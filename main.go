/*
*  Copyright (c) 2025 Lenny Siebert. All rights reserved.
*  Licensed under the terms of the GNU General Public License v3.0.
 */

package main

import (
	cmd "fireworks/cmd"
	"fireworks/internal/source/bundle"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	executablePath, err := os.Executable()
	if err != nil {
		panic(err)
	}
	cachePath := filepath.Join(filepath.Dir(executablePath), "vendor")

	bundle, err := internal.InitBundle(cachePath)
	if err != nil {
		panic(err)
	}

	artifact := bundle.InitArtifact("dart-sdk-3.7.2")

	artifact.SetOrigin(
		internal.UrlInnerFolderUnzipped,
		"https://storage.googleapis.com/dart-archive/channels/stable/release/3.7.2/sdk/dartsdk-windows-x64-release.zip",
	)
	_ = artifact.MakeAvailable()

	artifact = bundle.InitArtifact("cmake-4.0.1")
	artifact.SetOrigin(
		internal.UrlInnerFolderUnzipped,
		"https://github.com/Kitware/CMake/releases/download/v4.0.1/cmake-4.0.1-windows-x86_64.zip",
	)
	err = artifact.MakeAvailable()
	if err != nil {
		fmt.Printf("%v", err)
	}
	_ = bundle.Save()
	_ = bundle.CleanCache()

	cachePath = filepath.Join(filepath.Dir(executablePath), "internal")
	bundle, err = internal.InitBundle(cachePath)
	if err != nil {
		panic(err)
	}
	artifact = bundle.InitArtifact("data")

	dataPath := filepath.Join(filepath.Dir(filepath.Dir(executablePath)), "internal", "data")
	err = artifact.MakeAvailable()
	if err != nil {
		artifact.SetOrigin(
			internal.Local,
			dataPath,
		)
		_ = artifact.MakeAvailable()
	}

	_ = bundle.Save()
	cmd.Execute()
}
