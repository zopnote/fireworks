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

import 'package:fireworks/runner.dart';
import 'package:path/path.dart' as path;

CommandResponse doctor(Command cur, String argument, List<Flag> flags) {
  stdout.writeln("Health of the fireworks tooling:");
  final String varSeperator = Platform.isWindows ? ";" : ":";
  final String exeExtension = Platform.isWindows ? ".exe" : ":";
  final List<String> envPaths = Platform.environment["PATH"]?.split(varSeperator) ?? [];
  List<String> tools = [
    "clang", "cmake", "ninja", "dart"
  ];
  for (String tool in tools) {
    bool found = false;
    for (String envPath in envPaths) {
      if (File("$envPath${path.separator}$tool$exeExtension").existsSync())
        found = true;
    }
    if (found) stdout.writeln("$tool$exeExtension is found.");
    else stdout.writeln("$tool$exeExtension is not found.");
  }

  return CommandResponse("Escaped successful.");
}