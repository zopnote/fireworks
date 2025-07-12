import 'dart:io';

import 'package:fireworks.cli/build/config.dart';
import 'package:path/path.dart' as path;

final BuildConfigCallback defaultConfigOverride = (conf) => conf.reconfigure(
  outputDirectory: Directory(
    path.join(
      conf.outputDirectory.path,
      "${conf.buildType.name}-${conf.target.string()}",
    ),
  ),
  workDirectory: Directory(
    path.join(
      conf.workDirectory.path,
      "${conf.buildType.name}-${conf.target.string()}",
    ),
  ),
  variables: {
    "info": {
      ""
    }
  }
);
