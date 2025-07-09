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

final BuildEnvironment environment = BuildEnvironment.fromDefault((
  defaultEnvironment,
) {
  const String repositoryUrl = "https://github.com/llvm/llvm-project.git";
  final String repositoryPath = path.join(
    path.basenameWithoutExtension(repositoryUrl),
  );
  return BuildEnvironment(
    target: System(
      platform: SystemPlatform.windows,
      processor: SystemProcessor.x86_64,
    ),
    buildType: BuildType.release,
    outputDirectory: Directory(
      path.join(
        defaultEnvironment.outputDirectory.path,
        "bin",
        "clang-${defaultEnvironment.target.string()}",
      ),
    ),
    vars: {
      "repository_url": repositoryUrl,
      "repository_path": repositoryPath,
      "required_programs": ["git", "cmake", "python"],
    },
  );
});

final List<BuildStep> steps = [
  BuildStep(
    "Check for available programs",
    condition: (env) =>
        !BuildEnvironment.ensurePrograms(env.vars["required_programs"]!),
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
      arguments: [
        "-S ${env.vars["repository_path"]!}/llvm",
        "-B ${env.workDirectory.path}",
        "-DCMAKE_INSTALL_PREFIX=${env.outputDirectory.path}",
        "-DCMAKE_BUILD_TYPE=" +
            {
              BuildType.debug: "Debug",
              BuildType.release: "Release",
              BuildType.releaseDebug: "RelWithDebInfo",
            }[env.buildType]!,
        "-DLLVM_ENABLE_PDB=OFF",
        "-DLLVM_BUILD_TOOLS=OFF",
        "-DLLVM_ENABLE_DIA_SDK=OFF",
        "-DLLVM_ENABLE_PDB=OFF",
        "-DLLVM_ENABLE_PROJECTS=clang",
        "-DLLVM_TARGETS_TO_BUILD=" + {
          (SystemPlatform.windows, SystemProcessor.x86_64) : [
            "AArch64", "X86"
          ],
          (SystemPlatform.windows, SystemProcessor.arm64) : [
            "AA"
          ]
        }[(env.host.platform, env.host.processor)]!.join(";"),
      ],
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
        env.buildType.name["cmake"]!,
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
      arguments: ["--install", env.workDirectory.path],
    ),
  ),
  BuildStep(
    "Checkout",
    run: (env) async {
      stdout.writeln(
        "\nArtifact output can be found in '${env.vars["install_path"]}'",
      );
      String out = jsonEncode(env.toJson());
      final File outputInfo = File(
        path.join(env.workDirectory.path, "env.json"),
      )..writeAsStringSync(out);
      return true;
    },
  ),
];

Future<int> main(List<String> args) async =>
    await environment.execute(steps) ? 0 : 1;
