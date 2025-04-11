package main

import (
	"encoding/json"
	"fmt"
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

var internalProjectConfiguration = fmt.Sprintf(
	"%s/internal/data/project.json", workingDir())

var internalCMakePresets = fmt.Sprintf(
	"%s/internal/data/CMakePresets.json", workingDir())

var buildDir = fmt.Sprintf("%s/build", workingDir())

var logFilePath = fmt.Sprintf("%s/build.log", buildDir)

func helpMsg(projectConfigPath string) string {

	file, err := os.OpenFile(projectConfigPath, os.O_RDONLY, 04)
	if err != nil {
		log.Panicf("Cannot open %s.", internalProjectConfiguration)
		return ""
	}

	data, err := io.ReadAll(file)
	if err != nil {
		log.Panicf("Cannot read %s.", internalProjectConfiguration)
	}

	var parsedData map[string]interface{}
	err = json.Unmarshal(data, &parsedData)
	if err != nil {
		log.Panicf("Cannot parse %s.", internalProjectConfiguration)
	}

	projectData := parsedData["project"].(map[string]interface{})
	versionString := projectData["version"].(string)
	channelString := projectData["channel"].(string)
	copyrightString := projectData["copyright"].(string)
	configurationString := "debug"
	osSystemString := runtime.GOOS
	osArchString := runtime.GOARCH
	if err != nil {
		log.Printf("WARNING: The program cant receive the host system name. You must provide it manually.")
		osSystemString = "Unknown hostname"
	}
	return fmt.Sprintf("\n%s"+
		"\nProject version: %s-%s \n"+
		"Configuration: %s\n"+
		"Host system: %s-%s\n"+
		"Target system: %s-%s\n"+
		"Please specify\n"+
		"\n"+
		"",
		copyrightString,
		versionString,
		channelString,
		configurationString,
		osSystemString,
		osArchString,
		osSystemString,
		osArchString,
	)
}

/*
Vorgehen:
Zuerst muss der runner gebaut werden, welcher dann bereitsteht, um die runtime modules zu bauen.
Es muss eine bestimmte reihenfolge geben, damit je
*/
func main() {
	err := os.Mkdir(buildDir, os.ModePerm)
	err = os.Remove(logFilePath)
	file, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatal(err)
	}
	log.SetOutput(file)
	log.Print(helpMsg(internalProjectConfiguration))
	fmt.Print(helpMsg(internalProjectConfiguration))
	args := os.Args[1:]
	_ = fmt.Sprint(args)
	pathEnv := os.Getenv("GOROOT")
	if strings.Compare(pathEnv, "") == 0 {
		fmt.Print("GOROOT is not available. Consider it to be set at the root of your go installation.")
		os.Exit(1)
	}
	fmt.Print("GOROOT........FOUND")
}
