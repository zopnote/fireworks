import os, platform

os_name = platform.system()
print(f"")
android_ndk_path = os.getenv('ANDROID_NDK')
emscripten_path = os.getenv('EMSDK')