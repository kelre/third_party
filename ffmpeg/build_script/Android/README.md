[![Android Arsenal](https://img.shields.io/badge/Android%20Arsenal-Prebuilt%20FFmpeg%20Android-brightgreen.svg?style=flat-square)](https://android-arsenal.com/details/1/6815)

# Prebuilt FFmpeg Android
This repo contains build scripts to build FFmpeg executable binary for Android and also [publish prebuilt files here](https://github.com/Khang-NT/ffmpeg-binary-android/releases).
There are two build flavors: _FULL_ and _LITE_
  * **LITE** is a version that optimized binrary size, so it only includes small set features to work with most commom formats and codecs.
    + ABI and android version supported:
      - `armeabi` (Android 16+)
      - `armeabi-v7a`, `armeabi-v7a-neon`, (Android 16+)
      - `x86`  (Android 16+)
      - `arm64-v8a`  (Android 21+)
      - `x86_64` (Android 21+)
      - ~~`mips`  (Android 16+)~~ (No longer support)
      - ~~`mips64` (Android 21+)~~ (No longer support)
    + Addition libraries: `libmp3lame`, `libshine`, `libopus`, `libvorbis`
  * **FULL** is a version compiled full FFmpeg feature, include **https** support protocol.
    + ABI and android version supported:
      - `armeabi` (Android **21+**)
      - `armeabi-v7a`, `armeabi-v7a-neon`, (Android **21+**)
      - `x86`  (Android **21+**)
      - `arm64-v8a`  (Android 21+)
      - `x86_64` (Android 21+)
    + Include libraries in `LITE` version, plus with: `libfdk-aac` (**non-free**), `libx264`, **`openssl`** (thanks to [leenjewel/openssl_for_ios_and_android](https://github.com/leenjewel/openssl_for_ios_and_android))

## Download
Latest build: 
[![Latest build](https://img.shields.io/github/release/Khang-NT/ffmpeg-binary-android.svg?style=for-the-badge)](https://github.com/Khang-NT/ffmpeg-binary-android/releases)

## Build  

Prerequisites:
  * Android NDK r15
  * `export NDK=path/to/android-ndk`

Build:
```bash
export NDK=path/to/android-ndk
cd build_scripts

FLAVOR=full       # or "lite"
TARGET=armv7-a    # Support targets: "arm", "armv7-a", "arm-v7n", "arm64-v8a", "i686", "x86_64"
BUILD_DIR=$(pwd)/build_dir
FINAL_DIR=$(pwd)/final/$TARGET

./build_ffmpeg.sh $TARGET $FLAVOR $BUILD_DIR $FINAL_DIR
```

