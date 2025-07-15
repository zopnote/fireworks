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
      bool result = await BuildConfig(
        "clang",
        installPath: ["bin", "clang"],
        buildType: env.buildType,
        variables: env.variables,
        target: env.target
      ).execute(targets["clang"]!);
      result = result && await BuildConfig(
          "dart_sdk",
          installPath: ["bin", "dart_sdk"],
          buildType: env.buildType,
          variables: env.variables,
          target: env.target
      ).execute(targets["dart_sdk"]!);
      return result;
    }
  )
];