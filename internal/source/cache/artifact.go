package cache

import (
	"errors"
	"fireworks/internal/source"
	"io"
	"os"
	"path/filepath"
)

type ArtifactOrigin int

const (
	None                     ArtifactOrigin = 0
	LocalInnerFolderUnzipped ArtifactOrigin = 1
	LocalUnzipped            ArtifactOrigin = 2
	Local                    ArtifactOrigin = 3
	UrlInnerFolderUnzipped   ArtifactOrigin = 4
	UrlUnzipped              ArtifactOrigin = 5
	Url                      ArtifactOrigin = 6
)

type Artifact struct {
	ParentBundle Bundle         `json:"-"`
	Identifier   string         `json:"identifier"`
	Origin       ArtifactOrigin `json:"origin"`
	Vendor       string         `json:"vendor"`
}

func (artifact *Artifact) IsOriginArchive() bool {
	switch artifact.Origin {
	case Url:
	case Local:
		return false
	}
	return true
}

func (artifact *Artifact) IsOriginLocal() bool {
	if artifact.Origin < UrlInnerFolderUnzipped {
		return true
	}
	return false
}

func (artifact *Artifact) SetOrigin(originPreset ArtifactOrigin, origin string) {
	artifact.Origin = originPreset
	artifact.Vendor = origin
}

func (artifact *Artifact) Path() string {
	return filepath.Join(artifact.ParentBundle.Path, artifact.Identifier)
}

func (artifact *Artifact) RenewFromOrigin() error {
	artifactPath := artifact.Path()
	_, err := os.Stat(artifactPath)
	if err == nil {
		err = os.RemoveAll(artifactPath)
		if err != nil {
			return err
		}
	}
	err = artifact.MakeAvailable()
	return err
}

func (artifact *Artifact) MakeAvailable() error {
	_, err := os.Stat(artifact.Path())
	if err == nil {
		return nil
	}

	if artifact.Origin == 0 {
		return errors.New("artifact has no origin")
	}
	if artifact.Vendor == "" {
		return errors.New("the vendor reference is empty")
	}

	path := artifact.Path()

	if artifact.IsOriginArchive() {
		path = filepath.Join(artifact.ParentBundle.Path, "cache", artifact.Identifier)
		err = os.MkdirAll(filepath.Join(artifact.ParentBundle.Path, "cache"), 0666)
		if err != nil {
			return err
		}
	}

	_, err = os.Stat(path)
	if err != nil {
		if artifact.IsOriginLocal() {
			source, err := os.Open(artifact.Vendor)
			if err != nil {
				return err
			}
			defer func() { _ = source.Close() }()

			destination, err := os.Create(path)
			if err != nil {
				return err
			}

			defer func() { _ = destination.Close() }()

			_, err = io.Copy(destination, source)
			if err != nil {
				return err
			}
			path = destination.Name()
		} else {
			err = source.DownloadFromUrl(artifact.Vendor, path)
			if err != nil {
				return errors.Join(errors.New("can't download artifact"), err)
			}
		}
	}
	if artifact.IsOriginArchive() {
		err = source.Unzip(path, artifact.Path(), artifact.Origin == 1 || artifact.Origin == 4)
		if err != nil {
			return errors.Join(errors.New("failed to unzip archive"), err)
		}
	}
	return nil
}
