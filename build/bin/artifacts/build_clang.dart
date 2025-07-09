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

import 'dart:convert';
import 'dart:io';

import 'package:fireworks_scripts/environment.dart';
import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;
void main() async => await BuildConfig(
  variables: {
    "environment_name": "clang_sdk_ci_build",
    "version": 1.0
  }
).override((config) {
  const String repositoryUrl = "https://github.com/llvm/llvm-project.git";
  final String repositoryPath = path.join(
    path.basenameWithoutExtension(repositoryUrl),
  );
  return BuildConfig(
    outputDirectory: Directory(
      path.join(
        config.outputDirectory.path,
        config.target.string(),
        "bin",
        "clang",
      ),
    ),
    variables: {
      "repository_url": repositoryUrl,
      "repository_path": repositoryPath,
      "required_programs": ["git", "cmake", "python"],
    },
  );
}).execute([
  BuildStep(
    "Check for available programs",
    condition: (env) =>
    !BuildConfig.ensurePrograms(env.vars["required_programs"]!),
    run: (env) async {
      stderr.writeln(
        "\nPlease ensure the availability of all dependencies to proceed.",
      );
      return false;
    },
  ),
  BuildStep(
    "Create work directory",
    condition: (env) => !env.workDirectory.existsSync(),
    run: (env) async {
      await env.workDirectory.create(recursive: true);
      return await env.workDirectory.exists();
    },
  ),
  BuildStep(
    "Clone repository",
    condition: (env) => !Directory(env.vars["repository_path"]!).existsSync(),
    command: (env) => CommandProperties(
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
  BuildStep(
    "CMake configuration",
    condition: (env) =>
    !Directory("${env.workDirectory.path}/CMakeFiles").existsSync(),
    command: (env) => CommandProperties(
      program: "cmake",
      arguments:
      [
        "-S ${env.vars["repository_path"]!}/llvm",
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
    command: (env) => CommandProperties(
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
    "Create directory",
    condition: (env) => Directory(env.vars["install_path"]).existsSync(),
    run: (env) async {
      await Directory(env.vars["install_path"]).create(recursive: true);
      return await Directory(env.vars["install_path"]).exists();
    },
  ),
  BuildStep(
    "Install project binaries",
    command: (env) => CommandProperties(
      program: "cmake",
      arguments: ["--install", env.workDirectory.path, "--config",
        {
          BuildType.debug: "Debug",
          BuildType.release: "MinSizeRel",
          BuildType.releaseDebug: "RelWithDebInfo",
        }[env.buildType]!],
    ),
  ),
  BuildStep(
    "Checkout",
    run: (env) async {
      stdout.writeln(
        "\nArtifact output can be found in '${env.vars["install_path"]}'",
      );
      String out = jsonEncode(env.toJson());
      File(path.join(env.workDirectory.path, "env.json"))
        ..writeAsStringSync(out);
      return true;
    },
  )
]);

