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

import 'package:fireworks.cli/command/runner.dart';
import 'package:fireworks_app/command/doctor.dart';
import 'dart:core';

Future<int> main(List<String> args) => execute(
  args,
  Command(
    use: "fireworks",
    description: "Fireworks commandline tooling for manage projects.",
    run: (data) {
      if (data.arg.isNotEmpty)
        return CommandResponse(
          message: "\"${data.arg}\" is no valid sub command.",
          syntax: data.cmd,
          error: true,
        );
      return CommandResponse(
        message: "No arguments specified.",
        syntax: data.cmd,
      );
    },
    subCommands: [
      Command(
        use: "doctor",
        description: "Checks the environment for usability.",
        run: doctor,
      ),
      Command(
        use: "create",
        description: "Creates a new project",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
      Command(
        use: "run",
        description: "Runs the project in debug configuration.",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
      Command(
        use: "reload",
        description: "Hot reload the changes of the project.",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
      Command(
        use: "build",
        description: "Build the project for shipping on multiple platforms.",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
      Command(
        use: "get",
        description:
            "Load the cache and information necessary for tooling and dependencies.",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
      Command(
        use: "version",
        description: "Shows the version of the tooling.",
        run: (_) => CommandResponse(message: "Unimplemented.", error: true),
      ),
    ],
  ),
  globalFlags: const [
    Flag(name: "help", description: "Shows helpful description."),
    Flag(
      name: "verbose",
      description: "Enables additional information about processes.",
    ),
  ],
);
