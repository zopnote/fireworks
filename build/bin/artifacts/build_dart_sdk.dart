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

import 'package:fireworks_scripts/environment.dart';
import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;

const String repository =
    "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
const List<String> requiredPrograms = const ["cmake", "git", "python"];

final String systemName = Platform.version.split("\"")[1];
final String scriptName = path.basenameWithoutExtension(Platform.script.path);
final String repositoryName = path.basenameWithoutExtension(repository);

final String workDirectoryPath = Platform.isWindows
    ? path.join(path.dirname(Platform.script.path), scriptName).substring(1)
    : path.join(path.dirname(Platform.script.path), scriptName);

final String buildFilesDirectoryPath = path.join(
  workDirectoryPath,
  "$repositoryName-$systemName-cmake-build",
);

final String repositoryDirectoryPath = path.join(
  workDirectoryPath,
  repositoryName,
);

final String outputDirectoryPath = path.join(
  workDirectoryPath,
  "$scriptName-$systemName",
);

final String dartDirectoryPath = path.join(workDirectoryPath, "dart");
final String dartSdkDirectoryPath = path.join(dartDirectoryPath, "sdk");

const String windowsAttentionMessage = """

Please ensure you have the Windows 10 SDK installed.
This can be installed separately or by checking the appropriate box in the Visual Studio Installer.
The SDK Debugging Tools must also be installed.
More information on https://github.com/dart-lang/sdk/blob/main/docs/Building.md
""";

Future<int> main() async {
  if (Platform.isWindows) {
    stdout.writeln(windowsAttentionMessage);
  }
  if (!ensurePrograms(requiredPrograms)) {
    stderr.writeln(
      "\nPlease ensure the availability of all dependencies to proceed.",
    );
    return 1;
  }

  await Directory(workDirectoryPath).create(recursive: true);

  if (!Directory(repositoryDirectoryPath).existsSync()) {
    await executeProcess(workDirectoryPath, "git", ["clone", repository]);
  }

  if (Platform.isMacOS) {
    await executeProcess(workDirectoryPath, "sudo", [
      "xcode",
      "-select",
      "-s",
      "/Applications/Xcode.app/Contents/Developer",
    ]);
  }

  if (Platform.isWindows) {
    await executeProcess(
      repositoryDirectoryPath,
      "gclient",
      [],
      runInShell: true,
      includeParentEnvironment: true,
    );
  }

  if (!Directory(dartDirectoryPath).existsSync()) {
    await Directory(dartDirectoryPath).create(recursive: true);
  }

  if (!await Directory(path.join(dartDirectoryPath, "sdk")).existsSync()) {
    await executeProcess(
      dartDirectoryPath,
      path.join(repositoryDirectoryPath, "fetch.bat"),
      ["dart"],
      exitOnFail: true,
      winAsAdministrator: true
    );
  }

  return 0;
}
