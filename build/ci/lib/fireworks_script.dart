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
import 'dart:io';
import 'package:path/path.dart' as path;

bool isFlag(String flag) {
  for (String argFlag in Platform.executableArguments.where((arg) => arg.startsWith("--"))) {
    if (flag == argFlag) return true;
  }
  return false;
}


bool ensureRequiredPrograms(List<String> envPrograms) {
  if (envPrograms.isNotEmpty) {
    final String varSeperator = Platform.isWindows ? ";" : ":";
    final String exeExtension = Platform.isWindows ? ".exe" : ":";
    final List<String> envPaths = Platform.environment["PATH"]?.split(varSeperator) ?? [];
    stdout.writeln("Check for programs in path environment variable...");
    bool allAvailable = true;
    for (String program in envPrograms) {
      bool found = false;
      for (String envPath in envPaths) {
        if (File("$envPath${path.separator}$program$exeExtension").existsSync())
          found = true;
      }

      final int space = 20 - program.length;

      if (found) stdout.writeln("$program" + (" " * space) + "FOUND");
      else {
        stderr.writeln("$program" + (" " * space) + "NOT FOUND");
        allAvailable = false;
      }
    }
    return allAvailable;
  }
  return true;
}


class Spinner {
  final List<String> _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
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

Future<bool> executeProcess(String workDir, String command, List<String> args, {String? description}) async {
  String message = " $command";
  const int max = 3;
  int yet = 0;
  args.forEach((a) {
    if (yet <= max) {
      message = message + " $a";
      yet++;
    }
  });

  final spinner = Spinner();
  if (description != null) message = description;
  spinner.start(message);

  try {
    final process = await Process.start(
      command,
      args,
      workingDirectory: workDir,
    );

    var lastLine = StringBuffer();

    process.stdout.transform(utf8.decoder).listen((data) {
      spinner.stop();
      stdout.write(data);
      if (data.trim().isNotEmpty) {
        lastLine.clear();
        lastLine.write(data.trim().split('\n').last);
      }
      spinner.start('$message (${lastLine.toString()})');
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      spinner.stop();
      stderr.write(data);
      if (data.trim().isNotEmpty) {
        lastLine.clear();
        lastLine.write(data.trim().split('\n').last);
      }
      spinner.start('$message (${lastLine.toString()})');
    });

    final exitCode = await process.exitCode;
    spinner.stop();
    return exitCode == 0;

  } catch (e) {
    spinner.stop();
    stderr.writeln('\nFehler: $e');
    return false;
  }
}
