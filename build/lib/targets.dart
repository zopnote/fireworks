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

import 'package:fireworks.cli/build/process.dart';

import 'targets/artifacts/clang.dart' as clang;
import 'targets/artifacts/dart_sdk.dart' as dart_sdk;
import 'targets/sdk.dart' as sdk;


/// All registered build targets
final Map<String, List<BuildStep>> targets = {
  "sdk": sdk.processSteps,
  "clang": clang.processSteps,
  "dart_sdk": dart_sdk.processSteps
};