import 'package:fireworks.cli/build/config.dart';
import 'package:fireworks.cli/build/process.dart';
import '../targets.dart';

final List<BuildStep> processSteps = [
  BuildStep(
    "Build high priority dependency artifacts",
    run: (env) async {
      bool result = await BuildConfig(
        "clang",
        installPath: ["bin", "clang"],
        buildType: env.buildType,
        variables: env.variables,
        target: env.target
      ).execute(targets["clang"]!);
      result = result && await BuildConfig(
          "dart_sdk",
          installPath: ["bin", "dart_sdk"],
          buildType: env.buildType,
          variables: env.variables,
          target: env.target
      ).execute(targets["dart_sdk"]!);
      return result;
    }
  )
];