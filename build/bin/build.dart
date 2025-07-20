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

import 'package:fireworks.cli/build/environment.dart';
import 'package:fireworks.cli/command/runner.dart';

import 'package:fireworks.build/targets.dart';
import '../../app/modspec.dart';

Future<int> main(List<String> args) => execute(
  args,
  Command(
    use: "build",
    description: "\nPlease specify a target to build.",
    run: build,
  ),
  globalFlags: [
    Flag(
      name: "verbose",
      description: "Prints extra information about the process.",
    ),
    Flag(
      name: "platform",
      description: "Platform target for cross compilation.",
      value: System.current().string(),
      overview: supportedCouples[System.current().string()] ?? [],
    ),
    Flag(
      name: "config",
      description: "Build type configuration.",
      value: BuildType.debug.name,
      overview: BuildType.values.map((e) => e.name).toList(),
    ),
    Flag(name: "list", description: "List all build targets."),
  ],
);

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
  ],
  System(SystemPlatform.macos, SystemProcessor.arm64).string(): [
    System(SystemPlatform.macos, SystemProcessor.arm64).string(),
  ],
};

CommandRunner build = (data) async {
  final String? platformValue = data.flags
      .firstWhereOrNull((e) => e.name == "platform")
      ?.value;
  final String? configValue = data.flags
      .firstWhereOrNull((e) => e.name == "config")
      ?.value;
  if (configValue == null || platformValue == null) {
    return CommandResponse(
      message:
          (configValue == null ? "The config flag is not set.\n" : "") +
          (platformValue == null ? "The target flag is not set." : ""),
      error: true,
    );
  }

  System? target = System.parseString(platformValue);
  BuildType? buildType = BuildType.values.firstWhereOrNull(
    (e) => e.name == configValue,
  );
  if (target == null || buildType == null) {
    return CommandResponse(
      message:
          (target == null
              ? "The target flag value '$platformValue' is invalid.\n"
              : "") +
          (buildType == null
              ? "The build configuration flag value '$configValue' is invalid."
              : ""),
      error: true,
    );
  }

  if (!supportedCouples.keys.contains(System.current().string())) {
    return CommandResponse(
      message: "The current host isn't supported to build for any platform.",
      error: true,
    );
  }

  if (!supportedCouples[System.current().string()]!.contains(target.string())) {
    return CommandResponse(
      message:
          "You can't build for $platformValue on a ${System.current().string()} host platform.",
      error: true,
    );
  }

  final bool verbose =
      data.flags.firstWhereOrNull((e) => e.name == "verbose") == null
      ? false
      : true;

  final bool list = data.flags.firstWhereOrNull((e) => e.name == "list") == null
      ? false
      : true;

  void Function() listTargets = () =>
      stdout.writeln("\nAvailable targets:\n" + targets.keys.join("\n"));

  if (list) {
    listTargets();
    return CommandResponse();
  }

  if (data.arg.isEmpty) {
    return CommandResponse(syntax: data.cmd);
  }

  if (!targets.keys.contains(data.arg)) {
    listTargets();
    return CommandResponse(
      message: targets.keys.contains(data.arg)
          ? ""
          : "'${data.arg}' is not a valid build target.",
      error: true,
    );
  }
  if (verbose) {
    stdout.writeln("Execute build configuration and target build steps...");
  }
  test();
  return CommandResponse(
    error: !await BuildConfig(
      data.arg,
      target: target,
      buildType: buildType,
      variables: {"build_version": 1.0},
    ).execute(targets[data.arg]!),
  );
};
