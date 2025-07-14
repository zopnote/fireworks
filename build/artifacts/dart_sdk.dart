import 'dart:io';

import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import 'package:path/path.dart' as path;

List<BuildStep> processSteps = [
  BuildStep(
    "Ensures programs in environment",
    condition: (env) => BuildConfig.ensurePrograms(["python", "git"]),
  ),
  BuildStep(
    "Set system variable",
    condition: (env) => env.host.platform == SystemPlatform.windows,
    run: (env) {
      env.variables["DEPOT_TOOLS_WIN_TOOLCHAIN"] = 0;
      return true;
    },
  ),
  BuildStep(
    "Clone depot tools",
    condition: (env) {
      env.variables["repository_url"] =
          "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
      env.variables["repository_path"] = path.join(
        env.workDirectoryPath,
        path.basenameWithoutExtension(env.variables["repository_url"]),
      );
      return !Directory(env.variables["repository_path"]).existsSync();
    },
    command: (env) {
      return BuildStepCommand(
        program: "git",
        arguments: ["clone", env.variables["repository_url"]],
      );
    },
    exitFail: false,
  ),
  BuildStep(
    "Fetch the dart sdk",
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".dart-process-done"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: path.join(env.variables["repository_path"], "fetch"),
      arguments: ["dart"],
      administrator: env.host.platform == SystemPlatform.windows,
    ),
    spinner: true,
  ),
  BuildStep(
    "Synchronize gclient",
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".gclient_previous_sync_commits"),
    ).existsSync(),
    command: (env) => BuildStepCommand(
      program: path.join(
        env.variables["repository_path"],
        "gclient" + (env.host.platform == SystemPlatform.windows ? ".bat" : ""),
      ),
      arguments: ["sync"],
      workingDirectoryPath: path.join(env.workDirectoryPath, "sdk"),
    ),
  ),
  BuildStep(
    "Build the sdk for the target operating system",
    command: (env) => BuildStepCommand(
        program: "python",
        arguments: [
          "${path.join(env.workDirectoryPath, "sdk")}/tools/build.py",
          "--mode", "release",
          "--arch", {
          SystemProcessor.x86_64: "x64",
            SystemProcessor.arm64: "arm64",
            SystemProcessor.arm: "arm",
            SystemProcessor.riscv64: "riscv64",
            SystemProcessor.x86: "ia32"
          }[env.target.processor]!,
          "create_sdk"
        ],
      workingDirectoryPath: path.join(env.workDirectoryPath, "sdk"),
    )
  ),
];
