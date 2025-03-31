import os
import subprocess
import argparse
import sys

# Define host-target configurations
HOST_TARGET_CONFIGS = {
    "win-x86_64": ["windows-x64", "windows-arm64", "android-arm64", "android-x86_64", "android-x86", "asmjs"],
    "linux-x86_64": ["linux-x64", "linux-arm64", "android-arm64", "android-x86_64", "android-x86", "asmjs"],
    "macos": ["osx", "ios", "android-arm64", "android-x86_64", "android-x86", "asmjs"]
}

# Toolchain checks
def check_toolchains(targets):
    missing_tools = []
    for target in targets:
        if target.startswith("android"):
            if not os.environ.get("ANDROID_NDK_ROOT"):
                missing_tools.append("Android NDK")
        elif target == "asmjs":
            if not os.environ.get("EMSDK"):
                missing_tools.append("Emscripten SDK")
        elif target == "ios" or target == "osx":
            if not os.path.exists("/Applications/Xcode.app"):
                missing_tools.append("Xcode")
        elif target.startswith("windows"):
            # Check for Visual Studio
            vswhere_path = r"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
            if not os.path.exists(vswhere_path):
                missing_tools.append("Visual Studio")
    return missing_tools

# Clone repositories if they don't exist
def clone_repos():
    repos = {
        "bx": "https://github.com/bkaradzic/bx.git",
        "bimg": "https://github.com/bkaradzic/bimg.git",
        "bgfx": "https://github.com/bkaradzic/bgfx.git"
    }
    for name, url in repos.items():
        if not os.path.exists(name):
            subprocess.run(["git", "clone", url], check=True)

# Build BGFX for the specified targets
def build_bgfx(targets):
    for target in targets:
        print(f"Building for target: {target}")
        build_command = ["make", f"config={target}-release64"]
        subprocess.run(build_command, cwd="bgfx", check=True)

def main():
    parser = argparse.ArgumentParser(description="Build BGFX for specified targets.")
    parser.add_argument("--target", help="Sets the target configuration for the build.")
    parser.add_argument("--all", action="store_true", help="Build all available target configs.")
    args = parser.parse_args()

    if args.all:
        targets = set()
        for t in HOST_TARGET_CONFIGS.values():
            targets.update(t)
        targets = list(targets)
    elif args.target:
        if args.target in HOST_TARGET_CONFIGS:
            targets = HOST_TARGET_CONFIGS[args.target]
        else:
            print(f"Unknown target configuration: {args.target}")
            sys.exit(1)
    else:
        print("No target specified. Use --target or --all.")
        sys.exit(1)

    missing_tools = check_toolchains(targets)
    if missing_tools:
        print("Warning: The following required tools were not found:")
        for tool in set(missing_tools):
            print(f" - {tool}")
        print("Please ensure these are installed and configured correctly.")

    clone_repos()
    build_bgfx(targets)

if __name__ == "__main__":
    main()
