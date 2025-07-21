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

import 'dart:io' as io;

import 'package:path/path.dart' as path;

import '../../build.dart';

final List<Step> processSteps = [
  Step(
    "Check for available programs",
    run: (_) => ensurePrograms(["git", "cmake", "python"]),
  ),
  Step(
    "Clone repository",
    configure: (env) {
      env.vars["repository_url"] = "https://github.com/llvm/llvm-project.git";
      env.vars["repository_name"] = path.basenameWithoutExtension(
        env.vars["repository_url"],
      );
    },
    condition: (env) => !io.Directory(
      path.join(env.workDirectoryPath, env.vars["repository_name"]!),
    ).existsSync(),
    command: (env) => StepCommand(
      program: "git",
      arguments: [
        "clone",
        "-b",
        "release/20.x",
        "--single-branch",
        "--depth",
        "1",
        env.vars["repository_url"]!,
      ],
    ),
  ),
  Step(
    "CMake configuration",
    configure: (env) {
      env.vars["cmake_build_type"] = "MinSizeRel";
      env.vars["repository_path"] = path.join(
        env.workDirectoryPath,
        env.vars["repository_name"]!,
      );
    },
    condition: (env) => !io.File(
      path.join(env.workDirectoryPath, "CMakeCache.txt"),
    ).existsSync(),
    command: (env) => StepCommand(
      program: "cmake",
      arguments:
          [
            "-S ${env.vars["repository_path"]}/llvm",
            "-B ${env.workDirectoryPath}",
            "-DCMAKE_BUILD_TYPE=" + env.vars["cmake_build_type"],
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
          (env.host.platform == Platform.windows
              ? ["-DLLVM_ENABLE_PDB=OFF", "-DLLVM_ENABLE_DIA_SDK=OFF"]
              : []),
    ),
  ),
  Step(
    "Build project files",
    condition: (env) => !io.File(
      path.join(
        env.workDirectoryPath,
        env.vars["cmake_build_type"],
        "bin",
        "clang" + (env.target.platform == Platform.windows ? ".exe" : ""),
      ),
    ).existsSync(),
    command: (env) => StepCommand(
      program: "cmake",
      arguments: [
        "--build",
        env.workDirectoryPath,
        "--config",
        env.vars["cmake_build_type"],
      ],
    ),
  ),
  Step(
    "Install project binaries",
    configure: (env) {
      env.vars["clang_executable_path"] = path.join(
        env.installDirectoryPath,
        "bin",
        "clang" + (env.target.platform == Platform.windows ? ".exe" : ""),
      );
    },
    condition: (env) =>
        !io.File(env.vars["clang_executable_path"]).existsSync(),
    run: (env) => install(
      installPath: [env.installDirectoryPath, "bin"],
      rootDirectoryPath: [
        env.workDirectoryPath,
        env.vars["cmake_build_type"],
        "bin",
      ],
      fileNames: ["clang"],
    ),
  ),
  Step(
    "Copy license file",
    configure: (env) {
      env.vars["license_path"] = path.join(
        env.vars["repository_path"]!,
        "LICENSE.TXT",
      );
      env.vars["license_install_path"] = path.join(
        env.installDirectoryPath,
        "clang.license",
      );
    },
    condition: (env) => !io.File(env.vars["license_install_path"]).existsSync(),
    run: (env) => (io.File(
      env.vars["license_path"],
    )..copySync(env.vars["license_install_path"])).existsSync(),
  ),
];
