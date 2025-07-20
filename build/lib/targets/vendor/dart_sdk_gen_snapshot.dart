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
 *
 */

import 'dart:convert';
import 'dart:io';

import 'package:fireworks.cli/build/process.dart';
import 'package:path/path.dart' as path;

/// We have to add custom targets to the SDK Generate Ninja
/// build scripts. These changes are part of this List.
///
/// We add targets (public_deps dependencies) to the target "create_sdk",
/// that built then the gen_snapshot tools, necessary for android arm64 cross compilation,
/// as well as
final List<BuildStep> editSDKSteps = [
  BuildStep(
    "Add configs to runtime build gn",
    configure: (env) {
      if (env.variables["dart_sdk_root_path"] == null) {
        throw Exception(
          "You have to specify the Dart SDK root to execute further steps.",
        );
      }
      env.variables["runtime_build_file"] = path.join(
        env.variables["dart_sdk_root_path"],
        "runtime",
        "BUILD.gn",
      );

      env.variables["runtime_bin_build_file"] = path.join(
        env.variables["dart_sdk_root_path"],
        "runtime",
        "bin",
        "BUILD.gn",
      );
    },
    run: (env) {
      RandomAccessFile runtimeFile = File(
        env.variables["runtime_build_file"],
      ).openSync(mode: FileMode.append);
      runtimeFile.writeStringSync(
          """
          config("dart_android_arm64_config") {
            defines = [
              "DART_TARGET_OS_ANDROID",
              "TARGET_ARCH_ARM64",
            ]
          }
          
          config("dart_android_arm_config") {
            defines = [
              "DART_TARGET_OS_ANDROID",
              "TARGET_ARCH_ARM",
            ]
          }
          """);
      runtimeFile.closeSync();

      RandomAccessFile runtimeBinFile = File(
        env.variables["runtime_bin_build_file"],
      ).openSync(mode: FileMode.append);

      runtimeBinFile.
    },
  ),
];
