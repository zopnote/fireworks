/*
 * Copyright (c) 2025 Lenny Siebert
 *
 * This software is dual-licensed:
 *
 * 1. Open Source License:
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License version 3
 *    as published by the Free Software Foundation.
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY. See the GNU General Public
 *    License for more details: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * 2. Commercial License:
 *    A commercial license will be available at a later time for use in commercial products.
 */

import 'dart:io';

import 'package:fireworks_scripts/environment.dart' as environment;
import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;

const String repository = "https://github.com/llvm/llvm-project.git";
const List<String> requiredPrograms = const ["cmake", "git", "python"];


final String scriptName = path.basenameWithoutExtension(Platform.script.path);
final String repositoryName = path.basenameWithoutExtension(repository);

final String buildFilesDirectoryPath = path.join(
  environment.currentDirectory,
  "$repositoryName-${environment.system}-cmake-build",
);

final String repositoryDirectoryPath = path.join(
  environment.currentDirectory,
  repositoryName,
);

final String outputDirectoryPath = path.join(
  environment.outputDirectory, "artifacts",
  "$repositoryName-${environment.system}"
);

Future<int> main(List<String> args) async {

  if (!environment.ensurePrograms(requiredPrograms)) {
    stderr.writeln(
      "\nPlease ensure the availability of all dependencies to proceed.",
    );
    return 1;
  }

  await Directory(workDirectoryPath).create(recursive: true);

  if (!Directory(repositoryDirectoryPath).existsSync()) {
    await executeProcess(workDirectoryPath, "git", [
      "clone",
      "-b release/20.x",
      "--single-branch",
      "--depth 1",
      repository,
    ], exitOnFail: true);
  }

  await Directory("$buildFilesDirectoryPath").create(recursive: true);

  if (!Directory("$buildFilesDirectoryPath/CMakeFiles").existsSync()) {
    await executeProcess(workDirectoryPath, "cmake", [
      "-S $repositoryDirectoryPath/llvm",
      "-B $buildFilesDirectoryPath",
      "-DCMAKE_INSTALL_PREFIX=$outputDirectoryPath",

      "-DCMAKE_BUILD_TYPE=Release",
      "-DLLVM_ENABLE_PDB=OFF",
      "-DLLVM_BUILD_TOOLS=OFF",
      "-DLLVM_ENABLE_DIA_SDK=OFF",
      "-DLLVM_ENABLE_PDB=OFF",
      "-DLLVM_ENABLE_PROJECTS=clang",
      "-DLLVM_TARGETS_TO_BUILD=X86;AArch64",
    ], exitOnFail: true);
  }

  await executeProcess(workDirectoryPath, "cmake", [
    "--build $buildFilesDirectoryPath",
    "--config Release",
  ], exitOnFail: true);

  await Directory("$outputDirectoryPath").create(recursive: true);

  await executeProcess(workDirectoryPath, "cmake", [
    "--install $buildFilesDirectoryPath",
  ], exitOnFail: true);

  stdout.writeln("\nArtifact output can be found in $outputDirectoryPath");
  return 0;
}
