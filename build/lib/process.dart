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

Future<bool> executeProcess(
  String workingDirectory,
  String program,
  List<String> arguments, {
  bool exitOnFail = false,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
  bool winAsAdministrator = false,
}) async {
  String command = program;
  arguments.forEach((arg) {
    command = command + " $arg";
  });

  stdout.writeln("\n[$workingDirectory] $command");

  try {
    if (winAsAdministrator && Platform.isWindows) {
      program = "powershell.exe";
      arguments = [
        "-Command",
        """
        Set-Location -Path $workingDirectory;
        Start-Process -FilePath $command -Verb RunAs 
        """,
      ];
    }

    final process = await Process.start(
      program,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      mode: mode,
      runInShell: runInShell,
    );

    if (mode == ProcessStartMode.normal) {
      void Function(String) writeln = (data) {
        stdout.writeln(data.trim().split('\n').last);
      };
      process.stdout.transform(utf8.decoder).listen(writeln);
      process.stderr.transform(utf8.decoder).listen(writeln);
    }

    final exitCode = await process.exitCode;
    return exitCode == 0;
  } catch (e) {
    stderr.writeln('\nAn error occurred: $e');
    if (mode != ProcessStartMode.normal) if (exitOnFail) exit(1);
    return false;
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
