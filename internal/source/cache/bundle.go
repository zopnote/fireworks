package cache

import (
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
)

type Bundle struct {
	Path      string     `json:"-"`
	Artifacts []Artifact `json:"artifacts"`
}

func InitBundleAt(directoryPath string) (Bundle, error) {
	bundleFile := filepath.Join(directoryPath, "bundle.json")
	bundle := Bundle{
		Path:      directoryPath,
		Artifacts: []Artifact{},
	}
	_, err := os.Stat(bundleFile)
	if err != nil {
		err = bundle.Save()
		if err != nil {
			return bundle, errors.Join(errors.New("failed to save bundle"), err)
		}
		return bundle, nil
	}

	file, err := os.OpenFile(bundleFile, os.O_RDONLY, 04)
	if err != nil {
		return bundle, err
	}
	defer func() { _ = file.Close() }()

	bundleData, err := io.ReadAll(file)
	if err != nil {
		return bundle, err
	}

	err = json.Unmarshal(bundleData, &bundle)
	if err != nil {
		return bundle, err
	}

	bundle.Path = directoryPath
	for _, artifact := range bundle.Artifacts {
		artifact.ParentBundle = bundle
	}

	return bundle, nil
}

func (bundle *Bundle) InitArtifact(identifier string) Artifact {
	for _, artifact := range bundle.Artifacts {
		if artifact.Identifier == identifier {
			return artifact
		}
	}
	var artifact = Artifact{
		Identifier:   identifier,
		ParentBundle: *bundle,
	}
	bundle.Artifacts = append(bundle.Artifacts, artifact)
	return artifact
}

func (bundle *Bundle) Save() error {
	data, err := json.Marshal(bundle)
	if err != nil {
		return err
	}
	bundleFilePath := filepath.Join(bundle.Path, "bundle.json")
	_, err = os.Stat(bundleFilePath)
	if err == nil {
		err = os.Remove(bundleFilePath)
		if err != nil {
			return err
		}
	}
	err = os.MkdirAll(bundle.Path, 0666)
	if err != nil {
		return errors.Join(errors.New("failed to create bundle directory"), err)
	}
	err = os.WriteFile(bundleFilePath, data, 0666)
	if err != nil {
		return errors.Join(errors.New("failed to write bundle specification"), err)
	}
	return nil
}
