# Building Fireworks for several platforms
Fireworks development environment is not supported on every platform because of the support flutter and dart has
## Base prerequisites
* [CMake](https://cmake.org/download/) with version 3.20 or higher

# Windows
> Host is a Windows x86_64 machine
## x86 target
Windows x86 supports the full Fireworks SDK

**Build requirements**:
* Flutter SDK
* Dart language SDK
* Download the [Windows SDK](https://developer.microsoft.com/windows/downloads/windows-sdk/) with the modules for x86_64
* Use the [Microsoft Visual Studio installer](https://visualstudio.microsoft.com/de/downloads/) to download the MSVC x86_64 and x64 Buildtools

## arm64 target
Windows arm64 supports the engine runtime

**Build requirements**:
* Download the [Windows SDK](https://developer.microsoft.com/windows/downloads/windows-sdk/) with the modules for ARM64
* Use the [Microsoft Visual Studio installer](https://visualstudio.microsoft.com/de/downloads/) to download the MSVC ARM Buildtools

# Linux
> Host is a Linux x86_64 machine

## x86 target
Linux x86 supports the full Fireworks SDK

**Build requirements**:
* Flutter SDK ([More install details](https://docs.flutter.dev/get-started/install/linux/desktop))
* Dart language SDK ([More install details](https://dart.dev/get-dart#install))
* Unix Makefiles, GNU C & C++ compiler (apt-get ``build-essential``)

## arm64 target
Linux arm64 supports the engine runtime

**Build requirements**:
* GNU C & C++ ARM compiler toolchain
* Unix Makefiles
````shell
sudo apt-get update -y && sudo apt-get upgrade -y;
sudo apt-get install gcc-aarch64-linux-gnueabihf g++-aarch64-linux-gnueabihf build-essential
````

# macOS
> Host is a macOS arm64 machine
## arm64 target
macOS arm64 supports the full Fireworks SDK

**Build requirements**:
* XCode with C & C++ Compiler toolchain