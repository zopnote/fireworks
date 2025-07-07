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
import 'package:path/path.dart' as path;

final String system = Platform.version.split("\"")[1];
final String systemProcessor = system.split("_").last;
final String systemName = system.split("_").first;

/// Notice that Platform.script is the script ran at initialization, not the script we are in.
/// Therefore currentDirectory will be the directory of the script that initialized the entire tree of imports etc.
String get currentDirectory {
  if (Platform.isWindows) {
    return path.dirname(Platform.script.path).substring(1);
  }
  return path.dirname(Platform.script.path);
}

final String scriptName = path.basenameWithoutExtension(Platform.script.path);

const String _entityAtRootLevel = ".git";
String get rootDirectory {
  Directory rootDirectory = Directory(currentDirectory);
  while (true) {
    if (Directory(
      path.join(rootDirectory.path, _entityAtRootLevel),
    ).existsSync()) {
      return rootDirectory.path;
    }
    rootDirectory = Directory(path.dirname(rootDirectory.path));
  }
}

final String workDirectory = path.join(
  outputDirectory,
  "${scriptName}-${system}",
);

const String _outputDirectoryName = "out";
String get outputDirectory {
  return path.join(rootDirectory, _outputDirectoryName);
}

final Iterable<String> flags = Platform.executableArguments.where(
  (arg) => arg.startsWith("--"),
);

bool isFlag(String flag) {
  for (String argumentFlag in flags) {
    if (flag == argumentFlag) return true;
  }
  return false;
}

final String pathVariableSeparator = Platform.isWindows ? ";" : ":";
final String executableExtension = Platform.isWindows ? ".exe" : "";
final List<String> pathVariableEntries =
    Platform.environment["PATH"]?.split(pathVariableSeparator) ?? [];

bool ensurePrograms(List<String> requiredPrograms) {
  if (requiredPrograms.isEmpty) return true;
  stdout.writeln("Check for programs in the environment...");

  bool isAllFound = true;
  for (String program in requiredPrograms) {
    bool found = false;
    for (String pathVariableEntry in pathVariableEntries) {
      final File programFile = File(
        path.join(pathVariableEntry, "$program$executableExtension"),
      );
      if (programFile.existsSync()) {
        found = true;
      }
    }

    if (!found) {
      final result = Process.runSync(
        program,
        [],
        runInShell: true,
        includeParentEnvironment: true,
      );
      if (result.exitCode == 0) {
        found = true;
      }
    }
    final int space = 20 - program.length;

    if (found) {
      stdout.writeln("$program" + (" " * space) + "FOUND");
    } else {
      stderr.writeln("$program" + (" " * space) + "NOT FOUND");
      isAllFound = false;
    }
  }
  return isAllFound;
}
