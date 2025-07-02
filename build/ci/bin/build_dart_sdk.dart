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
  const String depotRepository = "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
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
      path.basenameWithoutExtension(depotRepository),
    ),
  ).exists())) {
    await executeProcess(workDirectory.path, "git", [
      "clone",
      depotRepository,
    ]);
  }
  if (Platform.isMacOS) await executeProcess(
      workDirectory.path, "sudo", [
    "xcode",
    "-select",
    "-s",
    "/Applications/Xcode.app/Contents/Developer"
  ]);

  final String system = Platform.version.split('\"')[1];

}