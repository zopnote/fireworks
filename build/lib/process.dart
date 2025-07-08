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
import 'environment.dart';

final class CommandProperties {
  final String program;
  final List<String> arguments;

  /// Should the parent environment variables be added to the access of the command.
  final bool includeParentEnvironment = true;

  /// Should the command be run inside the systems command shell.
  final bool shell;

  /// On windows the command will be executed as powershell administrator,
  /// on linux and macOS a sudo will be added.
  final bool administrator;

  const CommandProperties({
    required this.program,
    required this.arguments,
    this.shell = false,
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
  final Future<bool> Function(BuildEnvironment environment)? run;

  final CommandProperties Function(BuildEnvironment environment)? command;

  /// If a false value received by run() or the command should terminate the [BuildProcess]
  final bool exitFail;

  final bool Function(BuildEnvironment environment)? condition;

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
    this.spinner = false,
  });

  Future<bool> execute({
    required final BuildEnvironment environment,
    String message = "",
  }) async {
    final workDirectoryPath = environment.workDirectory.path;

    if (message[message.length - 1] != " " && message.isNotEmpty) {
      message += " ";
    }
    ProcessSpinner? spinner;
    bool exitExecute(bool returnable) {
      if (spinner != null) {
        spinner.stop(message + name);
        return returnable;
      }
      return true;
    }

    if (this.spinner) {
      spinner = ProcessSpinner()..start(message + name);
    } else {
      stdout.writeln(message + name);
    }
    if (condition != null) {
      if (!condition!(environment)) {
        return exitExecute(true);
      }
    }
    if (run != null) {
      return exitExecute(await run!(environment));
    }

    if (this.command == null) {
      throw Exception(
        "You have to decide between a function call that should "
        "be run as the steps purpose or the combination of an argument array "
        "and the program the arguments will be applied to."
        "But you didn't specified a function or the program, argument couple.",
      );
    }

    final CommandProperties command = this.command!(environment);
    final String program = command.administrator
        ? Platform.isWindows
              ? "powershell.exe"
              : "sudo ${command.program}"
        : command.program;

    final List<String> arguments;
    if (command.administrator && Platform.isWindows) {
      arguments = [
        "-Command",
        """
        Set-Location -Path $workDirectoryPath;
        Start-Process -FilePath ${command.string} -Verb RunAs
        """,
      ];
    } else {
      arguments = command.arguments;
    }

    final Map<String, String> processableEnvironment = {};
    environment.vars.forEach((key, value) {
      if (value is String) {
        processableEnvironment[key] = value;
      } else if (value is num) {
        processableEnvironment[key] = value.toString();
      }
    });

    final result = await Process.start(
      program,
      arguments,
      workingDirectory: workDirectoryPath,
      environment: processableEnvironment,
      includeParentEnvironment: true,
      mode: ProcessStartMode.normal,
      runInShell: command.shell,
    );

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
    stdout.write(message);
    stdout.write('\r');
  }
}
