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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'config.dart';

final class BuildStepCommand {
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

  const BuildStepCommand({
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
 * Representation of a command that can be executed as part of [BuildProcess];
 */
class BuildStep {
  final String name;

  /// Function that will run.
  final FutureOr<bool> Function(BuildConfig environment)? run;

  final BuildStepCommand Function(BuildConfig environment)? command;

  /// If a false value received by run() or the command should terminate the [BuildProcess]
  final bool exitFail;

  final FutureOr<bool> Function(BuildConfig environment)? condition;
  final FutureOr<void> Function(BuildConfig environment)? configure;

  /// If the process should get a spinner.
  /// Notice that any input to stdout or stderr will move the spinner to the last line.
  /// Therefore stop the spinner before any result information have to printed
  /// or another step will be executed.
  final bool spinner;

  const BuildStep(
    this.name, {
    this.command,
    this.run,
    this.exitFail = true,
    this.condition,
    this.configure,
    this.spinner = false,
  });

  Future<bool> execute({
    required final BuildConfig env,
    String message = "",
  }) async {
    ProcessSpinner? spinner;
    bool exitExecute(bool returnable) {
      if (spinner != null) {
        spinner.stop(message);
        return returnable;
      }
      return returnable;
    }


    if (this.spinner) {
      spinner = ProcessSpinner()..start(message);
    } else {
      stdout.writeln(message);
    }
    if (run != null) {
      return exitExecute(await run!(env));
    }

    if (this.command == null) {
      return exitExecute(true);
    }

    final BuildStepCommand command = this.command!(env);
    final String program = command.administrator
        ? Platform.isWindows
              ? "powershell.exe"
              : "sudo ${command.program}"
        : command.program;

    final List<String> arguments;
    final String doneFilePath = path.join(
      command.workingDirectoryPath ?? env.workDirectoryPath,
      ".dart-process-done",
    );
    if (command.administrator && Platform.isWindows) {
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
    env.variables.forEach((key, value) {
      if (value is String) {
        processableEnvironment[key] = value;
      } else if (value is num) {
        processableEnvironment[key] = value.toString();
      }
    });

    final result = await Process.start(
      program,
      arguments,
      workingDirectory: command.workingDirectoryPath ?? env.workDirectoryPath,
      environment: processableEnvironment,
      includeParentEnvironment: true,
      mode: ProcessStartMode.normal,
      runInShell: command.shell,
    );
    if (command.administrator)
      await waitWhile(() {
        return File(doneFilePath).existsSync();
      }, Duration(seconds: 1));

    if (!this.spinner) {
      void Function(String) writeln = (data) {
        stdout.writeln(data.trim());
      };
      result.stdout.transform(utf8.decoder).listen(writeln);
      result.stderr.transform(utf8.decoder).listen(writeln);
    }

    final exitCode = await result.exitCode;
    return exitExecute(exitCode == 0);
  }
}

class ProcessSpinner {
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

  Timer? _timer;
  int _counter = 0;

  void start([String message = '']) {
    _counter = 0;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 80), (timer) {
      stdout.write('\r$message ${_frames[_counter % _frames.length]}');
      _counter++;
    });
  }

  void stop([String message = ""]) {
    _timer?.cancel();
    stdout.write('\r');
    stdout.write(message + "\n");
  }
}

Future waitWhile(bool test(), [Duration pollInterval = Duration.zero]) {
  var completer = new Completer();
  check() {
    if (!test()) {
      completer.complete();
    } else {
      new Timer(pollInterval, check);
    }
  }

  check();
  return completer.future;
}
