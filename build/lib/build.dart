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

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:io' as io;

import 'package:path/path.dart' as path;

/**
 * Representation of a command that can be executed as part of [BuildProcess];
 */
final class Step {
  final String name;

  /// Function that will run.
  final async.FutureOr<bool> Function(Environment environment)? run;

  final StepCommand Function(Environment environment)? command;

  /// If a false value received by run() or the command should terminate the [BuildProcess]
  final bool exitFail;

  final async.FutureOr<bool> Function(Environment environment)? condition;
  final async.FutureOr<void> Function(Environment environment)? configure;

  /// If the process should get a spinner.
  /// Notice that any input to stdout or stderr will move the spinner to the last line.
  /// Therefore stop the spinner before any result information have to printed
  /// or another step will be executed.
  final bool spinner;

  const Step(
    this.name, {
    this.command,
    this.run,
    this.exitFail = true,
    this.condition,
    this.configure,
    this.spinner = false,
  });

  Future<bool> execute(final Environment env, {String message = ""}) async {
    ProcessSpinner? spinner;
    bool exitExecute(bool returnable) {
      if (spinner != null) {
        spinner.stop(message);
        return returnable;
      }
      return returnable;
    }

    if (this.spinner) {
      spinner = ProcessSpinner(env)..start(message);
    } else {
      io.stdout.writeln(message);
    }
    if (run != null) {
      return exitExecute(await run!(env));
    }

    if (this.command == null) {
      return exitExecute(true);
    }

    final StepCommand command = this.command!(env);
    final String program = command.administrator
        ? io.Platform.isWindows
              ? "powershell.exe"
              : "sudo ${command.program}"
        : command.program;

    final List<String> arguments;
    final String doneFilePath = path.join(
      command.workingDirectoryPath ?? env.workDirectoryPath,
      ".${env.name}-process-done",
    );
    if (command.administrator && io.Platform.isWindows) {
      arguments = [
        "-Command",
        """
        # Set variables
        \$targetFolder = "${command.workingDirectoryPath ?? env.workDirectoryPath}"
        \$command = "${command.program}"
        \$arguments = "${command.arguments.join(" ")}"
        
        # Relaunch as administrator
        Start-Process powershell -Verb runAs -wait -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy Bypass",
            "-Command `"Set-Location -Path '\$targetFolder'; & '\$command' \$arguments`""
        )
        
        New-Item -ItemType File -Path "$doneFilePath"
        """,
      ];
    } else {
      arguments = command.arguments;
    }

    final Map<String, String> processableEnvironment = {};
    env.vars.forEach((key, value) {
      if (value is String) {
        processableEnvironment[key] = value;
      } else if (value is num) {
        processableEnvironment[key] = value.toString();
      }
    });

    final result = await io.Process.start(
      program,
      arguments,
      workingDirectory: command.workingDirectoryPath ?? env.workDirectoryPath,
      environment: processableEnvironment,
      includeParentEnvironment: true,
      mode: io.ProcessStartMode.normal,
      runInShell: command.shell,
    );
    if (command.administrator)
      await waitWhile(() {
        if (io.File(doneFilePath).existsSync()) {
          io.File(doneFilePath).deleteSync();
          return true;
        }
        return false;
      }, Duration(seconds: 1));

    if (!this.spinner) {
      void Function(String) writeln = (data) {
        io.stdout.writeln(data.trim());
      };
      result.stdout.transform(convert.utf8.decoder).listen(writeln);
      result.stderr.transform(convert.utf8.decoder).listen(writeln);
    }

    final exitCode = await result.exitCode;
    return exitExecute(exitCode == 0);
  }
}

final class StepCommand {
  final String program;
  final List<String> arguments;

  /// Should the parent environment variables be added to the access of the command.
  final bool includeParentEnvironment = true;

  /// On windows the command will be executed as powershell administrator,
  /// on linux and macOS a sudo will be added.
  final bool administrator;

  final String? workingDirectoryPath;

  /// Should run the command in an external shell.
  final bool shell;

  const StepCommand({
    required this.program,
    required this.arguments,
    this.shell = false,
    this.workingDirectoryPath,
    this.administrator = false,
  });

  String get string {
    return "${program} ${arguments.join(" ")}";
  }
}

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
   * How much spaces should appear for the stdout of this environment.
   * Provides structure in deeper executions.
   */
  final int prefixSpace;

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
  String get workDirectoryPath =>
      path.join(outputDirectoryPath, this.target.string(), this.name);

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
    this.prefixSpace = 0,
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

  Future<bool> execute(
    final List<Step> steps, {
    final String suffix = "",
    final bool forced = false,
  }) async {
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
        String message =
            targetName + "⟮${i + 1}⁄${steps.length}⟯" + spaceCharacter;

        if (step.configure != null) {
          await step.configure!(this);
        }
        if (step.condition != null && !forced) {
          if (!await step.condition!(this)) {
            io.stdout.writeln(message + "Skipped");
            continue;
          }
        }
        result = await step.execute(this, message: message + step.name);
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

  bool ensurePrograms(List<String> requiredPrograms) {
    final String executableExtension = io.Platform.isWindows ? ".exe" : "";
    final List<String> pathVariableEntries =
        io.Platform.environment["PATH"]?.split(
          io.Platform.isWindows ? ";" : ":",
        ) ??
        [];

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
        io.stderr.writeln("$program" + " ✖  ");
        isAllFound = false;
      }
    }
    return isAllFound;
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

/**
 * Representing a specific operating system.
 */
enum Platform { windows, macos, linux }

/**
 * Representing a specific processor architecture.
 */
enum Processor { x86_64, arm64 }

/**
 * Operating system, processor couple to determine the full platform in context.
 */

final class System {
  final Platform platform;
  final Processor processor;
  System(this.platform, this.processor);
  static System? parseString(String string) {
    Platform? platform = null;
    Processor? processor = null;

    for (Platform systemValue in Platform.values) {
      if (systemValue.name == string.split("_").first) {
        platform = systemValue;
      }
    }
    for (Processor processorValue in Processor.values) {
      if (processorValue.name == string.split("_").sublist(1).join("_")) {
        processor = processorValue;
      }
    }
    if (platform == null || processor == null) return null;
    return System(platform, processor);
  }

  factory System.current() {
    final String system = io.Platform.version.split("\"")[1];
    return System(
      Platform.values.firstWhere((i) => i.name == system.split("_").first),
      {"x64": Processor.x86_64, "arm64": Processor.arm64}[system
          .split("_")
          .last]!,
    );
  }

  /**
   *  A formatted version of System for use of representation.
   */
  String string() {
    return "${platform.name}_${processor.name}";
  }
}

class ProcessSpinner {
  final Environment env;
  ProcessSpinner(this.env);

  static const List<String> _frames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];

  async.Timer? _timer;
  int _counter = 0;

  void start([String message = '']) {
    _counter = 0;
    _timer?.cancel();
    _timer = async.Timer.periodic(Duration(milliseconds: 80), (timer) {
      io.stdout.write('\r$message ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  void stop([String message = ""]) {
    _timer?.cancel();
    io.stdout.write('\r');
    io.stdout.write(message + "\n");
  }
}

Future waitWhile(bool test(), [Duration pollInterval = Duration.zero]) {
  var completer = async.Completer();
  check() {
    if (!test()) {
      completer.complete();
    } else {
      async.Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}
