package cache

import (
	"archive/zip"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
)

type Artifact struct {
	ParentBundle       Bundle `json:"-"`
	Identifier         string `json:"artifact_identifier"`
	IsArchive          bool   `json:"is_archive"`
	IsVendorUrl        bool   `json:"is_vendor_url"`
	VendorUrl          string `json:"vendor_url"`
	IsVendorFile       bool   `json:"is_vendor_file"`
	VendorFile         string `json:"vendor_file"`
	RelativeBundlePath string `json:"relative_bundle_path"`
}

func (artifact *Artifact) SetOriginFromUrl(unzip bool, url string) {
	artifact.IsVendorUrl = true
	artifact.VendorUrl = url
	artifact.IsArchive = unzip
	artifact.IsVendorFile = false
	artifact.VendorFile = ""
}

func (artifact *Artifact) SetOriginFromFile(path string) {
	artifact.IsVendorUrl = false
	artifact.VendorUrl = ""
	artifact.IsArchive = false
	artifact.IsVendorFile = true
	artifact.VendorFile = path
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
	err = artifact.EnsureAvailable()
	return err
}

func (artifact *Artifact) EnsureAvailable() error {
	lastArtifactPath := artifact.Path()
	_, err := os.Stat(lastArtifactPath)
	if err == nil {
		return nil
	}
	if artifact.IsVendorFile {
		if artifact.VendorFile == "" {
			return errors.New("the vendor path is empty")
		}
		source, err := os.Open(artifact.VendorFile)
		if err != nil {
			return err
		}
		defer func() { _ = source.Close() }()

		destination, err := os.OpenFile(lastArtifactPath, os.O_WRONLY, os.ModePerm)
		if err != nil {
			return err
		}
		defer func() { _ = destination.Close() }()

		_, err = io.Copy(source, destination)
		if err != nil {
			return err
		}
		return nil
	}
	if artifact.IsVendorUrl {
		if artifact.VendorUrl == "" {
			return errors.New("the vendor url is empty")
		}
		if artifact.IsArchive {
			lastArtifactPath = filepath.Join(artifact.ParentBundle.Path, "download", artifact.Identifier)
			err = os.MkdirAll(filepath.Join(artifact.ParentBundle.Path, "download"), 0666)
			if err != nil {
				return err
			}
		}
		_, err = os.Stat(lastArtifactPath)
		if err != nil {
			err = downloadFromUrl(artifact.VendorUrl, lastArtifactPath)
			if err != nil {
				return errors.Join(errors.New("can't download artifact"), err)
			}
		}
		if artifact.IsArchive {
			err = unzip(lastArtifactPath, true, artifact.Path())
			if err != nil {
				return errors.Join(errors.New("failed to unzip archive"), err)
			}
		}
		return nil
	}
	return errors.New("artifact has no origin")
}

func downloadFromUrl(url string, outputFile string) error {
	output, err := os.Create(outputFile)
	if err != nil {
		return err
	}

	defer func(output *os.File) {
		_ = output.Close()
	}(output)

	response, err := http.Get(url)
	if err != nil {
		return err
	}

	defer func(Body io.ReadCloser) {
		err = Body.Close()
	}(response.Body)

	_, err = io.Copy(output, response.Body)
	if err != nil {
		return err
	}
	return nil
}

func unzip(sourceArchive string, removeFirstFolder bool, destination string) error {
	reader, err := zip.OpenReader(sourceArchive)
	if err != nil {
		return err
	}
	defer func() {
		if err := reader.Close(); err != nil {
			panic(err)
		}
	}()

	err = os.MkdirAll(destination, 0755)
	if err != nil {
		return err
	}

	extractAndWriteFile := func(entity *zip.File) error {
		entityReader, err := entity.Open()
		if err != nil {
			return err
		}
		defer func() { _ = entityReader.Close() }()

		cutIndex := 0
		if removeFirstFolder {
			for i, char := range entity.Name {
				if char == '/' || char == '\\' {
					cutIndex = i
					break
				}
			}
		}

		unpackedDestination := filepath.Join(destination, entity.Name[cutIndex:])
		if entity.FileInfo().IsDir() {
			return nil
		}

		err = os.MkdirAll(filepath.Dir(unpackedDestination), entity.Mode())
		if err != nil {
			return err
		}

		f, err := os.OpenFile(unpackedDestination, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, entity.Mode())
		if err != nil {
			return err
		}

		defer func() {
			if err := f.Close(); err != nil {
				panic(err)
			}
		}()

		_, err = io.Copy(f, entityReader)
		if err != nil {
			return err
		}
		return nil
	}

	for _, file := range reader.File {
		err := extractAndWriteFile(file)
		if err != nil {
			return err
		}
	}

	return nil
}
