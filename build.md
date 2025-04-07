# Building Fireworks for several platforms
Fireworks development environment is not supported on every platform because of the support flutter and dart has. 
## Base prerequisites
* [CMake](https://cmake.org/download/) with version 3.20 or higher

# Windows
## x86 target
> Host is a Windows x86 or x64/amd64 machine

All targets are **available for this platform**.

**Build requirements**:

Click  [here](https://visualstudio.microsoft.com/de/downloads/) to get the Microsoft Visual Studio installer
* Install Visual Studio with Desktop environment for C++
* MSVC v143 VS 2022 C++ x64/x86 buildtools (newest)
* Windows 11-SDK (recommend v10.0.26100.0) from the Visual Studio installer
* Flutter SDK (recommend v3.29.1) ([here](https://docs.flutter.dev/release/archive))
* Go language binaries for Windows amd64 ([here](https://go.dev/dl/))

If you have problems with bgfx see its prerequisites [here](https://bkaradzic.github.io/bgfx/build.html). 

````shell
cmake -S . --preset win-x86_64 --DCMAKE_BUILD_TYPE=Debug
````

## ARM64 target
> Host is a Windows x86 or x64/amd64 machine

All targets are **available for this platform**.

**Build requirements**:

Click [here](https://visualstudio.microsoft.com/de/downloads/)  to get the Microsoft Visual Studio installer
* Install Visual Studio with Desktop environment for C++
* MSVC v143 VS 2022 C++ ARM64/ARM64EC buildtools (newest version) ([More Information](https://devblogs.microsoft.com/cppblog/windows-arm64-support-for-cmake-projects-in-visual-studio/))
* Windows 11-SDK (recommend v10.022621.0) from the Visual Studio installer
* Go language binaries for Windows amd64 ([here](https://go.dev/dl/))

````shell
cmake -S . --preset win-arm64 --DCMAKE_BUILD_TYPE=Debug
````

# Linux
**Recommend** is an Ubuntu 22.04+ distribution as target and host. SteamOS is also officially supported as target.

## x86_64 target
> Host is a Linux x86_64 machine

All targets are **available for this platform**.

**Build requirements**:
* Get the Vulkan SDK for x86_64 Linux ([here](https://vulkan.lunarg.com/sdk/home#linux))
* Download the Go language binaries for Linux x86_64 ([here](https://go.dev/dl/))
* Setup the Flutter SDK ([here](https://docs.flutter.dev/get-started/install/linux/desktop))
* Install the packages:
````shell
sudo apt-get update -y && sudo apt-get upgrade -y;
````
````shell
sudo apt-get install \
libgl1-mesa-dev x11proto-core-dev libx11-dev build-essential git make \
pkg-config cmake ninja-build gnome-desktop-testing libasound2-dev libpulse-dev \
libaudio-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev \
libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev 
````
If you encounter problems related to X11 add ``libx11*`` as packages.\
On Ubuntu 22.04+ as host add ``libpipewire-0.3-dev libwayland-dev libdecor-0-dev liburing-dev``.

For more information about Linux requirements check out
[SDL Linux build prerequisites](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md) and
[bgfx prerequisites](https://bkaradzic.github.io/bgfx/build.html).

````shell
cmake -S . --preset linux-x86_64 --DCMAKE_BUILD_TYPE=Debug
````

## aarch64 target
> Host is a Linux x86_64 machine or Linux aarch64 machine

All targets are **available for this platform**.

**Build requirements**:
* Download the Go language binaries for Linux arm64 ([here](https://go.dev/dl/))
* Setup the Flutter SDK ([here](https://docs.flutter.dev/get-started/install/linux/desktop))
* Install the packages:
````shell
sudo apt-get update -y && sudo apt-get upgrade -y;
````
````shell
sudo apt-get install gcc-aarch64-linux-gnueabihf g++-aarch64-linux-gnueabihf \
libgl1-mesa-dev x11proto-core-dev libx11-dev build-essential git make \
pkg-config cmake ninja-build gnome-desktop-testing libasound2-dev libpulse-dev \
libaudio-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev \
libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev 
````
If you encounter problems related to X11 add ``libx11*`` as packages.\
On Ubuntu 22.04+ as host add ``libpipewire-0.3-dev libwayland-dev libdecor-0-dev liburing-dev``.

For more information about Linux requirements check out 
[SDL Linux build prerequisites](https://github.com/libsdl-org/SDL/blob/main/docs/README-linux.md) and
[bgfx prerequisites](https://bkaradzic.github.io/bgfx/build.html).

````shell
cmake -S . --preset linux-arm64 --DCMAKE_BUILD_TYPE=Debug
````

# macOS
> Host is a macOS apple silicon machine
## Apple silicon macOS target
All targets are **available for this platform**.

**Build requirements**:
* Xcode with Clang C/C++ compilation toolchain ([here](https://developer.apple.com/xcode/))
* Download the Go language binaries for macOS arm64 ([here](https://go.dev/dl/))
* Install the Metal development kit on your device ([here](https://developer.apple.com/metal/))
* Setup the Flutter SDK for macOS ([here](https://docs.flutter.dev/get-started/install/macos/desktop))

````shell
cmake -S . --preset macos --DCMAKE_BUILD_TYPE=Debug
````

## iOS target
iOS just supports the engine runtime.

**Build requirements**:
* Xcode with Clang C/C++ compilation and iOS toolchain ([here](https://developer.apple.com/xcode/))
* Install the Metal development kit on your device ([here](https://developer.apple.com/metal/))

````shell
cmake -S . --preset ios --DCMAKE_BUILD_TYPE=Debug
````


# Emscripten
> Host is a Windows x86 or x64/amd64 machine, Linux x86_64 machine, macOS apple silicon machine

Emscripten just supports the engine runtime.

1. Setup your host platform as target, because you need the many of the libraries also for an Emscripten build. But you can left Go, Flutter and Vulkan out.
2. Install the Emscripten SDK on your platform (at least v3.16.0) ([here](https://emscripten.org/docs/getting_started/downloads.html))
3. Set the root directory of the Emscripten SDK as environment variable ``EMSDK``.

````shell
cmake -S . --preset emscripten --DCMAKE_BUILD_TYPE=Debug
````


# Android
> Host is a Windows x86 or x64/amd64 machine, Linux x86_64 machine, macOS apple silicon machine

Android just supports the engine runtime.

1. Download the Android NDK (here)
2. Set the Android NDK root as environment variable ``ANDROID_NDK``.

````shell
cmake -S . --preset android-arm64-v8a --DCMAKE_BUILD_TYPE=Debug
````
