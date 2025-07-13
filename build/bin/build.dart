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

import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import 'package:fireworks.cli/command/runner.dart';

Future<int> main(List<String> args) => execute(
  args,
  Command(
    use: "build",
    description:
    "\ndart run build.dart <target>",
    run: build,
  ),
  globalFlags: [
    Flag(
      name: "verbose",
      description: "Prints extra information about the process.",
    ),
    Flag(
      name: "target",
      description: "Target for cross compilation.",
      value: System.current().string(),
      overview: supportedCouples[System.current().string()] ?? [],
    ),
    Flag(name: "list", description: "List all build targets."),
  ],
);

/// All registered build targets
final Map<String, Future<int> Function()> targets = {
  "clang_artifacts": (() async => await main([])),
};

/// Host target couples supported by the build scripts for building fireworks.
final supportedCouples = {
  System(SystemPlatform.windows, SystemProcessor.x86_64).string(): [
    System(SystemPlatform.windows, SystemProcessor.x86_64).string(),
    System(SystemPlatform.windows, SystemProcessor.arm64).string(),
  ],
  System(SystemPlatform.windows, SystemProcessor.arm64).string(): [
    System(SystemPlatform.windows, SystemProcessor.arm64).string(),
  ],
  System(SystemPlatform.linux, SystemProcessor.x86_64).string(): [
    System(SystemPlatform.linux, SystemProcessor.x86_64).string(),
    System(SystemPlatform.linux, SystemProcessor.arm64).string(),
    System(SystemPlatform.linux, SystemProcessor.riscv64).string(),
  ],
  System(SystemPlatform.macos, SystemProcessor.arm64).string(): [
    System(SystemPlatform.macos, SystemProcessor.arm64).string(),
  ],
};

CommandRunner build = (data) async {
  for (Flag flag in data.flags) {
    if (flag.name == "list") {
      stdout.writeln("Available targets: \n" + targets.keys.join(",\n"));
      await stdout.flush();
      return CommandResponse();
    }
  }

  if (supportedCouples[System(
    SystemPlatform.windows,
    SystemProcessor.x86_64,
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

    System target = System.current();
    return CommandResponse(error: await targets[arg]!() != 0);
  }
  return CommandResponse(
  message:
  "Please specify a valid build target as argument or a sub command.",
  syntax: cmd,
  );
};
