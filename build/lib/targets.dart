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

import 'build.dart';
import 'targets/vendor/clang.dart' as clang;
import 'targets/vendor/dart_sdk.dart' as dart_sdk;
import 'targets/app/app.dart' as app;
import 'targets/sdk.dart' as sdk;


/// All registered build targets
final Map<String, List<Step>> targets = {
  "sdk": sdk.processSteps,
  "clang": clang.processSteps,
  "dart_sdk": dart_sdk.processSteps,
  "app": app.processSteps
};