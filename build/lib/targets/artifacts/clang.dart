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

final List<BuildStep> processSteps = [
  BuildStep(
    "Check for available programs",
    run: (_) => ensurePrograms(["git", "cmake", "python"]),
  ),
  BuildStep(
    "Clone repository",
    condition: (env) {
      env.variables["repository_url"] =
          "https://github.com/llvm/llvm-project.git";
      env.variables["repository_name"] = path.basenameWithoutExtension(
        env.variables["repository_url"],
      );
      return !Directory(
        path.join(env.workDirectoryPath, env.variables["repository_name"]!),
      ).existsSync();
    },
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
    condition: (env) {
      env.variables["cmake_build_type"] = "MinSizeRel";
      return !File(
        path.join(env.workDirectoryPath, "CMakeCache.txt"),
      ).existsSync();
    },
    command: (env) => BuildStepCommand(
      program: "cmake",
      arguments:
          [
            "-S ${path.join(env.workDirectoryPath, env.variables["repository_name"]!)}/llvm",
            "-B ${env.workDirectoryPath}",
            "-DCMAKE_BUILD_TYPE=" + env.variables["cmake_build_type"],
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
    condition: (env) {
      return !File(
        path.join(
          env.workDirectoryPath,
          env.variables["cmake_build_type"],
          "bin",
          "clang" +
              (env.target.platform == SystemPlatform.windows ? ".exe" : ""),
        ),
      ).existsSync();
    },
    command: (env) => BuildStepCommand(
      program: "cmake",
      arguments: [
        "--build",
        env.workDirectoryPath,
        "--config",
        env.variables["cmake_build_type"],
      ],
    ),
  ),
  BuildStep(
    "Install project binaries",
    condition: (env) {
      return !File(
        path.join(
          env.installDirectoryPath,
          "clang" +
              (env.target.platform == SystemPlatform.windows ? ".exe" : ""),
        ),
      ).existsSync();
    },
    run: (env) {
      install(
        installPath: [env.installDirectoryPath, "bin"],
        rootDirectoryPath: [
          env.workDirectoryPath,
          env.variables["cmake_build_type"],
          "bin",
        ],
        fileNames: [
          "clang"
        ]
      );
      File(
        path.join(
          env.workDirectoryPath,
          env.variables["repository_name"]!,
          "LICENSE.TXT",
        ),
      ).copySync(path.join(env.installDirectoryPath, "clang.license"));
      return true;
    },
  ),
];
