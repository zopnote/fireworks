/*
*  Copyright (c) 2025 Lenny Siebert. All rights reserved.
*  Licensed under the terms of the GNU General Public License v3.0.
 */

package main

import (
	cmd "fireworks/cmd"
	cache2 "fireworks/internal/source/cache"
	"os"
	"path/filepath"
)

func main() {
	executablePath, err := os.Executable()
	if err != nil {
		panic(err)
	}
	cachePath := filepath.Join(filepath.Dir(executablePath), "vendor")

	bundle, err := cache2.InitBundle(cachePath)
	if err != nil {
		panic(err)
	}

	artifact := bundle.InitArtifact("dart-sdk-3.7.2")

	err = artifact.MakeAvailable()
	if err != nil {
		artifact.SetOrigin(
			cache2.UrlInnerFolderUnzipped,
			"https://storage.googleapis.com/dart-archive/channels/stable/release/3.7.2/sdk/dartsdk-windows-x64-release.zip",
		)
		_ = artifact.MakeAvailable()
	}

	artifact = bundle.InitArtifact("cmake-4.0.1")

	err = artifact.MakeAvailable()
	if err != nil {
		artifact.SetOrigin(
			cache2.UrlInnerFolderUnzipped,
			"https://github.com/Kitware/CMake/releases/download/v4.0.1/cmake-4.0.1-windows-x86_64.zip",
		)
		_ = artifact.MakeAvailable()
	}
	_ = bundle.Save()

	cachePath = filepath.Join(filepath.Dir(executablePath), "internal")
	bundle, err = cache2.InitBundle(cachePath)
	if err != nil {
		panic(err)
	}
	artifact = bundle.InitArtifact("data")

	dataPath := filepath.Join(filepath.Dir(filepath.Dir(executablePath)), "internal", "data.zip")
	err = artifact.MakeAvailable()
	if err != nil {
		artifact.SetOrigin(
			cache2.LocalInnerFolderUnzipped,
			dataPath,
		)
		_ = artifact.MakeAvailable()
	}

	_ = bundle.Save()
	cmd.Execute()
}
