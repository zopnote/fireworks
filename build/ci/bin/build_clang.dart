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

import 'package:fireworks_ci_scripts/fireworks_script.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  const String clangRepository = "https://github.com/llvm/llvm-project.git";
  if (!ensureRequiredPrograms(["cmake", "git", "python"])) {
    stderr.writeln(
      "\nPlease ensure the availability of all dependencies to proceed.",
    );
    return;
  }

  final String scriptName = path.basenameWithoutExtension(Platform.script.path);
  final Directory workDirectory = Platform.isWindows
      ? Directory(
          "${path.join(path.dirname(Platform.script.path), scriptName).substring(1)}",
        )
      : Directory(
          "${path.join(path.dirname(Platform.script.path), scriptName)}",
        );
  await workDirectory.create(recursive: true);

  if (!(await Directory(
    path.join(
      workDirectory.path,
      path.basenameWithoutExtension(clangRepository),
    ),
  ).exists())) {
    await executeProcess(workDirectory.path, "git", [
      "clone",
      "-b",
      "release/20.x",
      "--single-branch",
      "--depth",
      "1",
      clangRepository,
    ]);
  }

  await Directory("${workDirectory.path}/cmake").create(recursive: true);
  if (!(await Directory("${workDirectory.path}/cmake/CMakeFiles").exists()))
    await executeProcess(workDirectory.path, "cmake", [
      "-S",
      "${workDirectory.path}/llvm-project/llvm",
      "-B",
      "${workDirectory.path}/cmake",
      "-DCMAKE_BUILD_TYPE=Release",
      "-DLLVM_ENABLE_PDB=OFF",
      "-DLLVM_BUILD_TOOLS=OFF",
      "-DLLVM_ENABLE_DIA_SDK=OFF",
      "-DLLVM_ENABLE_PDB=OFF",
      "-DCMAKE_INSTALL_PREFIX=${workDirectory.path}/clang-newest",
      "-DLLVM_ENABLE_PROJECTS=clang",
      "-DLLVM_TARGETS_TO_BUILD=X86;AArch64",
    ], description: "Generate build files of llvm...");
  await executeProcess(workDirectory.path, "cmake", [
    "--build",
    "${workDirectory.path}/cmake",
    "--config",
    "Release",
  ]);

  await Directory(
    "${workDirectory.path}/clang-newest",
  ).create(recursive: true);
  await executeProcess(workDirectory.path, "cmake", [
    "--install",
    "${workDirectory.path}/cmake",
  ]);
}
