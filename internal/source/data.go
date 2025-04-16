package source

import (
	"fmt"
	"os"
	"path/filepath"
)

func GetDataPath() (string, error) {
	executablePath, err := os.Executable()
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%s/../internal/data", filepath.Dir(executablePath)), err
}
