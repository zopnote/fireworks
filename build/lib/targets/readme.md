## Build targets
Build targets have to be registered in ``package:firework.build/targets.dart``.
This directory mirrors the project structure for better overview, but at the end it is regardless 
how the scripts are positioned as long as their inclusion (``import '...';``) paths
are set right.

**Target dependencies**:
If a target depend on another target, the target will just build the depend-target before the own
``BuildStep``s be executed and save its working- and install directory to perform steps with the 
binaries.

# Target documentation

## ``app``
The Fireworks app is the heart of the SDK. It isn't the biggest and complex part, but
it is the main reason why anyone should decide for Fireworks instead of the more-feature-rich
engines. It provides a special development experience and the necessary tools for everything.


## ``vendor/``
### ``dart_sdk``
The Dart SDK is one of the most important dependencies. It is the main reason for the idea Fireworks
to came up. It is also one of the most fragile and complex dependencies, because
we build the platform sdk and then several cross compilation build tools as well as an embedder to
make all things work. Let us talk about these binaries.

At first, we build the platform sdk which is the easiest. Just clone the ``depot_tools`` of Google,
fetch the Dart repository, switch tag to a specific version, get the dependencies with ``gclient`` and then
build the sdk for the target system. But then things will get more complicated.

Dart doesn't officially support cross compilation on Windows or macOS to Android and macOS to iOS.
For these, a modification of the Generate Ninja build scripts is necessary to build the required binaries.
Thankfully while im in development of the build infrastructure, the Dart team started to support
Linux cross compilation and I can just look up the dart-sdk commit [d257c52
](https://github.com/dart-lang/sdk/commit/d257c52309d90389c4d8c15aec7588eb21acbf54) to find out which
targets I have to add.

After all, the cross compilation binaries are installed together with the platform sdk into ``vendor/``.

### ``clang``
Because Fireworks ship with a complete environment clang is also part of the build process.
We build the entire llvm-project and then just extracts out clang (executable) and of course their license.
