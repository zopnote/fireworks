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

final String repositoryName = path.basenameWithoutExtension(repository);

final Directory workDirectory = Directory(environment.workDirectory);

final Directory repositoryDirectory = Directory(path.join(workDirectory.path, repositoryName));

final Directory outputDirectory = Directory(path.join(
  environment.outputDirectory,
  "bin",
  "clang-${environment.system}",
));

final StepProcess process = StepProcess(
  workingDirectory: workDirectory.path,
  steps: [
    Step(
      "Check for available programs",
      condition: () => !environment.ensurePrograms(requiredPrograms),
      run: (_) async {
        stderr.writeln(
          "\nPlease ensure the availability of all dependencies to proceed.",
        );
        return false;
      },
    ),
    Step(
      "Create directory",
      condition: () => !workDirectory.existsSync(),
      run: (_) async {
        await workDirectory.create(recursive: true);
        return workDirectory.exists();
      },
    ),
    Step(
      "Clone repository",
      condition: () => !repositoryDirectory.existsSync(),
      command: CommandProperties(
        program: "git",
        arguments: [
          "clone",
          "-b release/20.x",
          "--single-branch",
          "--depth 1",
          repository,
        ],
      ),
    ),
    Step(
      "CMake configuration",
      condition: () => !Directory("${workDirectory.path}/CMakeFiles").existsSync(),
      command: CommandProperties(
        program: "cmake",
        arguments: [
          "-S ${repositoryDirectory.path}/llvm",
          "-B ${workDirectory.path}",
          "-DCMAKE_INSTALL_PREFIX=${outputDirectory.path}",

          "-DCMAKE_BUILD_TYPE=Release",
          "-DLLVM_ENABLE_PDB=OFF",
          "-DLLVM_BUILD_TOOLS=OFF",
          "-DLLVM_ENABLE_DIA_SDK=OFF",
          "-DLLVM_ENABLE_PDB=OFF",
          "-DLLVM_ENABLE_PROJECTS=clang",
          "-DLLVM_TARGETS_TO_BUILD=X86;AArch64",
        ],
      ),
    ),
    Step(
      "Build project files",
      command: CommandProperties(
        program: "cmake",
        arguments: ["--build ${workDirectory.path}", "--config Release"],
      ),
    ),
    Step(
      "Create directory",
      run: (_) async {
        Directory directory = await Directory(
          "$outputDirectory",
        ).create(recursive: true);
        return directory.exists();
      },
    ),
    Step(
      "Install project binaries",
      command: CommandProperties(
        program: "cmake",
        arguments: ["--install ${workDirectory.path}"],
      ),
    ),
    Step(
      "Checkout",
      run: (_) async {
        stdout.writeln("\nArtifact output can be found in '${outputDirectory.path}'");
        return true;
      },
    ),
  ],
);

Future<int> main(List<String> args) async => await process.execute() ? 0 : 1;
