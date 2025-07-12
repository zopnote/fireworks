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

import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import 'package:path/path.dart' as path;

final BuildConfigCallback processConfig = (config) {
  const String repositoryUrl = "https://github.com/llvm/llvm-project.git";
  final String repositoryPath = path.join(
    path.basenameWithoutExtension(repositoryUrl),
  );
  return config.reconfigure(
    outputDirectory: Directory(
      path.join(
          config.outputDirectory.path, "bin", "clang"),
    ),
    variables: {
      "repository_url": repositoryUrl,
      "repository_path": repositoryPath,
    },
  );
};


final List<BuildStep> processSteps = [
  BuildStep(
    "Check for available programs",
    condition: (_) => !BuildConfig.ensurePrograms(["git", "cmake", "python"]),
    run: (env) async {
      stderr.writeln(
        "\nPlease ensure the availability of all dependencies to proceed.",
      );
      return false;
    },
  ),
  BuildStep(
    "Clone repository",
    condition: (env) =>
        !Directory(env.variables["repository_path"]!).existsSync(),
    command: (env) => BuildStepCommand(
      program: "git",
      arguments: [
        "clone",
        "-b",
        "release/20.x",
        "--single-branch",
        "--depth",
        "1",
        env.variables["repository_url"]!,
      ],
    ),
  ),
  BuildStep(
    "CMake configuration",
    condition: (env) =>
        !Directory("${env.workDirectory.path}/CMakeFiles").existsSync(),
    command: (env) => BuildStepCommand(
      program: "cmake",
      arguments:
          [
            "-S ${env.variables["repository_path"]!}/llvm",
            "-B ${env.workDirectory.path}",
            "-DCMAKE_INSTALL_PREFIX=${env.outputDirectory.path}",
            "-DCMAKE_BUILD_TYPE=" +
                {
                  BuildType.debug: "Debug",
                  BuildType.release: "Release",
                  BuildType.releaseDebug: "RelWithDebInfo",
                }[env.buildType]!,
            "-DLLVM_BUILD_TOOLS=OFF",
            "-DLLVM_INCLUDE_BENCHMARKS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_ENABLE_PEDANTIC=ON",
            "-DLLVM_ENABLE_BINDINGS=OFF",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_ENABLE_FFI=OFF",
            "-DLLVM_ENABLE_IDE=OFF",
            "-DLLVM_ENABLE_LIBCXX=OFF",
            "-DLLVM_ENABLE_UNWIND_TABLES=OFF",
            "-DLLVM_ENABLE_PROJECTS=clang",
            "-DLLVM_TARGETS_TO_BUILD=" + ["AArch64", "X86"].join(";"),
          ] +
          (env.host.platform == SystemPlatform.windows
              ? ["-DLLVM_ENABLE_PDB=OFF", "-DLLVM_ENABLE_DIA_SDK=OFF"]
              : []),
    ),
  ),
  BuildStep(
    "Build project files",
    command: (env) => BuildStepCommand(
      program: "cmake",
      arguments: [
        "--build",
        env.workDirectory.path,
        "--config",
        {
          BuildType.debug: "Debug",
          BuildType.release: "MinSizeRel",
          BuildType.releaseDebug: "RelWithDebInfo",
        }[env.buildType]!,
      ],
    ),
  ),
  BuildStep(
    "Install project binaries",
    command: (env) => BuildStepCommand(
      program: "cmake",
      arguments: [
        "--install",
        env.workDirectory.path,
        "--config",
        {
          BuildType.debug: "Debug",
          BuildType.release: "MinSizeRel",
          BuildType.releaseDebug: "RelWithDebInfo",
        }[env.buildType]!,
      ],
    ),
  )
];
