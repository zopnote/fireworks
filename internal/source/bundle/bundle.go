package internal

import (
	"encoding/json"
	"errors"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

type Bundle struct {
	Path      string      `json:"-"`
	Artifacts []*Artifact `json:"artifacts"`
}

func InitBundle(directoryPath string) (*Bundle, error) {
	bundleFile := filepath.Join(directoryPath, "bundle.json")
	_, err := os.Stat(bundleFile)
	if err != nil {
		return &Bundle{
			Path:      directoryPath,
			Artifacts: make([]*Artifact, 0),
		}, nil
	}
	file, err := os.OpenFile(bundleFile, os.O_RDONLY, 04)
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()

	bundleData, err := io.ReadAll(file)
	if err != nil {
		return nil, err
	}

	var bundle Bundle
	err = json.Unmarshal(bundleData, &bundle)
	if err != nil {
		return nil, err
	}
	bundle.Path = directoryPath
	for _, artifact := range bundle.Artifacts {
		artifact.ParentBundle = bundle
	}

	return &bundle, nil
}

func (bundle *Bundle) InitArtifact(identifier string) *Artifact {
	for _, artifact := range bundle.Artifacts {
		if artifact.Identifier == identifier {
			return artifact
		}
	}
	var artifact = Artifact{
		Identifier:   identifier,
		ParentBundle: *bundle,
		Origin:       None,
	}
	bundle.Artifacts = append(bundle.Artifacts, &artifact)
	return &artifact
}

func (bundle *Bundle) Save() error {

	data, err := json.Marshal(bundle)
	if err != nil {
		return err
	}

	bundlePath := filepath.Join(bundle.Path, "bundle.json")
	_, err = os.Stat(bundlePath)
	if err == nil {
		err = os.Remove(bundlePath)
		if err != nil {
			return err
		}
	}
	err = os.MkdirAll(bundle.Path, 0666)
	if err != nil {
		return errors.Join(errors.New("failed to create bundle directory"), err)
	}
	err = os.WriteFile(bundlePath, data, 0666)
	if err != nil {
		return errors.Join(errors.New("failed to write bundle specification"), err)
	}
	return nil
}

func (bundle *Bundle) CacheRoot() (string, error) {
	cacheRoot := filepath.Join(bundle.Path, "cache")
	cacheExists, err := exists(cacheRoot)
	if err != nil {
		return cacheRoot, errors.Join(errors.New("can't create cache directory"), err)
	}
	if !cacheExists {
		err = os.MkdirAll(cacheRoot, 0750)
		if err != nil {
			return cacheRoot, errors.Join(errors.New("can't create cache directory"), err)
		}
	}
	return cacheRoot, nil
}

func exists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, fs.ErrNotExist) {
		return false, nil
	}
	return false, err
}

func (bundle *Bundle) CleanCache() error {
	cacheRoot, err := bundle.CacheRoot()
	if err != nil {
		return err
	}
	err = os.RemoveAll(cacheRoot)
	return err
}
