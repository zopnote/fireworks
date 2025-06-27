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

import 'package:fireworks/command/execute/doctor.dart';
import 'package:fireworks/command/runner.dart';

void main(List<String> args) => run(
  rawArgs: args,
  command: Command(
    "fireworks",
    description: "Fireworks commandline tooling for manage projects.",
    run:
        (cur, arg, flags) {
          if (arg.isNotEmpty) return CommandResponse("\"$arg\" is no valid sub command.", printSyntax: cur, isError: true);
         return CommandResponse("No arguments specified.", printSyntax: cur);
        },
    subCommands: [
      Command(
        "doctor",
        description: "Checks the environment for usability.",
        run: doctor,
      ),
      Command(
        "create",
        description: "Creates a new project",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
      Command(
        "run",
        description: "Runs the project in debug configuration.",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
      Command(
        "reload",
        description: "Hot reload the changes of the project.",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
      Command(
        "build",
        description: "Build the project for shipping on multiple platforms.",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
      Command(
        "get",
        description:
            "Load the cache and information necessary for tooling and dependencies.",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
      Command(
        "version",
        description: "Shows the version of the tooling.",
        run: (_, _, _) => CommandResponse("Unimplemented.", isError: true),
      ),
    ],
  ),
  globalFlags: const [
    Flag("help", description: "Shows helpful description."),
    Flag(
      "verbose",
      description: "Enables additional information about processes.",
    )
  ],
);
