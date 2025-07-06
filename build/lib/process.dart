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

/**
 * Representation of a command that can be executed as part of [StepProcess];
 */
final class Step {
  /// Switch between stdio and a spinner. Stderr will be not affected.
  final bool printStdio;

  /// Override the working directory of the overall [StepProcess];
  final String? overrideWorkingDirectory;

  /// Program that should be executed.
  final String program;

  /// Arguments that will be applied to the program and will result in the command.
  final List<String> arguments;

  /// If a error should be ignored for the rest of the steps list inside of a [StepProcess];
  final bool proceedOnFail;

  /// Custom environment variables that get applied to the commands execution.
  final Map<String, String>? environment;

  /// Should the parent environment variables be added to the access of the command.
  final bool includeParentEnvironment;

  /// If the process of the command should start as part of the Dart process or detached.
  final ProcessStartMode mode;

  /// Should the command be run inside the systems command shell.
  final bool shell;

  /// On windows the command will be executed as powershell administrator,
  /// on linux and macOS a sudo will be added.
  final bool administrator;

  final Future<bool> Function(String workingDirectory, Map<String, String> environment, String message)? run;
  const Step({
    this.overrideWorkingDirectory,
    required this.program,
    required this.arguments,
    this.proceedOnFail = true,
    this.environment,
    this.includeParentEnvironment = true,
    this.mode = ProcessStartMode.normal,
    this.shell = false,
    this.administrator = false,
    this.printStdio = true,
    this.run
  });

  Future<bool> execute({
    required String workingDirectory,
    Map<String, String> environment = const {},
    String message = "",
  }) async {
    if (overrideWorkingDirectory != null) {
      workingDirectory = overrideWorkingDirectory!;
    }

    if (this.environment != null) {
      environment.addAll(this.environment!);
    }

    if (run != null) {
      return run!(workingDirectory, environment, message);
    }

    final String program = administrator
        ? Platform.isWindows
              ? "powershell.exe"
              : "sudo ${this.program}"
        : this.program;

    final List<String> arguments;
    if (administrator && Platform.isWindows) {
      arguments = [
        "-Command",
        """
        Set-Location -Path $workingDirectory;
        Start-Process -FilePath ${this.program} ${this.arguments.join(" ")} -Verb RunAs 
        """,
      ];
    } else {
      arguments = this.arguments;
    }

    ProcessSpinner? spinner;
    if (!printStdio) {
      spinner = ProcessSpinner()..start();
    }

    final result = await Process.start(
      program,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
      runInShell: shell,
    );

    if (mode != ProcessStartMode.detached && printStdio) {
      void Function(String) writeln = (data) {
        stdout.writeln(data.trim().split('\n').last);
      };
      result.stdout.transform(utf8.decoder).listen(writeln);
      result.stderr.transform(utf8.decoder).listen(writeln);
    }
    if (spinner != null) {
      spinner.stop();
    }

    final exitCode = await result.exitCode;
    return exitCode == 0;
  }
}

final class StepProcess {
  final String workingDirectory;
  final Map<String, String> environment;
  final List<Step> steps;
  StepProcess({
    required this.workingDirectory,
    required this.steps,
    this.environment = const {},
  });
  Future<bool> execute() async {
    for (int i = 0; i < steps.length - 1; i++) {
      bool result = await steps[i].execute(
        workingDirectory: workingDirectory,
        environment: environment,
        message: "[${i + 1}/${steps.length}] ",
      );
      if (!result) {
        return false;
      }
    }
    return true;
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
      stdout.write('\r${_frames[_counter % _frames.length]} $message');
      _counter++;
    });
  }

  void stop() {
    _timer?.cancel();
    stdout.write('\r');
    stdout.write(' ' * 80);
    stdout.write('\r');
  }
}
