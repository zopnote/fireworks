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

import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;

const String _hostSystemKey = "host_system";
const String _hostSystemNameKey = "host_system_name";
const String _hostSystemProcessorKey = "host_system_processor";
const String _targetSystemKey = "target_system";
const String _targetSystemNameKey = "target_system_name";
const String _targetSystemProcessorKey = "target_system_processor";
const String _workDirectoryKey = "work_directory";
const String _scriptDirectoryKey = "script_directory";
const String _projectRootDirectoryKey = "root_directory";
const String _outputDirectoryKey = "output_directory";

enum BuildType {
  debug({"normal": "debug", "cmake": "Debug"}),
  releaseDebug({"normal": "rel_debug", "cmake": "RelWithDebInfo"}),
  release({"normal": "release", "cmake": "Release"});

  const BuildType(this.name);
  final Map<String, String> name;
}

enum SystemName {
  windows({
    "normal": "windows",
    "cmake": "Windows"
  }),
  android({
    "normal": "android",
    "cmake": "Android"
  }),
  linux({
    "normal": "linux",
    "cmake": "Linux"
  }),
  ios({
    "normal": "ios",
    "cmake": "iOS"
  }),
  macos({
    "normal": "macos",
    "cmake": "Darwin"
  });

  const SystemName(this.name);
  final Map<String, String> name;
}

enum SystemProcessor {
  x86_64("x86_64", {
    "cmake_win": "AMD64",
    "cmake_linux": "x86_64",
    "cmake_macos": "x86_64",
    "android_abi": "x86_64",
    "dart": "x64"
  }),
  arm64("arm64", {
    "cmake_win": "ARM64",
    "cmake_linux": "aarch64",
    "cmake_macos": "arm64",
    "android_abi": "arm64-v8a"
  }),
  x86("x86", {
    "cmake_win": "X86",
    "cmake_linux": "i386",
    "android_abi": "x86"
  }),
  arm("arm", {
    "cmake_win": "ARM",
    "cmake_linux": "arm",
    "android_abi": "armeabi-v7a"
  }),
  riscv({

  });

  const SystemProcessor(this.name, this.alias);
  final String name;
  final Map<String, String> alias;
}

/// Representing processor architecture, operating system couple.
final class System {
  final SystemName name;
  final SystemProcessor processor;
  System({required this.name, required this.processor});
  factory System.current() {
    final String system = Platform.version.split("\"")[1];
    return System(
      name: SystemName.values.firstWhere(
        (i) => i.names.contains(system.split("_").first),
      ),
      processor: SystemProcessor.values.firstWhere(
        (i) => i.names.contains(system.split("_").last),
      ),
    );
  }
  String string() {
    return "${name.names.first}_${processor.names.first}";
  }
}

final class BuildEnvironment {
  BuildEnvironment({
    final System? target,
    this.buildType = BuildType.debug,
    final Map<String, dynamic>? vars,
    final Directory? workDirectory,
    final Directory? scriptDirectory,
    final Directory? rootDirectory,
    final Directory? outputDirectory,
  }) {
    late final Directory defaultScriptDirectory;
    if (Platform.isWindows) {
      defaultScriptDirectory = Directory(
        path.dirname(Platform.script.path).substring(1),
      );
    } else {
      defaultScriptDirectory = Directory(path.dirname(Platform.script.path));
    }

    Directory defaultRootDirectory = Directory(defaultScriptDirectory.path);
    while (true) {
      if (Directory(
        path.join(defaultRootDirectory.path, ".git"),
      ).existsSync()) {
        defaultRootDirectory = defaultRootDirectory;
        break;
      }
      defaultRootDirectory = Directory(path.dirname(defaultRootDirectory.path));
    }

    final Directory defaultOutputDirectory = Directory(
      path.join(defaultRootDirectory.path, "out"),
    );

    final Directory defaultWorkDirectory = Directory(
      path.join(defaultOutputDirectory.path, ".$scriptName"),
    );

    this.workDirectory = workDirectory ?? defaultWorkDirectory;
    this.scriptDirectory = scriptDirectory ?? defaultScriptDirectory;
    this.rootDirectory = rootDirectory ?? defaultRootDirectory;
    this.outputDirectory = outputDirectory ?? defaultOutputDirectory;
    this.target = target ?? System.current();

    if (vars != null) {
      this.vars = vars;
    } else {
      this.vars = {};
    }
    this.vars.addAll({
      _hostSystemKey: host.string(),
      _hostSystemNameKey: host.name,
      _hostSystemProcessorKey: host.processor,
      _targetSystemKey: this.target.string(),
      _targetSystemNameKey: this.target.name,
      _targetSystemProcessorKey: this.target.processor,
      _workDirectoryKey: this.workDirectory,
      _scriptDirectoryKey: this.scriptDirectory,
      _projectRootDirectoryKey: this.rootDirectory,
      _outputDirectoryKey: this.outputDirectory,
    });
  }

  factory BuildEnvironment.fromDefault(
    BuildEnvironment builder(BuildEnvironment defaultEnvironment),
  ) => builder(BuildEnvironment());

  BuildEnvironment override({
    final System? target,
    final BuildType? buildType,
    final Map<String, dynamic>? vars,
    final Directory? workDirectory,
    final Directory? scriptDirectory,
    final Directory? rootDirectory,
    final Directory? outputDirectory,
  }) => BuildEnvironment(
      target: target ?? this.target,
      buildType: buildType ?? this.buildType,
      vars: vars ?? this.vars,
      workDirectory: workDirectory ?? this.workDirectory,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      rootDirectory: rootDirectory ?? this.rootDirectory,
      scriptDirectory: scriptDirectory ?? this.scriptDirectory
  );

  final BuildType buildType;

  late final System target;

  final System host = System.current();

  late final Map<String, dynamic> vars;

  /// Name of the script run as entry of the dart isolate.
  static String scriptName = path.basenameWithoutExtension(
    Platform.script.path,
  );

  /// The directory where work has to be done.
  late final Directory workDirectory;

  /// Notice that Platform.script is the script ran at initialization, not the script we are in.
  /// Therefore scriptDirectory will be the directory of the script that initialized the entire tree of imports etc.
  late final Directory scriptDirectory;

  /// Project root directory, determined by the repository root.
  late final Directory rootDirectory;

  late final Directory outputDirectory;

  Map<String, String> toJson() {
    final Map<String, String> jsonMap = {};
    vars.forEach((key, value) {
      if (value is String) {
        jsonMap[key] = value;
      } else if (value is num || value is List<String>) {
        jsonMap[key] = value.toString();
      } else if (value is SystemName || value is SystemProcessor) {
        jsonMap[key] = value.name;
      } else if (value is Directory) {
        jsonMap[key] = value.path;
      }
    });
    return jsonMap;
  }

  static bool ensurePrograms(List<String> requiredPrograms) {
    final String executableExtension = Platform.isWindows ? ".exe" : "";
    final List<String> pathVariableEntries =
        Platform.environment["PATH"]?.split(Platform.isWindows ? ";" : ":") ??
        [];

    if (requiredPrograms.isEmpty) return true;

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

  Future<bool> execute(List<BuildStep> steps) async {
    bool result;
    for (int i = 0; i < steps.length - 1; i++) {
      result = await steps[i].execute(
        environment: this,
        message: "[${i + 1}/${steps.length}] ",
      );
      if (!result) {
        return false;
      }
    }
    return true;
  }
}
