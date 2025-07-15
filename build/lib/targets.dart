
import 'package:fireworks.cli/build/process.dart';

import 'targets/artifacts/clang.dart' as clang;
import 'targets/artifacts/dart_sdk.dart' as dart_sdk;
import 'targets/sdk.dart' as sdk;


/// All registered build targets
final Map<String, List<BuildStep>> targets = {
  "sdk": sdk.processSteps,
  "clang": clang.processSteps,
  "dart_sdk": dart_sdk.processSteps
};