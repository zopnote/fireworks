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
 *
 */

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../build.dart';

List<Step> processSteps = [
  Step(
    "Ensures programs in environment",
    run: (env) => env.ensurePrograms(["python", "git"]),
  ),
  /**
   * The chromium toolchain has to be cloned first.
   */
  Step(
    "Clone depot tools repository",
    configure: (env) {
      env.vars["depot_tools_url"] =
          "https://chromium.googlesource.com/chromium/tools/depot_tools.git";
      env.vars["depot_tools_path"] = path.join(
        env.workDirectoryPath,
        path.basenameWithoutExtension(env.vars["depot_tools_url"]),
      );
    },
    condition: (env) => !Directory(env.vars["depot_tools_path"]).existsSync(),
    command: (env) => StepCommand(
      program: "git",
      arguments: ["clone", env.vars["depot_tools_url"]],
    ),
    exitFail: false,
  ),
  Step(
    "Set repository url",
    run: (env) {
      final dartConfig = File(path.join(env.vars["depot_tools_path"], "fetch_configs", "dart.py"));
      final String dartConfigContent = dartConfig.readAsStringSync();
      dartConfig.deleteSync();
      dartConfig.createSync();
      dartConfig.writeAsStringSync(dartConfigContent.replaceAll("https://dart.googlesource.com/sdk.git", "https://github.com/zopnote/dart-sdk.git"));
      return true;
    },
  ),
  /**
   * The Dart SDK depend on the chromium toolchain and has to be fetched
   * with the depot_tools fetch tool. We set DEPOT_TOOLS_WIN_TOOLCHAIN,
   * because if we doesn't a google toolchain is downloaded to compile
   * C++ instead of the local installation of gcc or msvc.
   */
  Step(
    "Fetch the dart sdk",
    configure: (env) {
      if (env.host.platform == Platform.windows) {
        env.vars["DEPOT_TOOLS_WIN_TOOLCHAIN"] = 0;
      }
    },
    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".${env.name}-process-done"),
    ).existsSync(),
    command: (env) => StepCommand(
      program: path.join(env.vars["depot_tools_path"], "fetch"),
      arguments: ["dart"],
      administrator: env.host.platform == Platform.windows,
    ),
    spinner: true,
  ),

  /**
   * In debug mode we save all available versions of the repository.
   * For version upgrades and information.
   */
  Step(
    "Save available dart git tags",
    configure: (env) {
      env.vars["dart_tags_path"] = path.join(
        env.workDirectoryPath,
        ".dart-available-versions",
      );
      env.vars["dart_sdk_path"] = path.join(env.workDirectoryPath, "sdk");
    },
    condition: (env) =>
        (env.config != Config.release) &&
        !File(env.vars["dart_tags_path"]).existsSync(),
    command: (env) => StepCommand(
      program: "git",
      arguments: [
        "tag",
        ">>",
        path.join("..", path.basename(env.vars["dart_tags_path"])),
      ],
      workingDirectoryPath: env.vars["dart_sdk_path"],
      shell: true,
    ),
  ),

  /**
   * gclient is a tool of google and is used in this context to download
   * all dependencies of the Dart SDK.
   */
  Step(
    "Synchronize gclient dependencies",

    configure: (env) {
      env.vars["gclient_script_file"] = path.join(
        env.vars["depot_tools_path"],
        "gclient" + (env.host.platform == Platform.windows ? ".bat" : ""),
      );
    },

    condition: (env) => !File(
      path.join(env.workDirectoryPath, ".gclient_previous_sync_commits"),
    ).existsSync(),

    command: (env) => StepCommand(
      program: env.vars["gclient_script_file"],
      arguments: ["sync"],
      workingDirectoryPath: env.vars["dart_sdk_path"],
    ),
  ),
  Step(
    "Build the sdk for the target operating system",
    configure: (env) {
      env.vars["dart_architecture"] = {
        Processor.x86_64: "x64",
        Processor.arm64: "arm64",
      }[env.target.processor]!;
      env.vars["dart_binaries_path"] = path.join(
        env.vars["dart_sdk_path"],
        "out",
        "Product" + (env.vars["dart_architecture"] as String).toUpperCase(),
      );
      env.vars["dart_dependency_python"] = env.host.platform == Platform.windows
          ? path.join(env.vars["depot_tools_path"], "python3.bat")
          : "python";
    },
    condition: (env) => !Directory(env.vars["dart_binaries_path"]).existsSync(),
    command: (env) => StepCommand(
      program: env.vars["dart_dependency_python"],
      arguments: [
        "${env.vars["dart_sdk_path"]}/tools/build.py",
        "--mode",
        "product",
        "--arch",
        env.vars["dart_architecture"],
        "create_sdk",
      ],
      workingDirectoryPath: env.vars["dart_sdk_path"],
    ),
  ),
  /**
   * The simarm64 cross compilation tool is capable of compiling Dart code to
   * arm64 systems. The downside is, it is inefficient and should only be used in debug.
   * For production the android_arm64 & ios_arm64 tools are built.
   */
  Step(
    "Build simarm64 cross compilation gen snapshot tool",
    configure: (env) {
      env.vars["product_simarm64_utils_path"] = path.join(
        env.vars["dart_sdk_path"],
        "out",
        "ProductSIMARM64",
        "dart-sdk",
        "bin",
        "utils",
      );
    },
    condition: (env) =>
        !Directory(env.vars["product_simarm64_utils_path"]).existsSync(),
    command: (env) => StepCommand(
      program: env.vars["dart_dependency_python"],
      arguments: [
        path.join(".", "tools", "build.py"),
        "--arch",
        "simarm64",
        "--mode",
        "product",
        "copy_gen_snapshot",
      ],
      workingDirectoryPath: env.vars["dart_sdk_path"],
    ),
  ),
  /**
   * Installation of only the important binaries and linux cross compilation tooling.
   * If a binary isn't found it just ignore it.
   */
  Step(
    "Install platform sdk",
    condition: (env) => !Directory(
      path.join(env.installDirectoryPath, "bin", "utils"),
    ).existsSync(),
    run: (env) =>
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["bin"],
          fileNames: ["dart", "dartaotruntime"],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["lib", "_internal"],
          directoryNames: ["vm", "vm_shared", "sdk_library_metadata"],
          fileNames: [
            "ddc_outline",
            "ddc_platform",
            "fix_data",
            "vm_platform",
            "vm_platform_product",
            "vm_platform_strong",
            "allowed_experiments",
          ],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["lib"],
          directoryNames: [
            "_http",
            "async",
            "collection",
            "concurrent",
            "convert",
            "core",
            "developer",
            "ffi",
            "internal",
            "io",
            "isolate",
            "math",
            "typed_data",
          ],
          fileNames: ["api_readme.md", "libraries.json"],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!, "dart-sdk"],
          relativePath: ["bin", "snapshots"],
          fileNames: [
            "analysis_server_aot.dart",
            "dartdev.dart",
            "gen_kernel_aot.dart",
            "kernel_worker_aot.dart",
            "kernel-service.dart",
          ],
        ) &&
        install(
          installPath: [env.installDirectoryPath, "bin", "utils"],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!],
          fileNames: [
            "gen_snapshot_product",
            "gen_snapshot_product_linux_x64",
            "gen_snapshot_product_linux_arm64",
            "gen_snapshot_product_linux_riscv64",
          ],
          excludeEndings: [".lib"],
        ) &&
        install(
          installPath: [env.installDirectoryPath],
          rootDirectoryPath: [env.vars["dart_binaries_path"]!, "dart-sdk"],
          fileNames: ["version", "LICENSE"],
        ) &&
        (File(path.join(env.installDirectoryPath, "LICENSE"))
              ..rename(path.join(env.installDirectoryPath, "dart.license")))
            .existsSync() &&
        (File(path.join(env.installDirectoryPath, "version"))
              ..rename(path.join(env.installDirectoryPath, "dart.version")))
            .existsSync(),
    exitFail: false,
  ),
  /**
   * This extra step occurs because we have to rename the simarm64 gen snapshot
   * for the later tooling to work properly.
   */
  Step(
    "Install simarm64 cross compilation gen snapshot tool",
    configure: (env) {
      for (FileSystemEntity entity in Directory(
        env.vars["product_simarm64_utils_path"],
      ).listSync()) {
        if (!(entity is File)) continue;

        if (path.basenameWithoutExtension(entity.path) != "gen_snapshot")
          continue;

        env.vars["simarm64_snapshot_path"] = path.join(
          env.vars["product_simarm64_utils_path"],
          path.basename(entity.path),
        );
      }
      env.vars["executable_ending"] = (env.target.platform == Platform.windows
          ? ".exe"
          : "");
    },
    condition: (env) => !File(env.vars["simarm64_snapshot_path"]).existsSync(),
    run: (env) =>
        (File(env.vars["simarm64_snapshot_path"])..copySync(
              path.join(
                env.installDirectoryPath,
                "bin",
                "utils",
                "gen_snapshot_product_simarm64" + env.vars["executable_ending"],
              ),
            ))
            .existsSync(),
  ),

  /**
   * In order to build the gen_snapshot for android_arm64 we have to modify
   * the build targets to allow the cross compilation tools.
   */
  Step(
    "Add configs to runtime build gn",
    configure: (env) {
      // env.vars["dart_sdk_path"] = path.join(env.scriptDirectoryPath, "test");
      env.vars["file_runtime"] = path.join(
        env.vars["dart_sdk_path"],
        "runtime",
        "BUILD.gn",
      );

      env.vars["file_runtime_binaries"] = path.join(
        env.vars["dart_sdk_path"],
        "runtime",
        "bin",
        "BUILD.gn",
      );

      env.vars["file_runtime_config"] = path.join(
        env.vars["dart_sdk_path"],
        "runtime",
        "configs.gni",
      );

      env.vars["file_sdk"] = path.join(env.vars["dart_sdk_path"], "BUILD.gn");
    },

    run: (env) {
      injectGNContent(
        file: File(env.vars["file_runtime"]),
        block: ["config(\"dart_linux_riscv64_config\")"],
        injectable: InjectAt.afterBlock,
        content: """
          config("dart_android_arm64_config") {
            defines = [
              "DART_TARGET_OS_ANDROID",
              "TARGET_ARCH_ARM64",
            ]
          }
          
          config("dart_android_arm_config") {
            defines = [
              "DART_TARGET_OS_ANDROID",
              "TARGET_ARCH_ARM",
            ]
          }
          """,
      );
      injectGNContent(
        file: File(env.vars["file_runtime_binaries"]),
        block: [
          "build_libdart_builtin(\"libdart_builtin_product_linux_riscv64\")",
        ],
        injectable: InjectAt.afterBlock,
        content: """
          build_libdart_builtin("libdart_builtin_product_android_arm64") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm64_config",
            ]
          }
          
          build_libdart_builtin("libdart_builtin_product_android_arm") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm_config",
            ]
          }
          """,
      );
      injectGNContent(
        file: File(env.vars["file_runtime_binaries"]),
        block: ["build_gen_snapshot(\"gen_snapshot_product_linux_riscv64\")"],
        injectable: InjectAt.afterBlock,
        content: """
          build_gen_snapshot("gen_snapshot_product_android_arm64") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm64_config",
            ]
            extra_deps = [
              ":gen_snapshot_dart_io_product_android_arm64",
              ":libdart_builtin_product_android_arm64",
              "..:libdart_precompiler_product_android_arm64",
              "../platform:libdart_platform_precompiler_product_android_arm64",
            ]
          }
          
          build_gen_snapshot("gen_snapshot_product_android_arm") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm_config",
            ]
            extra_deps = [
              ":gen_snapshot_dart_io_product_android_arm",
              ":libdart_builtin_product_android_arm",
              "..:libdart_precompiler_product_android_arm",
              "../platform:libdart_platform_precompiler_product_android_arm",
            ]
          }
          """,
      );
      injectGNContent(
        file: File(env.vars["file_runtime_binaries"]),
        block: [
          "build_gen_snapshot_dart_io(\"gen_snapshot_dart_io_product_linux_riscv64\")",
        ],
        injectable: InjectAt.afterBlock,
        content: """
          build_gen_snapshot_dart_io("gen_snapshot_dart_io_product_android_arm64") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm64_config",
            ]
          }
          
          build_gen_snapshot_dart_io("gen_snapshot_dart_io_product_android_arm") {
            extra_configs = [
              "..:dart_product_config",
              "..:dart_android_arm_config",
            ]
          }
          """,
      );

      injectGNContent(
        file: File(env.vars["file_runtime_config"]),
        block: ["_precompiler_product_linux_riscv64_config"],
        injectable: InjectAt.afterBlock,
        content: """
          _precompiler_product_android_arm64_config =
              [
                "\$_dart_runtime:dart_config",
                "\$_dart_runtime:dart_android_arm64_config",
              ] + _product + _precompiler_base
          
          _precompiler_product_android_arm_config =
              [
                "\$_dart_runtime:dart_config",
                "\$_dart_runtime:dart_android_arm_config",
              ] + _product + _precompiler_base
          """,
      );

      injectGNContent(
        file: File(env.vars["file_runtime_config"]),
        block: ["_all_configs"],
        injectable: InjectAt.blockEnd,
        content: """
            {
              suffix = "_precompiler_product_android_arm64"
              configs = _precompiler_product_android_arm64_config
              snapshot = false
              compiler = true
              is_product = true
            },
            {
              suffix = "_precompiler_product_android_arm"
              configs = _precompiler_product_android_arm_config
              snapshot = false
              compiler = true
              is_product = true
            },
          """,
      );

      injectGNContent(
        file: File(env.vars["file_sdk"]),
        block: ["group(\"create_full_sdk\")"],
        injectable: InjectAt.blockEnd,
        content: """
          if (dart_target_arch != "ia32" && dart_target_arch != "x86" && dart_target_arch != "arm") {
            public_deps += [
              "../runtime/bin:gen_snapshot_product_android_arm64",
              "../runtime/bin:gen_snapshot_product_android_arm",
            ]
          }
          """,
      );
      return true;
    },
  ),
];

enum InjectAt { blockStart, blockEnd, afterBlock }

Future<bool> injectGNContent({
  required File file,
  required String content,
  List<String> block = const [],
  InjectAt injectable = InjectAt.blockEnd,
}) async {
  final fileContent = await file.readAsString();

  int position = 0;
  final List<String> context = [];

  String current = "";
  Future<void> processFile() async {
    for (final String char in fileContent.codeUnits.map(
      (e) => utf8.decode([e]),
    )) {
      current += char;
      position += utf8.encode(char).lengthInBytes;

      final bool blockOpenBrace = char.contains('{');
      final bool blockCloseBrace = char.contains('}');

      if (blockOpenBrace) {
        context.add(current);
        current = "";
      }

      if (blockCloseBrace && context.isNotEmpty) {
        context.removeLast();
        current = "";
      }

      for (int i = 0; i < context.length; i++) {
        if (context.length != block.length ||
            !context.last.contains(block.last) ||
            !context[i].contains(block[i])) {
          break;
        }

        if (i == context.length - 1) {
          if (blockOpenBrace && (injectable == InjectAt.blockStart))
            return;
          else if (blockCloseBrace) {
            if (injectable == InjectAt.afterBlock)
              return;
            else if (injectable == InjectAt.blockEnd) {
              position -= utf8.encode(char).lengthInBytes;
              return;
            }
          } else
            continue;
        }
      }
    }
  }

  await processFile();
  if (position == file.lengthSync() && context.isEmpty) {
    return false;
  }
  final output = File("./${path.basename(file.path)}")
    ..writeAsStringSync(fileContent);
  output.openSync(mode: FileMode.writeOnlyAppend)
    ..setPositionSync(position)
    ..writeStringSync(content);
  print(
    "\nposition: $position, file length: ${file.lengthSync()}, context: $context\n",
  );
  return true;
}
