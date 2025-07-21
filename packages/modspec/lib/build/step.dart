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

import 'process_spinner.dart';
import 'environment.dart';

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
 * Representation of a command that can be executed as part of [BuildProcess];
 */
class Step {
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

  Future<bool> execute(final Environment env, {
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
      ".dart-process-done",
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
        return io.File(doneFilePath).existsSync();
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