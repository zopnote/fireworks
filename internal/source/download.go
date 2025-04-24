package internal

import (
	"io"
	"net/http"
	"os"
)

func DownloadFromUrl(url string, outputFile string) error {
	output, err := os.Create(outputFile)
	if err != nil {
		return err
	}

	defer func(output *os.File) { _ = output.Close() }(output)

	response, err := http.Get(url)
	if err != nil {
		return err
	}

	defer func(Body io.ReadCloser) { err = Body.Close() }(response.Body)

	_, err = io.Copy(output, response.Body)
	if err != nil {
		return err
	}
	return nil
}
