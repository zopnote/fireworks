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

List<BuildStep> processSteps = [
  BuildStep(
    "Ensures programs in environment",
    condition: (env) => BuildConfig.ensurePrograms(["python", "git"]),
  ),
  BuildStep(
    "Set system variable",
    condition: (env) => env.host.platform == SystemPlatform.windows,
    run: (env) {
      env.variables["DEPOT_TOOLS_WIN_TOOLCHAIN"] = 0;
      return true;
    },
  ),
  BuildStep(
    "Clone depot tools",
    condition: (env) {
      env.variables["repository_url"] =
          "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
      env.variables["repository_path"] = path.join(
        env.workDirectoryPath,
        path.basenameWithoutExtension(env.variables["repository_url"]),
      );
      return !Directory(env.variables["repository_path"]).existsSync();
    },
    command: (env) {
      return BuildStepCommand(
        program: "git",
        arguments: ["clone", env.variables["repository_url"]],
      );
    },
    exitFail: false,
  ),
  BuildStep(
    "Fetch the dart sdk",
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".dart-process-done"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: path.join(env.variables["repository_path"], "fetch"),
      arguments: ["dart"],
      administrator: env.host.platform == SystemPlatform.windows,
    ),
    spinner: true,
  ),
  BuildStep(
    "Synchronize gclient",
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".gclient_previous_sync_commits"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: path.join(
        env.variables["repository_path"],
        "gclient" + (env.host.platform == SystemPlatform.windows ? ".bat" : ""),
      ),
      arguments: ["sync"],
      workingDirectoryPath: path.join(env.workDirectoryPath, "sdk"),
    ),
  ),
  BuildStep(
    "Build the sdk for the target operating system",
    condition: (env) {
      env.variables["dart_architecture"] = {
        SystemProcessor.x86_64: "x64",
        SystemProcessor.arm64: "arm64",
        SystemProcessor.arm: "arm",
        SystemProcessor.riscv64: "riscv64",
        SystemProcessor.x86: "ia32",
      }[env.target.processor]!;

      env.variables["dart_binaries_path"] = path.join(
        env.workDirectoryPath,
        "sdk",
        "out",
        "Product" +
            (env.variables["dart_architecture"] as String).toUpperCase(),
      );
      return !Directory(env.variables["dart_binaries_path"]).existsSync();
    },
    command: (env) => BuildStepCommand(
      program: env.host.platform == SystemPlatform.windows
          ? path.join(env.variables["repository_path"], "python3.bat")
          : "python",
      arguments: [
        "${path.join(env.workDirectoryPath, "sdk")}/tools/build.py",
        "--mode",
        "product",
        "--arch",
        env.variables["dart_architecture"],
        "create_sdk",
      ],
      workingDirectoryPath: path.join(env.workDirectoryPath, "sdk"),
    ),
  ),
  BuildStep(
    "Install platform sdk",
    condition: (env) => !Directory(
      path.join(env.installDirectoryPath, "bin", "utils"),
    ).existsSync(),
    run: (env) {
      final List<String> installable = [
        "dart",
        "dartaotruntime",
        "utils",
        "snapshot",
        "lib",
        "sdk_packages",
        "version",
        "revision",
        "LICENSE",
      ];
      for (FileSystemEntity entity in Directory(
        path.join(env.variables["dart_binaries_path"], "dart-sdk"),
      ).listSync(recursive: true)) {
        if (!installable.contains(path.basenameWithoutExtension(entity.path))) {
          continue;
        }
        if (!(entity is File)) continue;
        Directory(path.dirname(entity.path)).createSync(recursive: true);
        entity.copySync(
          path.join(
            env.installDirectoryPath,
            path.dirname(
              path.relative(
                entity.path,
                from: path.join(
                  env.variables["dart_binaries_path"],
                  "dart-sdk",
                ),
              ),
            ),
          ),
        );
      }
      for (FileSystemEntity entity in Directory(
        path.join(env.variables["dart_binaries_path"], "dart-sdk", "bin"),
      ).listSync(recursive: true)) {
        if (entity is File) {
          if (!installable.contains(
            path.basenameWithoutExtension(entity.path),
          )) {
            continue;
          }

          Directory(path.dirname(entity.path)).createSync(recursive: true);
          entity.copySync(
            path.join(
              env.installDirectoryPath,
              path.dirname(
                path.relative(
                  entity.path,
                  from: path.join(
                    env.variables["dart_binaries_path"],
                    "dart-sdk",
                  ),
                ),
              ),
            ),
          );
        }
      }
      return true;
    },
  ),
  BuildStep(
    "Build simarm64 cross compilation gen snapshot tool",
    condition: (env) {
      env.variables["snap_out_path"] = path.join(
        env.workDirectoryPath,
        "sdk",
        "out",
        "ReleaseSIMARM64",
      );
      return !Directory(env.variables["snap_out_path"]).existsSync();
    },
    command: (env) {
      return BuildStepCommand(
        program: env.host.platform == SystemPlatform.windows
            ? path.join(env.variables["repository_path"], "python3.bat")
            : "python",
        arguments: [
          path.join(".", "tools", "build.py"),
          "--arch",
          "simarm64",
          "--mode",
          "product",
          "copy_gen_snapshot",
        ],
        workingDirectoryPath: path.join(env.workDirectoryPath, "sdk"),
      );
    },
  ),
  BuildStep(
    "Install simarm64 cross compilation gen snapshot tool",
    condition: (env) {
      env.variables["simarm64_snapshot_name"] = "simarm64_gen_snapshot";
      bool found = true;
      Directory(env.installDirectoryPath).listSync().forEach((e) {
        if (path.basenameWithoutExtension(e.path) ==
            env.variables["simarm64_snapshot_name"]) {
          found = false;
        }
      });
      return found;
    },
    run: (env) {
      env.variables["executable_ending"] =
          (env.target.platform == SystemPlatform.windows ? ".exe" : "");
      Directory(env.installDirectoryPath).listSync().forEach((e) {
        if (path.basenameWithoutExtension(e.path) ==
            env.variables["simarm64_snapshot_name"]) {
          (e as File).copySync(
            path.join(
              env.installDirectoryPath,
              env.variables["simarm64_snapshot_name"] +
                  env.variables["executable_ending"],
            ),
          );
        }
      });
      return true;
    },
  ),
];
