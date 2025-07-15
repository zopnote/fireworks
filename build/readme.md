# Build Fireworks
Fireworks is a complex project participated in targets and steps through the build. 
Therefore, it could be quite complicated to first figure out how to build the sdk.
An own build system was done to prevent too much complexity. This documentation should give you an overview how to achieve compiled binaries of the
Fireworks project.

Because Fireworks depends on fragile software systems the decision was taken, to
build the sdk with own scripts and without a build system. The entry point for every build is ``build.dart``, inside the file are build targets specified, which directs to a list of ``BuildStep``-objects that were
created to generically represents a step of compilation or processing.

### Supported platforms

| Source Host Platform | SDK Target Platform           | Resulting SDK can develop for                                                        |
|----------------|-------------------------------|--------------------------------------------------------------------------------------|
| windows_x86_64 | windows_x86_64; windows_arm64 | android_arm64; android_arm; windows_arm64; windows_x86_64; linux_x86_64; linux_arm64 |
| linux_x86_64   | linux_x86_64; linux_arm64     | android_arm64; android_arm; linux_x86_64; linux_arm64                                |
| macos_arm64    | macos_arm64                   | ios_arm64; macos_arm64; android_arm64; android_arm; linux_x86_64; linux_arm64        |


List all build targets with:
````bash
dart run bin/build.dart --list
````

Build a target with:
````bash 
dart run bin/build.dart <target>
````
Add some spice:
````bash 
dart run bin/build.dart <target> --platform=windows_arm64 --config=release --verbose
````
## The build scripts
If you want more than just build the SDK and let it run, you need some insights. The build system to build Fireworks is based on the same
Dart package that is the foundation of the Fireworks command line app build system.
````dart
import 'package:fireworks.cli/build/config';

void main() async {
  await BuildConfig(
    "sdk",
    target: System(
      platform: SystemPlatform.windows,
      processor: SystemProcessor.x86_64
    ),
    buildType: BuildType.release,
  ).execute([
    BuildStep(
      "Example build run step",
      run: (env) {
        File("${env.workDirectoryPath}/example.txt").createSync();
        return true;
      }
    ),
    BuildStep(
      "Example build command step",
      command: (env) => BuildStepCommand(
        program: "git",
        arguments: [
          "clone",
          "https://github.com/zopnote/fireworks.git"
        ]
      )
    )
  ]);
}
````

The entirety of Fireworks is build just like that, with participation's to different targets and platform checks.
A linear execution of programs and functions, easily readable.
