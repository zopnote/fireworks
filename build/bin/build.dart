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

import 'package:fireworks.build/artifacts/clang.dart' as clang;
import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import 'package:fireworks.cli/command/runner.dart';
import 'package:path/path.dart' as path;

const double version = 1.0;

/// Host target couples supported by the build scripts for building fireworks.
final supportedCouples = {
  System(
    platform: SystemPlatform.windows,
    processor: SystemProcessor.x86_64,
  ).string(): [
    System(
      platform: SystemPlatform.windows,
      processor: SystemProcessor.x86_64,
    ).string(),
    System(
      platform: SystemPlatform.windows,
      processor: SystemProcessor.arm64,
    ).string(),
  ],

  System(
    platform: SystemPlatform.windows,
    processor: SystemProcessor.arm64,
  ).string(): [
    System(
      platform: SystemPlatform.windows,
      processor: SystemProcessor.arm64,
    ).string(),
  ],
  System(
    platform: SystemPlatform.linux,
    processor: SystemProcessor.x86_64,
  ).string(): [
    System(
      platform: SystemPlatform.linux,
      processor: SystemProcessor.x86_64,
    ).string(),
    System(
      platform: SystemPlatform.linux,
      processor: SystemProcessor.arm64,
    ).string(),
    System(
      platform: SystemPlatform.linux,
      processor: SystemProcessor.riscv64,
    ).string(),
  ],

  System(
    platform: SystemPlatform.macos,
    processor: SystemProcessor.arm64,
  ).string(): [
    System(
      platform: SystemPlatform.macos,
      processor: SystemProcessor.arm64,
    ).string(),
  ],
};

/// All registered build targets
final Map<String, (BuildConfigCallback, List<BuildStep>)> targets = {
  "clang_artifacts": (clang.processConfig, clang.processSteps),
};

final extendedConfig = (BuildType buildType, System target) =>
    BuildConfig.overrideDefault((config) {
      return config.reconfigure();
    });

final Command command = Command(
  "build",
  description:
      "\n"
      "dart run build.dart <target>",
  run: (cmd, arg, flags) async {
    for (Flag flag in flags) {
      if (flag.name == "list") {
        stdout.writeln("Available targets: \n" + targets.keys.join(",\n"));
        await stdout.flush();
        return CommandResponse();
      }
    }

    if (supportedCouples[System(
          platform: SystemPlatform.windows,
          processor: SystemProcessor.x86_64,
        ).string()] ==
        null) {
      stderr.writeln(
        "Your host system is not supported. List of supported host systems: ${supportedCouples.keys.join(", ")}",
      );
    }

    if (targets.containsKey(arg)) {
      Flag? targetFlag = null;
      Flag? verboseFlag = null;
      flags.forEach((flag) {
        if (flag.name == "target") targetFlag = flag;
        if (flag.name == "verbose") verboseFlag = flag;
      });

      System target;
      return CommandResponse(
        isError: !await extendedConfig(
          BuildType.releaseDebug,
          System.current(),
        ).override(targets[arg]!.$1).execute(targets[arg]!.$2),
      );
    }
    return CommandResponse(
      message:
          "Please specify a valid build target as argument or a sub command.",
      printSyntax: cmd,
    );
  },
);

Future<int> main(List<String> args) async =>
    await run(
      rawArgs: args,
      command: command,
      globalFlags: [
        Flag(
          "verbose",
          description: "Prints extra information about the process.",
        ),
        Flag(
          "target",
          description: "Target for cross compilation.",
          value: System.current().string(),
          overview: supportedCouples[System.current().string()] ?? [],
        ),
        Flag("list", description: "List all build targets."),
      ],
    )
    ? 0
    : 1;
