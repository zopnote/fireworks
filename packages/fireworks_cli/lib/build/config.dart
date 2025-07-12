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

import 'dart:convert';
import 'dart:io';

import 'process.dart';
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

enum BuildType { debug, releaseDebug, release }

enum SystemPlatform { windows, android, linux, ios, macos }

enum SystemProcessor { x86_64, x86, arm64, arm, riscv64 }

/// Representing processor architecture, operating system couple.
final class System {
  final SystemPlatform platform;
  final SystemProcessor processor;
  System({required this.platform, required this.processor});
  factory System.current() {
    final String system = Platform.version.split("\"")[1];
    return System(
      platform: SystemPlatform.values.firstWhere(
        (i) => i.name == system.split("_").first,
      ),
      processor: {
        "x64": SystemProcessor.x86_64,
        "arm64": SystemProcessor.arm64,
        "arm": SystemProcessor.arm,
        "riscv64": SystemProcessor.riscv64,
      }[system.split("_").last]!,
    );
  }
  String string() {
    return "${platform.name}_${processor.name}";
  }
}

typedef BuildConfigCallback = BuildConfig Function(BuildConfig config);

final class BuildConfig {
  BuildConfig({
    final System? target,
    this.buildType = BuildType.debug,
    final Map<String, dynamic>? variables,
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

    if (variables != null) {
      this.variables = variables;
    } else {
      this.variables = {};
    }
    this.variables.addAll({
      _hostSystemKey: host.string(),
      _hostSystemNameKey: host.platform,
      _hostSystemProcessorKey: host.processor,
      _targetSystemKey: this.target.string(),
      _targetSystemNameKey: this.target.platform,
      _targetSystemProcessorKey: this.target.processor,
      _workDirectoryKey: this.workDirectory,
      _scriptDirectoryKey: this.scriptDirectory,
      _projectRootDirectoryKey: this.rootDirectory,
      _outputDirectoryKey: this.outputDirectory,
    });
  }

  factory BuildConfig.overrideDefault(final BuildConfigCallback callback) {
    return BuildConfig().override(callback);
  }

  BuildConfig override(final BuildConfigCallback callback) {
    final BuildConfig call = callback(this);
    return BuildConfig(
      variables: {}
        ..addAll(this.variables)
        ..addAll(call.variables),
      outputDirectory: call.outputDirectory,
      target: call.target,
      buildType: call.buildType,
      rootDirectory: call.rootDirectory,
      scriptDirectory: call.scriptDirectory,
      workDirectory: call.workDirectory,
    );
  }

  BuildConfig reconfigure({
    final System? target,
    final BuildType? buildType,
    final Map<String, dynamic>? variables,
    final Directory? workDirectory,
    final Directory? scriptDirectory,
    final Directory? rootDirectory,
    final Directory? outputDirectory,
  }) => BuildConfig(
    target: target ?? this.target,
    buildType: buildType ?? this.buildType,
    variables: variables ?? this.variables,
    workDirectory: workDirectory ?? this.workDirectory,
    outputDirectory: outputDirectory ?? this.outputDirectory,
    rootDirectory: rootDirectory ?? this.rootDirectory,
    scriptDirectory: scriptDirectory ?? this.scriptDirectory,
  );

  final BuildType buildType;

  late final System target;

  final System host = System.current();

  late final Map<String, dynamic> variables;

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


  Map<String, dynamic> toJson() {
    Map<String, dynamic> toJsonMap(Map<String, dynamic> map) {
      final Map<String, dynamic> jsonMap = {};
      map.forEach((key, val) {
        if (val is String) {
          jsonMap[key] = val;
        } else if (val is num || val is List<String>) {
          jsonMap[key] = val;
        } else if (val is SystemPlatform) {
          jsonMap[key] = val.name;
        } else if (val is SystemProcessor) {
          jsonMap[key] = val.name;
        } else if (val is Directory) {
          jsonMap[key] = val.path;
        } else if (val is Map<String, dynamic>) {
          jsonMap[key] = toJsonMap(val);
        }
      });
      return jsonMap;
    }
    return toJsonMap(variables);
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
    if (!this.outputDirectory.existsSync()) {
      this.outputDirectory.createSync(recursive: true);
    }
    if (!this.workDirectory.existsSync()) {
      this.workDirectory.createSync(recursive: true);
    }

    File(
      path.join(this.outputDirectory.path, "build_config.json"),
    ).writeAsStringSync(jsonEncode(toJson()));

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
