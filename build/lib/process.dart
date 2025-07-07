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

final class CommandProperties {
  final String program;
  final List<String> arguments;

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

  /// If the process should get a spinner.
  /// Notice that any input to stdout or stderr will move the spinner to the last line.
  /// Therefore stop the spinner before any result information have to printed
  /// or another step will be executed.
  final bool spinner;

  const CommandProperties({
    required this.program,
    required this.arguments,
    this.environment,
    this.includeParentEnvironment = true,
    this.mode = ProcessStartMode.normal,
    this.shell = false,
    this.administrator = false,
    this.spinner = false,
  });

  String get string {
    return "${program} ${arguments.join(" ")}";
  }
}

/**
 * Representation of a command that can be executed as part of [StepProcess];
 */
final class Step {
  final String name;

  /// Function that will run.
  final Future<bool> Function(String workingDirectory)? run;

  final CommandProperties? command;

  /// If a false value received by run() or the command should terminate the [StepProcess]
  final bool exitFail;

  final bool Function()? condition;

  const Step(this.name, {this.command, this.run, this.exitFail = true, this.condition});

  Future<bool> execute({
    required String workingDirectory,
    Map<String, String> environment = const {},
    String message = "",
  }) async {
    if (condition != null) {
      if (!condition!()) {
        return true;
      }
    }
    if (message[message.length - 1] != " " && message.isNotEmpty) {
      message += " ";
    }
    ProcessSpinner? spinner;
    if (run != null) {
      spinner = ProcessSpinner()..start(message + name);
      return run!(workingDirectory);
    }

    if (this.command == null) {
      throw Exception(
        "You have to decide between a function call that should "
        "be run as the steps purpose or the combination of an argument array "
        "and the program the arguments will be applied to."
        "But you didn't specified a function or the program, argument couple.",
      );
    }

    if (this.command!.spinner) {
      spinner = ProcessSpinner()..start(message + this.command!.string);
    }
    if (this.command!.environment != null) {
      environment.addAll(this.command!.environment!);
    }

    final String program = this.command!.administrator
        ? Platform.isWindows
              ? "powershell.exe"
              : "sudo ${this.command!.program}"
        : this.command!.program;

    final List<String> arguments;
    if (this.command!.administrator && Platform.isWindows) {
      arguments = [
        "-Command",
        """
        Set-Location -Path $workingDirectory;
        Start-Process -FilePath ${this.command!.string} -Verb RunAs 
        """,
      ];
    } else {
      arguments = this.command!.arguments;
    }

    final result = await Process.start(
      program,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: this.command!.includeParentEnvironment,
      mode: this.command!.mode,
      runInShell: this.command!.shell,
    );

    if (this.command!.mode != ProcessStartMode.detached &&
        !this.command!.spinner) {
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
  const StepProcess({
    required this.workingDirectory,
    required this.steps,
    this.environment = const {},
  });
  Future<bool> execute() async {
    bool result;
    for (int i = 0; i < steps.length - 1; i++) {
      result = await steps[i].execute(
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
      stdout.write('\r$message ${_frames[_counter % _frames.length]}');
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
