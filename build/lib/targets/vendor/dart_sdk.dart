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

import 'package:fireworks.cli/build/environment.dart';
import 'package:fireworks.cli/build/process.dart';
import 'package:path/path.dart' as path;

List<BuildStep> processSteps = [
  BuildStep(
    "Ensures programs in environment",
    run: (env) => ensurePrograms(["python", "git"]),
  ),
  BuildStep(
    "Clone depot tools repository",
    configure: (env) {
      env.variables["depot_tools_url"] =
          "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
      env.variables["depot_tools_path"] = path.join(
        env.workDirectoryPath,
        path.basenameWithoutExtension(env.variables["depot_tools_url"]),
      );
    },
    condition: (env) =>
        !Directory(env.variables["depot_tools_path"]).existsSync(),
    command: (env) => BuildStepCommand(
      program: "git",
      arguments: ["clone", env.variables["depot_tools_url"]],
    ),
    exitFail: false,
  ),

  BuildStep(
    "Fetch the dart sdk",
    configure: (env) {
      if (env.host.platform == SystemPlatform.windows) {
        env.variables["DEPOT_TOOLS_WIN_TOOLCHAIN"] = 0;
      }
    },
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".dart-process-done"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: path.join(env.variables["depot_tools_path"], "fetch"),
      arguments: ["dart"],
      administrator: env.host.platform == SystemPlatform.windows,
    ),
    spinner: true,
  ),
  BuildStep(
    "Save available dart git tags",
    configure: (env) {
      env.variables["dart_tags_path"] = path.join(
        env.workDirectoryPath,
        ".dart-available-versions",
      );
      env.variables["dart_sdk_path"] = path.join(env.workDirectoryPath, "sdk");
    },
    condition: (env) =>
        (env.buildType != BuildType.release) &&
        !File(env.variables["dart_tags_path"]).existsSync(),
    command: (env) => BuildStepCommand(
      program: "git",
      arguments: [
        "tag",
        ">>",
        path.join("..", path.basename(env.variables["dart_tags_path"])),
      ],
      workingDirectoryPath: env.variables["dart_sdk_path"],
      shell: true,
    ),
  ),
  BuildStep(
    "Switch dart version tag",
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".gclient_previous_sync_commits"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: "git",
      arguments: ["checkout", "3.10.0-7.0.dev"],
      workingDirectoryPath: env.variables["dart_sdk_path"],
    ),
  ),
  BuildStep(
    "Synchronize gclient dependencies",
    configure: (env) {
      env.variables["gclient_script_file"] = path.join(
        env.variables["depot_tools_path"],
        "gclient" + (env.host.platform == SystemPlatform.windows ? ".bat" : ""),
      );
    },
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".gclient_previous_sync_commits"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: env.variables["gclient_script_file"],
      arguments: ["sync"],
      workingDirectoryPath: env.variables["dart_sdk_path"],
    ),
  ),
  BuildStep(
    "Build the sdk for the target operating system",
    configure: (env) {
      env.variables["dart_architecture"] = {
        SystemProcessor.x86_64: "x64",
        SystemProcessor.arm64: "arm64",
        SystemProcessor.arm: "arm",
        SystemProcessor.riscv64: "riscv64",
        SystemProcessor.x86: "ia32",
      }[env.target.processor]!;
      env.variables["dart_binaries_path"] = path.join(
        env.variables["dart_sdk_path"],
        "out",
        "Product" +
            (env.variables["dart_architecture"] as String).toUpperCase(),
      );
      env.variables["dart_dependency_python"] =
          env.host.platform == SystemPlatform.windows
          ? path.join(env.variables["depot_tools_path"], "python3.bat")
          : "python";
    },
    condition: (env) =>
        !Directory(env.variables["dart_binaries_path"]).existsSync(),
    command: (env) => BuildStepCommand(
      program: env.variables["dart_dependency_python"],
      arguments: [
        "${env.variables["dart_sdk_path"]}/tools/build.py",
        "--mode",
        "product",
        "--arch",
        env.variables["dart_architecture"],
        "create_sdk",
      ],
      workingDirectoryPath: env.variables["dart_sdk_path"],
    ),
  ),
  BuildStep(
    "Build simarm64 cross compilation gen snapshot tool",
    configure: (env) {
      env.variables["product_simarm64_utils_path"] = path.join(
        env.variables["dart_sdk_path"],
        "out",
        "ProductSIMARM64",
        "dart-sdk",
        "bin",
        "utils",
      );
    },
    condition: (env) =>
        !Directory(env.variables["product_simarm64_utils_path"]).existsSync(),
    command: (env) => BuildStepCommand(
      program: env.variables["dart_dependency_python"],
      arguments: [
        path.join(".", "tools", "build.py"),
        "--arch",
        "simarm64",
        "--mode",
        "product",
        "copy_gen_snapshot",
      ],
      workingDirectoryPath: env.variables["dart_sdk_path"],
    ),
  ),
  BuildStep(
    "Install platform sdk",
    condition: (env) => !Directory(
      path.join(env.installDirectoryPath, "bin", "utils"),
    ).existsSync(),
    run: (env) =>
    install(
      installPath: [env.installDirectoryPath],
      rootDirectoryPath: [env.variables["dart_binaries_path"]!, "dart-sdk"],
      relativePath: ["bin"],
      fileNames: ["dart", "dartaotruntime"],
    ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.variables["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["lib", "_internal"],
          directoryNames: ["vm", "vm_shared", "sdk_library_metadata"],
          fileNames: [
            "ddc_outline",
            "ddc_platform",
            "fix_data",
            "vm_platform",
            "vm_platform_product",
            "vm_platform_strong",
            "allowed_experiments",
          ],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.variables["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["lib"],
          directoryNames: [
            "_http",
            "async",
            "collection",
            "concurrent",
            "convert",
            "core",
            "developer",
            "ffi",
            "internal",
            "io",
            "isolate",
            "math",
            "typed_data",
          ],
          fileNames: ["api_readme.md", "libraries.json"],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.variables["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["bin", "snapshots"],
          fileNames: [
            "analysis_server_aot.dart",
            "dartdev.dart",
            "gen_kernel_aot.dart",
            "kernel_worker_aot.dart",
            "kernel-service.dart",
          ],
        ) &&
        install(
          installPath: [env.installDirectoryPath, "bin", "utils"],
          rootDirectoryPath: [env.variables["dart_binaries_path"]!],
          fileNames: [
            "gen_snapshot_product",
            "gen_snapshot_product_linux_x64",
            "gen_snapshot_product_linux_arm64",
            "gen_snapshot_product_linux_riscv64",
          ],
          excludeEndings: [".lib"],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.variables["dart_binaries_path"]!, "dart-sdk"],
          fileNames: ["version", "LICENSE"],
        ) &&
        (File(path.join(env.installDirectoryPath, "LICENSE"))
          ..rename(path.join(env.installDirectoryPath, "dart.license")))
            .existsSync() &&
        (File(path.join(env.installDirectoryPath, "version"))
          ..rename(path.join(env.installDirectoryPath, "dart.version")))
            .existsSync(),
    exitFail: false,
  ),
  BuildStep(
    "Install simarm64 cross compilation gen snapshot tool",
    configure: (env) {
      for (FileSystemEntity entity in Directory(
        env.variables["product_simarm64_utils_path"],
      ).listSync()) {
        if (!(entity is File)) continue;

        if (path.basenameWithoutExtension(entity.path) != "gen_snapshot")
          continue;

        env.variables["simarm64_snapshot_path"] = path.join(
          env.variables["product_simarm64_utils_path"],
          path.basename(entity.path),
        );
      }
      env.variables["executable_ending"] =
          (env.target.platform == SystemPlatform.windows ? ".exe" : "");
    },
    condition: (env) => !File(env.variables["simarm64_snapshot_path"]).existsSync(),
    run: (env) =>
        (File(env.variables["simarm64_snapshot_path"])..copySync(
              path.join(
                env.installDirectoryPath,
                "bin",
                "utils",
                "gen_snapshot_product_simarm64" +
                    env.variables["executable_ending"],
              ),
            ))
            .existsSync(),
  ),
];
