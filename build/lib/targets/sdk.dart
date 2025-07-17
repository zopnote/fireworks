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

import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import '../targets.dart';

final List<BuildStep> processSteps = [
  BuildStep(
    "Build high priority dependency artifacts",
    run: (env) async {
      final String vendorPath = "vendor";


      final BuildConfig clangConfig = BuildConfig(
        "clang",
        installPath: [vendorPath],
        buildType: env.buildType,
        variables: env.variables,
        target: env.target
      );
      final BuildConfig dartConfig = BuildConfig(
          "dart_sdk",
          installPath: [vendorPath],
          buildType: env.buildType,
          variables: env.variables,
          target: env.target
      );
      final BuildConfig appConfig = BuildConfig(
          "app",
          installPath: ["bin"],
          buildType: env.buildType,
          variables: {
            "dart_sdk_path": dartConfig.installDirectoryPath,
            "clang_path": clangConfig.installDirectoryPath
          }..addAll(env.variables),
          target: env.target
      );
      bool result = false;
      result = await clangConfig.execute(targets["clang"]!);
      result = result && await dartConfig.execute(targets["dart_sdk"]!);
      result = result && await appConfig.execute(targets["app"]!);
      return result;
    }
  )
];