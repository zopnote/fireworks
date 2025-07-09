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

import 'package:fireworks_scripts/environment.dart';
import 'package:fireworks_scripts/process.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async =>
    await BuildConfig(
          variables: {"environment_name": "dart_sdk_ci_build", "version": 1.0},
        )
        .override((config) {
          const String repository =
              "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
          final String repositoryName = path.basenameWithoutExtension(
            repository,
          );
          final String repositoryPath = path.join(
            config.workDirectory.path,
            repositoryName,
          );

          const String windowsAttentionMessage = """\n
  Please ensure you have the Windows 10 SDK installed.
  This can be installed separately or by checking the appropriate box in the Visual Studio Installer.
  The SDK Debugging Tools must also be installed.
  More information on https://github.com/dart-lang/sdk/blob/main/docs/Building.md
  """;
          return BuildConfig(
            outputDirectory: Directory(
              path.join(
                config.outputDirectory.path,
                config.target.string(),
                "bin",
                "dart",
              ),
            ),
            variables: {
              "windows_attention_message": windowsAttentionMessage,
              "required_programs": ["git", "python", "cmake"],
            },
          );
        })
        .execute([
          BuildStep(
            "Note for windows",
            condition: (env) => env.,
            run: (env) async {
              stdout.writeln(windowsAttentionMessage);
              return true;
            },
          ),
          BuildStep(
            "Check for available Programs",
            condition: () => !environment.ensurePrograms(requiredPrograms),
            run: (_) async {
              stderr.writeln(
                "\nPlease ensure the availability of all dependencies to proceed.",
              );
              return false;
            },
          ),
          BuildStep(
            "Create directory",
            condition: () => !workDirectory.existsSync(),
            run: (_) async {
              await workDirectory.create(recursive: true);
              return workDirectory.exists();
            },
          ),
          BuildStep(
            "Clone repository",
            command: CommandProperties(
              program: "git",
              arguments: ["clone", repository],
            ),
          ),
          BuildStep(
            "MacOS error precare",
            condition: () => Platform.isMacOS,
            command: CommandProperties(
              program: "xcode",
              arguments: [
                "-select",
                "-s",
                "/Applications/Xcode.app/Contents/Developer",
              ],
              administrator: true,
            ),
          ),
        ]);
