package main

import (
	"errors"
	internal "fireworks/internal/source"
	"fmt"
	"github.com/spf13/cobra"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

var hostSystemName string
var hostSystemProcessor string

func init() {
	var err error
	hostSystemName, err = getHostSystemName()
	if err != nil {
		writeInFatal(fmt.Sprintf("Error occured while tried to get the operating system: %v", err))
	}
	hostSystemProcessor, err = getHostSystemProcessor()
	if err != nil {
		writeInFatal(fmt.Sprintf("Error occured while tried to get the systems processor architecture: %v", err))
	}

	err = os.Mkdir(buildDir, os.ModePerm)
	_, err = os.Stat(logFilePath)
	if err == nil {
		err = os.Remove(logFilePath)
	}
	file, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	log.SetOutput(file)

	err = registerConfigFlag()
	if err != nil {
		writeInFatal(fmt.Sprintf("Error occured while tried to register '--config' flag: %v", err))
	}
	err = registerTargetFlag()
	if err != nil {
		writeInFatal(fmt.Sprintf("Error occured while tried to register '--target' flag: %v", err))
	}
}

func main() {
	writeInDefault("Starting build...")
	err := rootCommand.Execute()
	if err != nil {
		log.Fatal("Failed to execute build-chain.")
	}
}

var rootCommand = &cobra.Command{

	Use:   "build",
	Short: "Build the engine sdk components for your platform.",

	Long: "Small build tool to fit the needs of the Fireworks sdk development toolchain of building." +
		"Builds the sdk in steps to self host the engine runtime as module in the ecosystem of the " +
		"fireworks cmdline tool.",

	RunE: func(cmd *cobra.Command, args []string) error {

		target, _ := cmd.Flags().GetString("target")
		validTarget := false
		availableTargets, err := getAvailableTargets()
		if err != nil {
			return err
		}
		for _, m := range availableTargets {
			if m == target {
				validTarget = true
			}
		}
		if !validTarget {
			writeInFatal("Error: The target is invalid")
		}

		log.Println(fmt.Sprintf("Go language root located at %s", getGoRoot()))
		log.Println(fmt.Sprintf("Host system %s-%s", hostSystemName, hostSystemProcessor))
		log.Println(fmt.Sprintf("Target system preset %s", target))

		// Sets the GOOS and GOARCH variables for cross compiling
		// -----------------------------------------------------------------------
		for key, value := range hostFormat {
			if value == hostSystemName {
				err := os.Setenv("GOOS", key)
				if err != nil {
					writeInFatal(fmt.Sprintf("Can't set the environment variable GOOS: %v", err))
				}

			} else if value == hostSystemProcessor {
				err := os.Setenv("GOARCH", key)
				if err != nil {
					writeInFatal(fmt.Sprintf("Can't set the environment variable GOARCH: %v", err))
				}
			}
		}
		// -----------------------------------------------------------------------

		// Command for building the runner
		// -----------------------------------------------------------------------
		lastCmd := exec.Command(
			"go",
			"build",
			"-o",
			fmt.Sprintf("%s/fireworks", buildDir),
			fmt.Sprintf("%s/main.go", workingDir()),
		)
		writeInDefault(fmt.Sprintf("[1/3] Build the runner -> %s", lastCmd.String()))
		stdout, err := lastCmd.Output()
		if err != nil {
			return errors.Join(err, errors.New(fmt.Sprintf("error while executing go build: %s", lastCmd.Stderr)))
		}
		writeInDefault(fmt.Sprintf("%v", stdout))
		// -----------------------------------------------------------------------

		// Command for test the runner of configuration
		// -----------------------------------------------------------------------
		exeEnding := ""
		if hostSystemName == "win" {
			exeEnding = ".exe"
		}
		lastCmd = exec.Command(
			fmt.Sprintf("%s/fireworks%s", buildDir, exeEnding),
			"doctor",
			target,
		)
		writeInDefault(fmt.Sprintf("[2/3] Ask the runner if env is available -> %s", lastCmd.String()))
		stdout, err = lastCmd.Output()
		if err != nil {
			return errors.Join(err, errors.New(fmt.Sprintf("error while building the runtime: %s", lastCmd.Stderr)))
		}
		writeInDefault(fmt.Sprintf("%s", lastCmd.Stdout))
		// -----------------------------------------------------------------------

		os.Exit(0)
		return nil
	},
}

func workingDir() string {
	exePath, err := os.Getwd()
	if err != nil {
		log.Panic("Cannot receive working dir. Fallback to relative paths.")
		return "."
	}
	return exePath
}

func getAvailableTargets() ([]string, error) {
	var availableTargets []string
	presets, err := internal.GetPresets()
	if err != nil {
		return nil, err
	}

	for _, preset := range presets {
		availability := preset.CacheVariables["FIREWORKS_ONLY_AVAILABLE"]
		if availability == "" || availability == runtime.GOOS {
			availableTargets = append(availableTargets, preset.Name)
			continue
		}
	}
	return availableTargets, nil
}

var hostFormat = map[string]string{
	"linux":   "linux",
	"windows": "win",
	"darwin":  "macos",
	"amd64":   "x86_64",
	"arm64":   "arm64",
}

func getHostSystemName() (string, error) {
	for key, value := range hostFormat {
		if key == runtime.GOOS {
			return value, nil
		}
	}
	return "", errors.New("unknown host operating system")
}
func getHostSystemProcessor() (string, error) {
	for key, value := range hostFormat {
		if strings.Compare(key, runtime.GOARCH) == 0 {
			return value, nil
		}
	}
	return "", errors.New("unknown host processor architecture")
}

//goland:noinspection ALL
func getGoRoot() string {
	goRoot := os.Getenv("GOROOT")
	if goRoot == "" {
		log.Printf("Cannot find GOROOT as environment variable, maybe read this article "+
			"https://medium.com/@ugurkinik/golang-basics-goroot-gopath-3f80063a08d8. "+
			" Fall back on runtime.GOROOT(): %s", runtime.GOROOT())
		return runtime.GOROOT()
	}
	return goRoot
}

func registerConfigFlag() error {
	rootCommand.PersistentFlags().String("config", "debug", "Defines the configuration of the build.")
	return nil
}

func writeInDefault(message string) {
	log.Println(message)
	fmt.Println(message)
}

func writeInFatal(message string) {
	_, err := fmt.Fprintln(os.Stderr, message)
	if err != nil {
		fmt.Println(message)
	}
	log.Fatal(message)
}

func registerTargetFlag() error {

	rootCommand.PersistentFlags().String(
		"target",
		fmt.Sprintf("%s-%s", hostSystemName, hostSystemProcessor),
		"Defines the target system. For more information check out build.md.",
	)
	return nil
}

var buildDir = fmt.Sprintf("%s/bin", workingDir())

var logFilePath = fmt.Sprintf("%s/build.log", buildDir)
