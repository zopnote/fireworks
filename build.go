package main

import (
	"encoding/json"
	"fmt"
	"github.com/spf13/cobra"
	"io"
	"log"
	"os"
	"runtime"
	"strings"
)

func workingDir() string {
	exePath, err := os.Getwd()
	if err != nil {
		log.Panic("Cannot receive working dir. Fallback to relative paths.")
		return "."
	}
	return exePath
}

type Preset struct {
	Name           string            `json:"name"`
	Generator      string            `json:"generator"`
	BinaryDir      string            `json:"binaryDir"`
	InstallDir     string            `json:"installDir"`
	Architecture   string            `json:"architecture"`
	CacheVariables map[string]string `json:"cacheVariables"`
	Condition      Condition         `json:"condition"`
}
type ConfigPresets struct {
	Presets []Preset `json:"configurePresets"`
}

type Condition struct {
	Type string `json:"type"`
	LHS  string `json:"lhs"`
	RHS  string `json:"rhs"`
}

var presetsConfiguration = fmt.Sprintf(
	"%s/internal/data/presets.json", workingDir())

func getPresets() []Preset {
	file, err := os.OpenFile(presetsConfiguration, os.O_RDONLY, 04)
	if err != nil {
		errMsg := fmt.Sprintf("Cannot open %s: %v", presetsConfiguration, err)
		_, _ = fmt.Fprint(os.Stderr, errMsg)
		log.Fatal(errMsg)
		return nil
	}
	data, err := io.ReadAll(file)
	if err != nil {
		errMsg := fmt.Sprintf("Cannot read %s: %v", presetsConfiguration, err)
		_, _ = fmt.Fprint(os.Stderr, errMsg)
		log.Fatal(errMsg)
		return nil
	}

	var configPresets ConfigPresets

	err = json.Unmarshal(data, &configPresets)
	if err != nil {
		errMsg := fmt.Sprintf("Cannot parse %s: %v", presetsConfiguration, err)
		_, _ = fmt.Fprint(os.Stderr, errMsg)
		log.Fatal(errMsg)
		return nil
	}
	return configPresets.Presets
}

func getAvailableTargets() []string {
	var availableTargets []string
	for _, preset := range getPresets() {
		fireworksOnlyAvailable := preset.CacheVariables["FIREWORKS_ONLY_AVAILABLE"]
		if fireworksOnlyAvailable != "" {
			if strings.Compare(fireworksOnlyAvailable, runtime.GOOS) == 0 {
				availableTargets = append(availableTargets, preset.Name)
			}
			continue
		}
		availableTargets = append(availableTargets, preset.Name)
	}
	return availableTargets
}

var hostSystemsFormat = map[string]string{
	"linux_amd64":   "linux-x86_64",
	"linux_arm64":   "linux-arm64",
	"windows_amd64": "win-x86_64",
	"windows_arm64": "win-arm64",
	"darwin_arm64":  "macos",
}

func getHostSystemName() string {
	for format, _ := range hostSystemsFormat {
		if strings.Compare(format, fmt.Sprintf("%s_%s", runtime.GOOS, runtime.GOARCH)) == 0 {
			return hostSystemsFormat[format]
		}
	}
	return ""
}

//goland:noinspection ALL
func getGoRoot() string {
	goRoot := os.Getenv("GOROOT")
	if strings.Compare(goRoot, "") == 0 {
		log.Printf("Cannot find GOROOT as environment variable, maybe read this article https://medium.com/@ugurkinik/golang-basics-goroot-gopath-3f80063a08d8. "+
			" Fall back on runtime.GOROOT(): %s", runtime.GOROOT())
		return runtime.GOROOT()
	}
	return goRoot
}

func registerConfigFlag() {
	rootCommand.PersistentFlags().String("config", "debug", "Defines the configuration of the build.")
}

func registerTargetFlag() {
	hostSystemName := getHostSystemName()
	if strings.Compare(hostSystemName, "") == 0 {
		failedDetect := fmt.Sprintf("\nCannot detect your host architecture: %s_%s. "+
			"The application relies now on the target flag.", runtime.GOOS, runtime.GOARCH)
		openIssue := fmt.Sprint("Please open an issue on the github because it " +
			"is the fault of the implementation that you got this error.")
		fmt.Print(failedDetect)
		fmt.Println(openIssue)
		log.Print(failedDetect)
		log.Println(openIssue)
	}
	rootCommand.PersistentFlags().String("target", hostSystemName, "Defines the target system. For more information check out build.md.")
}

var rootCommand = &cobra.Command{
	Use:   "build",
	Short: "Build the engine sdk components for your platform.",
	Long: "Small build tool to fit the needs of the Fireworks sdk development toolchain of building." +
		"Builds the sdk in steps to self host the engine runtime as module in the ecosystem of the fireworks cmdline tool.",
	Run: func(cmd *cobra.Command, args []string) {
		target, _ := cmd.Flags().GetString("target")
		for _, m := range getAvailableTargets() {
			if strings.Compare(m, target) == 0 {
				fmt.Printf("GOROOT at %s\n", getGoRoot())
				fmt.Printf("Host system %s\n", getHostSystemName())
				fmt.Printf("Target system preset %s\n", target)
				os.Exit(0)
			}
		}
		fmt.Print("Error: The target is invalid")
	},
}

var buildDir = fmt.Sprintf("%s/build", workingDir())

var logFilePath = fmt.Sprintf("%s/build.log", buildDir)

func init() {
	err := os.Mkdir(buildDir, os.ModePerm)
	_, err = os.Stat(logFilePath)
	if err == nil {
		err = os.Remove(logFilePath)
	}
	file, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	log.SetOutput(file)
	registerConfigFlag()
	registerTargetFlag()
}

func main() {
	err := rootCommand.Execute()
	if err != nil {
		errMsg := "Failed to execute root command."
		_, _ = fmt.Fprint(os.Stderr, errMsg)
		log.Fatal(errMsg)
	}
}
