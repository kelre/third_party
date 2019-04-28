#!/bin/bash

## $1: target
## $2: build dir (prefix)
## $3: destination directory where ffmpeg binary will copy to

set -e
set -x

## Support either NDK linux or darwin (mac os)
## Check $NDK exists
if [ "$NDK" = "" ] || [ ! -d $NDK ]; then
	echo "NDK variable not set or path to NDK is invalid, exiting..."
	exit 1
fi

export TARGET=$1
export FLAVOR=$2
export PREFIX=$3
export DESTINATION_FOLDER=$4

if [ "$(uname)" == "Darwin" ]; then
    OS="darwin-x86_64"
else
    OS="linux-x86_64"
fi

NATIVE_SYSROOT=/

if [ "$FLAVOR" = "lite" ]; then 
    # LITE flavor support android 16+
    ARM_SYSROOT=$NDK/platforms/android-16/arch-arm/
    X86_SYSROOT=$NDK/platforms/android-16/arch-x86/
else 
    # FULL flavor require android 21 at minimum (because of including openssl)
    ARM_SYSROOT=$NDK/platforms/android-21/arch-arm/
    X86_SYSROOT=$NDK/platforms/android-21/arch-x86/
fi
ARM_PREBUILT=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$OS
X86_PREBUILT=$NDK/toolchains/x86-4.9/prebuilt/$OS

ARM64_SYSROOT=$NDK/platforms/android-21/arch-arm64/
ARM64_PREBUILT=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/$OS

X86_64_SYSROOT=$NDK/platforms/android-21/arch-x86_64/
X86_64_PREBUILT=$NDK/toolchains/x86_64-4.9/prebuilt/$OS

## No longer support MIPS MIPS64

# MIPS_SYSROOT=$NDK/platforms/android-16/arch-mips/
# MIPS_PREBUILT=$NDK/toolchains/mipsel-linux-android-4.9/prebuilt/darwin-x86_64
# MIPS_CROSS_PREFIX=$MIPS_PREBUILT/bin/$HOST-

# MIPS64_SYSROOT=$NDK/platforms/android-21/arch-mips64/
# MIPS64_PREBUILT=$NDK/toolchains/mips64el-linux-android-4.9/prebuilt/darwin-x86_64
# MIPS64_CROSS_PREFIX=$MIPS64_PREBUILT/bin/$HOST-

if [ "$FFMPEG_VERSION" = "" ]; then
    FFMPEG_VERSION="4.0.2"
fi
if [ ! -d "ffmpeg-${FFMPEG_VERSION}" ]; then
    echo "Downloading ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    curl -LO http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2
    echo "extracting ffmpeg-${FFMPEG_VERSION}.tar.bz2"
    tar -xf ffmpeg-${FFMPEG_VERSION}.tar.bz2
else
    echo "Using existing `pwd`/ffmpeg-${FFMPEG_VERSION}"
fi



function build_one
{

if [ "$(uname)" == "Darwin" ]; then
    #brew install yasm nasm automake gettext
    export PATH="/usr/local/opt/gettext/bin:$PATH"
else
    sudo apt-get update
    sudo apt-get -y install automake autopoint libtool gperf
    # Install nasm >= 2.13 for libx264
    if [ ! -d "nasm-2.13.03" ]; then
        curl -LO 'http://www.nasm.us/pub/nasm/releasebuilds/2.13.03/nasm-2.13.03.tar.xz'
        tar -xf nasm-2.13.03.tar.xz
    fi
    pushd nasm-2.13.03
        ./configure --prefix=/usr
        make
        sudo make install
    popd

    if [ "$FLAVOR" = "full" ]; then 
        pushd gettext-${GETTEXT_VERSION}
            ./configure --prefix=/usr
            make
            sudo make install
        popd
    fi;
fi

if [ $ARCH == "native" ]
then
    SYSROOT=$NATIVE_SYSROOT
    HOST=
    CROSS_PREFIX=
    if [ "$(uname)" == "Darwin" ]; then
        brew install openssl
    else 
        sudo apt-get install -y libssl-dev
    fi
elif [ $ARCH == "arm" ]
then
    SYSROOT=$ARM_SYSROOT
    HOST=arm-linux-androideabi
    CROSS_PREFIX=$ARM_PREBUILT/bin/$HOST-
    OPTIMIZE_CFLAGS="$OPTIMIZE_CFLAGS "
elif [ $ARCH == "arm64" ]
then
    SYSROOT=$ARM64_SYSROOT
    HOST=aarch64-linux-android
    CROSS_PREFIX=$ARM64_PREBUILT/bin/$HOST-
elif [ $ARCH == "x86_64" ]
then
    SYSROOT=$X86_64_SYSROOT
    HOST=x86_64-linux-android
    CROSS_PREFIX=$X86_64_PREBUILT/bin/$HOST-
elif [ $ARCH == "i686" ]
then
    SYSROOT=$X86_SYSROOT
    HOST=i686-linux-android
    CROSS_PREFIX=$X86_PREBUILT/bin/$HOST-
# elif [ $ARCH == "mips" ]
# then
#     SYSROOT=$MIPS_SYSROOT
#     HOST=mipsel-linux-android
#     CROSS_PREFIX=$MIPS_CROSS_PREFIX
# elif [ $ARCH == "mips64" ]
# then
#     SYSROOT=$MIPS64_SYSROOT
#     HOST=mips64el-linux-android
#     CROSS_PREFIX=$MIPS64_CROSS_PREFIX

fi

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export CPP="${CROSS_PREFIX}cpp"
export CXX="${CROSS_PREFIX}g++"
export CC="${CROSS_PREFIX}gcc"
export LD="${CROSS_PREFIX}ld"
export AR="${CROSS_PREFIX}ar"
export NM="${CROSS_PREFIX}nm"
export RANLIB="${CROSS_PREFIX}ranlib"
export LDFLAGS="-L$PREFIX/lib -fPIE -pie "
export CFLAGS="$OPTIMIZE_CFLAGS -I$PREFIX/include --sysroot=$SYSROOT -fPIE "
export CXXFLAGS="$CFLAGS "
export CPPFLAGS="--sysroot=$SYSROOT "
export STRIP=${CROSS_PREFIX}strip
export PATH="$PATH:$PREFIX/bin/"



# (wget --no-check-certificate https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/master/gas-preprocessor.pl && \
#     chmod +x gas-preprocessor.pl && \
#     sudo mv gas-preprocessor.pl /usr/bin) || exit 1
pushd ffmpeg-$FFMPEG_VERSION

if [ $ARCH == "native" ] 
then
    CROSS_COMPILE_FLAGS=
else 
    CROSS_COMPILE_FLAGS="--target-os=linux \
        --arch=$ARCH \
        --cross-prefix=$CROSS_PREFIX \
        --enable-cross-compile \
        --sysroot=$SYSROOT"
fi


# Build - LITE version
./configure --prefix=$PREFIX \
    $CROSS_COMPILE_FLAGS \
    --pkg-config=$(which pkg-config) \
    --pkg-config-flags="--static" \
    --enable-pic \
    --enable-small \
    --enable-gpl \
    --disable-everything \
    \
    --disable-shared \
    --disable-debug \
    --enable-static \
    \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-avfilter \
    --disable-postproc \
    --disable-bsfs \
    --disable-indevs \
    --disable-outdevs \
    --disable-avdevice \
    --disable-swscale \
    --disable-parsers \
    \
    --disable-protocols \
    --enable-protocol='file,http' \
    \
    --disable-demuxers \
    --disable-muxers \
    --enable-demuxer='mp3,ogg,flac,ape,wav,amr,amrnb,amrwb' \
    --enable-parser='ape,flac,opus' \
    \
    --disable-encoders \
    --disable-decoders \
    --enable-decoder='mp3,flac,vorbis,ape,pcm_s16be,pcm_s16be_planar,pcm_s16le,pcm_s16le_planar,opus,amr_nb_at,amrnb,amrwb' \
    \
    --disable-doc \
    $ADDITIONAL_CONFIGURE_FLAG


make clean
make -j8
make install V=1

mkdir -p $DESTINATION_FOLDER/$FLAVOR/

popd
}

ARM_NEON="no"
if [ $TARGET == 'arm-v7n' ]; then
    #arm v7n
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -mtune=cortex-a8 -march=$CPU -Os -O3"
    ADDITIONAL_CONFIGURE_FLAG="--enable-neon "
    LIBX264_FLAGS=
    ARM_NEON="yes"    
    build_one
elif [ $TARGET == 'arm64-v8a' ]; then
    #arm64-v8a
    CPU=armv8-a
    ARCH=arm64
    OPTIMIZE_CFLAGS="-march=$CPU -Os -O3"
    ADDITIONAL_CONFIGURE_FLAG=
    LIBX264_FLAGS=
    build_one
elif [ $TARGET == 'x86_64' ]; then
    #x86_64
    CPU=x86-64
    ARCH=x86_64
    OPTIMIZE_CFLAGS="-fomit-frame-pointer -march=$CPU -Os -O3"
    ADDITIONAL_CONFIGURE_FLAG=
    LIBX264_FLAGS=
    build_one
elif [ $TARGET == 'i686' ]; then
    #x86
    CPU=i686
    ARCH=i686
    OPTIMIZE_CFLAGS="-fomit-frame-pointer -march=$CPU -Os -O3"
    # disable asm to fix 
    ADDITIONAL_CONFIGURE_FLAG='--disable-asm' 
    LIBX264_FLAGS="--disable-asm"
    build_one
elif [ $TARGET == 'armv7-a' ]; then
    # armv7-a
    CPU=armv7-a
    ARCH=arm
    OPTIMIZE_CFLAGS="-mfloat-abi=softfp -marm -march=$CPU -Os -O3 "
    ADDITIONAL_CONFIGURE_FLAG=
    LIBX264_FLAGS=
    build_one
elif [ $TARGET == 'arm' ]; then
    #arm
    CPU=armv5te
    ARCH=arm
    OPTIMIZE_CFLAGS="-march=$CPU -Os -O3 "
    ADDITIONAL_CONFIGURE_FLAG=
    LIBX264_FLAGS="--disable-asm"
    build_one
elif [ $TARGET == 'native' ]; then
    # host = current machine
    CPU=x86-64
    ARCH=native
    OPTIMIZE_CFLAGS="-O2 -pipe -march=native"
    ADDITIONAL_CONFIGURE_FLAG=
    LIBX264_FLAGS=
    build_one
else
    echo "Unknown target: $TARGET"
    exit 1
fi

