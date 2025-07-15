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
import 'dart:math';

import 'process.dart';
import 'package:path/path.dart' as path;

/**
 * Representing the build type.
 *
 * [debug], [releaseDebug], [release]
 */
enum BuildType {
  /**
   * Referees to a build including assertions and debug symbols as well as no optimizations.
   */
  debug("debug"),

  /**
   * Referees to a build with assertions and debug symbols as well as all optimizations.
   */
  releaseDebug("debug_release"),

  /**
   * Referees to a build without debug symbols and assertions as well as all optimizations.
   */
  release("release");

  const BuildType(this.name);

  /**
   * The name of a build type, not corresponding to third parties.
   */
  final String name;
}

/**
 * Representing a specific operating system.
 */
enum SystemPlatform { windows, android, linux, ios, macos }

/**
 * Representing a specific processor architecture.
 */
enum SystemProcessor { x86_64, x86, arm64, arm, riscv64 }

/**
 * Operating system, processor couple to determine the full platform in context.
 */
final class System {
  final SystemPlatform platform;
  final SystemProcessor processor;
  System(this.platform, this.processor);
  static System? parseString(String string) {
    SystemPlatform? platform = null;
    SystemProcessor? processor = null;

    for (SystemPlatform systemValue in SystemPlatform.values) {
      if (systemValue.name == string.split("_").first) {
        platform = systemValue;
      }
    }
    for (SystemProcessor processorValue in SystemProcessor.values) {
      if (processorValue.name == string.split("_").sublist(1).join("_")) {
        processor = processorValue;
      }
    }
    if (platform == null || processor == null) return null;
    return System(platform, processor);
  }

  factory System.current() {
    final String system = Platform.version.split("\"")[1];
    return System(
      SystemPlatform.values.firstWhere(
        (i) => i.name == system.split("_").first,
      ),
      {
        "x64": SystemProcessor.x86_64,
        "arm64": SystemProcessor.arm64,
        "arm": SystemProcessor.arm,
        "riscv64": SystemProcessor.riscv64,
      }[system.split("_").last]!,
    );
  }

  /**
   *  A formatted version of System for use of representation.
   */
  String string() {
    return "${platform.name}_${processor.name}";
  }
}

/**
 * Represents a build configuration with information of the environment, the file system as well as host and targets.
 *
 * Manages the build life cycle with [BuildStep].
 */
class BuildConfig {
  /**
   * Name of the configuration to ensure no data conflicts between different build artifacts
   * a build configuration is used for. The name makes clear what is currently built with
   * the current configuration.
   */
  final String name;

  /**
   * Environment variables that get applied to process commands and are available in the entire configuration.
   */
  late final Map<String, dynamic> variables;

  final BuildType buildType;

  /**
   * Path relative to the output directory to install binaries at.
   */
  final List<String> _installPath;

  /**
   * The target system of this build configuration.
   * If not set, it will be automatically set to [System.current()].
   */
  late final System target;

  /**
   * The current Platform, determined by the Dart VM.
   */
  final System host = System.current();

  /**
   * Bare output directory of the project binaries.
   */
  String get outputDirectoryPath => path.join(rootDirectoryPath, "build", "out");

  /**
   * Root of the repository the dart scripts got executed.
   */
  String get rootDirectoryPath {
    Directory rootDirectory = Directory(scriptDirectoryPath);
    while (true) {
      if (Directory(path.join(rootDirectory.path, ".git")).existsSync()) {
        return rootDirectory.path;
      }
      rootDirectory = Directory(path.dirname(rootDirectory.path));
    }
  }

  String get installDirectoryPath => path.joinAll(
    [outputDirectoryPath] +
        [this.target.string(), this.buildType.name] +
        this._installPath,
  );

  /**
   * Temporal directory for files.
   */
  String get workDirectoryPath =>
      path.join(outputDirectoryPath, this.target.string(), this.name);

  /**
   * Directory of the script run in this isolate.
   */
  String get scriptDirectoryPath => Platform.isWindows
      ? path.dirname(Platform.script.path).substring(1)
      : path.dirname(Platform.script.path);

  BuildConfig(
    this.name, {
    List<String> installPath = const [],
    final System? target,
    this.buildType = BuildType.debug,
    final Map<String, dynamic>? variables,
  }) : _installPath = installPath,
       this.target = target ?? System.current(),
       this.variables = variables != null ? ({}..addAll(variables)) : {};

  Map<String, dynamic> toJson() {
    Map<String, dynamic> toJsonMap(Map<String, dynamic> map) {
      final Map<String, dynamic> jsonMap = {
        "host": host.string(),
        "target": this.target.string(),
        "install_path": this._installPath.join("/"),
      };
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

  Future<bool> execute(List<BuildStep> steps) async {
    if (!Directory(this.outputDirectoryPath).existsSync()) {
      Directory(this.outputDirectoryPath).createSync(recursive: true);
    }
    if (!Directory(this.installDirectoryPath).existsSync()) {
      Directory(this.installDirectoryPath).createSync(recursive: true);
    }
    if (!Directory(this.workDirectoryPath).existsSync()) {
      Directory(this.workDirectoryPath).createSync(recursive: true);
    }

    bool result;
    for (int i = 0; i < steps.length; i++) {
      try {
        result = await steps[i].execute(
          env: this,
          message: "⟮${i + 1}⁄${steps.length}⟯ ",
        );
      } catch (e) {
        stderr.writeln(
          "\nError while executing step '${steps[i].name}' (${i + 1} out of ${steps.length}).",
        );
        rethrow;
      } finally {
        File(
          path.join(this.installDirectoryPath, "${this.name}_build.json"),
        ).writeAsStringSync(
          jsonEncode(toJson())
              .replaceAll(",", ",\n  ")
              .replaceAll("{", "{\n  ")
              .replaceAll("}", "\n}")
              .replaceAll(":", ": "),
        );
      }
      if (!result && steps[i].exitFail) {
        return false;
      }
    }
    return true;
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

      if (found) {
        stdout.write("$program" + " ✔  ");
      } else {
        stderr.write("$program" + " ✖  ");
        isAllFound = false;
      }
    }
    stdout.writeln("");
    return isAllFound;
  }
}
