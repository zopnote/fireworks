package internal

import (
	"archive/zip"
	"errors"
	"io"
	"os"
	"path/filepath"
)

func Unzip(sourceArchive string, destination string, removeFirstFolder bool) error {
	reader, err := zip.OpenReader(sourceArchive)
	if err != nil {
		return err
	}
	defer func() { _ = reader.Close() }()

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

		defer func() { _ = f.Close() }()

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

func Zip(input string, output string) error {
	info, err := os.Stat(input)
	if err != nil {
		return errors.New("the input directory does not exist")
	}
	if !info.IsDir() {
		return errors.New("the input is not a directory which it must be to be zipped")
	}

	file, err := os.Create(output)
	if err != nil {
		return err
	}

	defer func() { _ = file.Close() }()

	archiveWriter := zip.NewWriter(file)
	defer func() { _ = archiveWriter.Close() }()

	walker := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		inputReader, err := os.Open(path)
		if err != nil {
			return err
		}

		defer func() { _ = inputReader.Close() }()

		archivedFile, err := archiveWriter.Create(path)
		if err != nil {
			return err
		}

		_, err = io.Copy(archivedFile, inputReader)
		if err != nil {
			return err
		}

		return nil
	}

	executablePath, err := os.Executable()
	if err != nil {
		return err
	}

	path, err := filepath.Rel(filepath.Dir(filepath.Dir(executablePath)), input)
	if err != nil {
		return err
	}

	err = filepath.Walk(path, walker)
	if err != nil {
		return err
	}

	return nil
}
