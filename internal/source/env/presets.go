package internal

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
)

type Preset struct {
	Name           string            `json:"name"`
	Generator      string            `json:"generator"`
	BinaryDir      string            `json:"binaryDir"`
	InstallDir     string            `json:"installDir"`
	Architecture   string            `json:"architecture"`
	CacheVariables map[string]string `json:"cacheVariables"`
}
type configPresetsT struct {
	Presets []Preset `json:"configurePresets"`
}

func GetPresetsConfigurationPath() (string, error) {
	dataPath, err := GetDataPath()
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%s/presets.json", dataPath), nil
}

func GetPresets() ([]Preset, error) {
	presetsConfiguration, err := GetPresetsConfigurationPath()
	if err != nil {
		return nil, err
	}

	file, err := os.OpenFile(presetsConfiguration, os.O_RDONLY, 04)
	if err != nil {
		return nil, err
	}

	data, err := io.ReadAll(file)
	if err != nil {
		return nil, err
	}

	var configPresets configPresetsT
	err = json.Unmarshal(data, &configPresets)
	if err != nil {
		return nil, err
	}

	return configPresets.Presets, nil
}
