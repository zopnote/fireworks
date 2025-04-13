/*
*  Copyright (c) 2025 Lenny Siebert. All rights reserved.
*  Licensed under the terms of the GNU General Public License v3.0.
 */

package main

import (
	cmd "fireworks/cmd"
	"fireworks/internal/source/cache"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	executablePath, err := os.Executable()
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "os.Executable is an error occurred: %v", err)
		os.Exit(1)
	}
	cachePath := filepath.Join(filepath.Dir(executablePath), "cache")
	bundle, err := cache.InitBundleAt(cachePath)
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "cache.InitBundleAt is an error occurred: %v", err)
		os.Exit(1)
	}
	artifact := bundle.InitArtifact("dart_sdk")
	if artifact.EnsureAvailable() != nil {
		artifact.SetOriginFromUrl(true, "https://storage.googleapis.com/dart-archive/channels/stable/release/3.7.2/sdk/dartsdk-windows-x64-release.zip")
		err = artifact.RenewFromOrigin()
		if err != nil {
			_, _ = fmt.Fprintf(os.Stderr, "artifact.RenewFromOrigin is an error occurred: %v", err)
			os.Exit(1)
		}
	}
	err = bundle.Save()
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "bundle.Save is an error occurred: %v", err)
		os.Exit(1)
	}
	cmd.Execute()
}
