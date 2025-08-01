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
 *
 */


import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'system.dart';
import 'step.dart';

/**
 * Representing the build type.
 *
 * [debug], [releaseDebug], [release]
 */
enum Config {
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

  const Config(this.name);

  /**
   * The name of a build type, not corresponding to third parties.
   */
  final String name;
}

/**
 * Represents a build configuration with information of the environment, the file system as well as host and targets.
 *
 * Manages the build life cycle with [Step].
 */
class Environment {
  /**
   * Name of the configuration to ensure no data conflicts between different build artifacts
   * a build configuration is used for. The name makes clear what is currently built with
   * the current configuration.
   */
  final String name;

  /**
   * Environment variables that get applied to process commands and are available in the entire configuration.
   */
  late final Map<String, dynamic> vars;

  final Config config;

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
  String get outputDirectoryPath =>
      path.join(rootDirectoryPath, "build", "out");

  /**
   * Root of the repository the dart scripts got executed.
   */
  String get rootDirectoryPath {
    io.Directory rootDirectory = io.Directory(scriptDirectoryPath);
    while (true) {
      if (io.Directory(path.join(rootDirectory.path, ".git")).existsSync()) {
        return rootDirectory.path;
      }
      rootDirectory = io.Directory(path.dirname(rootDirectory.path));
    }
  }

  String get installDirectoryPath => path.joinAll(
    [outputDirectoryPath] +
        [this.target.string(), this.config.name] +
        this._installPath,
  );

  /**
   * Temporal directory for files.
   */
  String get workDirectoryPath => path.join(
    outputDirectoryPath,
    this.target.string(),
    "targets-build",
    this.name,
  );

  /**
   * Directory of the script run in this isolate.
   */
  String get scriptDirectoryPath => io.Platform.isWindows
      ? path.dirname(io.Platform.script.path).substring(1)
      : path.dirname(io.Platform.script.path);

  Environment(
      this.name, {
        List<String> installPath = const [],
        final System? target,
        this.config = Config.debug,
        final Map<String, dynamic>? vars,
      }) : _installPath = installPath,
        this.target = target ?? System.current(),
        this.vars = vars != null ? ({}..addAll(vars)) : {};

  Map<String, dynamic> toJson() {
    Map<String, dynamic> toJsonMap(Map<String, dynamic> map) {
      final Map<String, dynamic> jsonMap = {};
      map.forEach((key, val) {
        if (val is String) {
          jsonMap[key] = val;
        } else if (val is num) {
          jsonMap[key] = val;
        } else if (val is List<String>) {
          jsonMap[key] = val.join(" ");
        } else if (val is Platform) {
          jsonMap[key] = val.name;
        } else if (val is Processor) {
          jsonMap[key] = val.name;
        } else if (val is io.Directory) {
          jsonMap[key] = val.path;
        } else if (val is Map<String, dynamic>) {
          jsonMap[key] = toJsonMap(val);
        }
      });
      return jsonMap;
    }

    return toJsonMap(vars);
  }

  Future<bool> execute(List<Step> steps, {String suffix = ""}) async {
    if (!io.Directory(this.outputDirectoryPath).existsSync()) {
      io.Directory(this.outputDirectoryPath).createSync(recursive: true);
    }
    if (!io.Directory(this.installDirectoryPath).existsSync()) {
      io.Directory(this.installDirectoryPath).createSync(recursive: true);
    }
    if (!io.Directory(this.workDirectoryPath).existsSync()) {
      io.Directory(this.workDirectoryPath).createSync(recursive: true);
    }

    bool result;
    final io.File processFile = io.File(
      path.join(this.workDirectoryPath, "../", ".${this.name}_build.steps"),
    );
    final String Function(String) format = (str) {
      return str
          .replaceAll(",", ",\n  ")
          .replaceAll("{", "\n  ")
          .replaceAll("}", "\n")
          .replaceAll(":", ": ");
    };

    final int bars = 80;
    final int dots = 10;

    final void Function(Map<String, dynamic>) addStep = (map) {
      processFile.writeAsStringSync(
        "\n${format(convert.jsonEncode(map))}\n${".." * dots}",
        mode: io.FileMode.append,
      );
    };

    processFile.writeAsStringSync(
      "${"-" * bars}\n${" " * 26}ENVIRONMENT CONSTANTS\n" +
          format(
            convert.jsonEncode({
              "name": this.name,
              "host": this.host.string(),
              "target": this.target.string(),
              "build_type": this.config.name,
              "work_directory": this.workDirectoryPath,
              "output_directory": this.outputDirectoryPath,
              "script_directory": this.scriptDirectoryPath,
              "install_directory": this.installDirectoryPath,
              "install_path": this._installPath.join("/"),
              "root_directory": this.rootDirectoryPath,
            }),
          ) +
          "\n\n${"-" * bars}\n${" " * 26}STEPS EXECUTION\n\n${"." * dots * 2}",
    );

    for (int i = 0; i < steps.length; i++) {
      final Step step = steps[i];
      try {
        const String spaceCharacter = " ";
        String targetName = "⟮" + this.name + "⟯" + spaceCharacter;
        String message = targetName + "⟮${i + 1}⁄${steps.length}⟯" + spaceCharacter;

        if (step.configure != null) {
          await step.configure!(this);
        }
        if (step.condition != null) {
          if (!await step.condition!(this)) {
            io.stdout.writeln(message + "Skipped");
            continue;
          }
        }
        result = await step.execute(
          this,
          message: message + step.name,
        );

      } catch (e) {
        io.stderr.writeln(
          "\nError while executing step '${step.name}' (${i + 1} out of ${steps.length}).",
        );
        rethrow;
      }
      addStep(
        <String, dynamic>{
          "index": "${i + 1} of ${steps.length}",
          "result": result,
          "description": step.name,
          "wasCritical": step.exitFail && !result,
          if (step.command != null)
            "command":
            step.command!(this).program +
                " " +
                step.command!(this).arguments.join(" "),
        }..addAll(toJson()),
      );

      if (!result && step.exitFail) {
        return false;
      }
    }
    return true;
  }
}

bool install({
  List<String> installPath = const [],
  List<String> directoryNames = const [],
  List<String> fileNames = const [],
  List<String> rootDirectoryPath = const [],
  List<String> excludeEndings = const [],
  List<String> relativePath = const [],
}) {
  try {
    final io.Directory workDirectory = io.Directory(
      path.joinAll(rootDirectoryPath + relativePath),
    );
    for (final entity in workDirectory.listSync()) {
      if (entity is io.File) {
        if (!fileNames.contains(path.basenameWithoutExtension(entity.path))) {
          continue;
        }
        if (excludeEndings.contains(path.extension(entity.path))) {
          continue;
        }
        final String filePath = path.join(
          path.joinAll(installPath),
          path.joinAll(installPath),
          path.relative(entity.path, from: path.joinAll(rootDirectoryPath)),
        );
        final fileDirectory = io.Directory(path.dirname(filePath));
        if (!fileDirectory.existsSync()) {
          fileDirectory.createSync(recursive: true);
        }
        entity.copySync(filePath);
      } else if (entity is io.Directory) {
        if (!directoryNames.contains(
          path.basenameWithoutExtension(entity.path),
        )) {
          continue;
        }
        final files = entity
            .listSync(recursive: true)
            .where((e) => (e is io.File))
            .cast<io.File>();
        for (final io.File file in files) {
          final String filePath = path.join(
            path.joinAll(installPath),
            path.relative(entity.path, from: path.joinAll(rootDirectoryPath)),
            path.relative(file.path, from: entity.path),
          );
          final fileDirectory = io.Directory(path.dirname(filePath));
          if (!fileDirectory.existsSync()) {
            fileDirectory.createSync(recursive: true);
          }
          file.copySync(filePath);
        }
      }
    }
    return true;
  } catch (e) {
    return false;
  }
}

bool ensurePrograms(List<String> requiredPrograms) {
  final String executableExtension = io.Platform.isWindows ? ".exe" : "";
  final List<String> pathVariableEntries =
      io.Platform.environment["PATH"]?.split(io.Platform.isWindows ? ";" : ":") ?? [];

  if (requiredPrograms.isEmpty) return true;

  bool isAllFound = true;
  for (String program in requiredPrograms) {
    bool found = false;
    for (String pathVariableEntry in pathVariableEntries) {
      final io.File programFile = io.File(
        path.join(pathVariableEntry, "$program$executableExtension"),
      );
      if (programFile.existsSync()) {
        found = true;
      }
    }

    if (!found) {
      final result = io.Process.runSync(
        program,
        [],
        runInShell: true,
        includeParentEnvironment: true,
      );
      if (result.exitCode == 0) {
        found = true;
      }
    }

    if (!found) {
      io.stderr.write("$program" + " ✖  ");
      isAllFound = false;
    }
  }
  return isAllFound;
}
