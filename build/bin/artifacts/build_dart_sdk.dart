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

import 'dart:io';

import 'package:fireworks_scripts/environment.dart' as environment;
import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;

const String repository =
    "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
const List<String> requiredPrograms = const ["cmake", "git", "python"];

final String repositoryName = path.basenameWithoutExtension(repository);

final Directory repositoryDirectory = Directory(
    path.join(
        environment.workDirectory,
        repositoryName
    ));

final Directory outputDirectory = Directory(path.join(
  environment.outputDirectory,
  "bin",
  "dart-${environment.system}",
));

final Directory workDirectory = Directory(environment.workDirectory);

final Directory fetchableDartDirectory = Directory(path.join(workDirectory.path, "dart"));
final Directory dartRepositoryDirectory = Directory(path.join(fetchableDartDirectory.path, "sdk"));

const String windowsAttentionMessage = """\n
Please ensure you have the Windows 10 SDK installed.
This can be installed separately or by checking the appropriate box in the Visual Studio Installer.
The SDK Debugging Tools must also be installed.
More information on https://github.com/dart-lang/sdk/blob/main/docs/Building.md
""";

final StepProcess process = StepProcess(
    workingDirectory: workDirectory.path,
    steps: [
      Step("Note for windows",
        condition: () => Platform.isWindows,
        run: (_) async {
          stdout.writeln(windowsAttentionMessage);
          return true;
        }
      ),
      Step("Check for available Programs",
        condition: () => !environment.ensurePrograms(requiredPrograms),
        run: (_) async {
          stderr.writeln(
            "\nPlease ensure the availability of all dependencies to proceed.",
          );
          return false;
        }
      ),
      Step("Create directory",
        condition: () => !workDirectory.existsSync(),
        run: (_) async {
          await workDirectory.create(recursive: true);
          return workDirectory.exists();
        }
      ),
      Step("Clone repository",
        command: CommandProperties(
            program: "git",
            arguments: [
              "clone",
              repository
            ]
        ),
      ),
      Step("MacOS error precare",
        condition: () => Platform.isMacOS,
        command: CommandProperties(
            program: "xcode",
            arguments: [
              "-select",
              "-s",
              "/Applications/Xcode.app/Contents/Developer"
            ],
          administrator: true
        ),
      ),

    ]
);

Future<int> main() async {


  if (!Directory(dartDirectoryPath).existsSync()) {
    await Directory(dartDirectoryPath).create(recursive: true);
  }

  if (!await Directory(path.join(dartDirectoryPath, "sdk")).existsSync()) {
    await executeProcess(
      dartDirectoryPath,
      path.join(repositoryDirectoryPath, "fetch.bat"),
      ["dart"],
      exitOnFail: true,
      winAsAdministrator: true
    );
  }

  return 0;
}
