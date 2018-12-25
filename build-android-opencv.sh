#!/bin/bash

NDK_ROOT=~/Program/android-ndk-r14b

#NDK_ROOT="${1:-${NDK_ROOT}}"

export ANDROID_NDK=$NDK_PATH


#ffmpeg
export LD_LIBRARY_PATH=/Users/cmm/Desktop/work/opencv-ffmpeg/ffmpeg-opt/armv6/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/Users/cmm/Desktop/work/opencv-ffmpeg/ffmpeg-opt/armv6/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR:/Users/cmm/Desktop/work/opencv-ffmpeg/ffmpeg-opt/armv6/lib

#cuda
CUDA_ROOT=/Developer/NVIDIA/CUDA-10.0/
#export CUDA_LIBRARIES=$CUDA_LIBRARIES:$CUDA_ROOT
#export CUDA_LIBS_PATH=$CUDA_LIBS_PATH:$CUDA_ROOT/lib
#export CUDA_DIR=$PATH:$CUDA_ROOT/include
export CUDA_PATH=$CUDA_PATH:$CUDA_ROOT
export CUDA_SDK_ROOT_DIR=$CUDA_SDK_ROOT_DIR:$CUDA_ROOT/lib
export CUDA_INCLUDE_DIRS=$CUDA_ROOT/include
export CUDA_LIBRARIES=$CUDA_ROOT/lib

### ABIs setup
#declare -a ANDROID_ABI_LIST=("x86" "x86_64" "armeabi-v7a with NEON" "arm64-v8a")
#declare -a ANDROID_ABI_LIST=("x86" "x86_64" "armeabi" "arm64-v8a" "armeabi-v7a" "mips" "mips64")
declare -a ANDROID_ABI_LIST=("armeabi")

### path setup
#SCRIPT=$(readlink -f $0)
SCRIPT=$(stat -f $0)
WD=$(pwd `dirname $SCRIPT`)
OPENCV_ROOT="${WD}/opencv"
N_JOBS=${N_JOBS:-4}

### Download android-cmake
if [ ! -d "${WD}/android-cmake" ]; then
    echo 'Cloning android-cmake'
    git clone https://github.com/taka-no-me/android-cmake.git
fi

INSTALL_DIR="${WD}/android_opencv"
rm -rf "${INSTALL_DIR}/opencv"

### Make each ABI target iteratly and sequentially
for i in "${ANDROID_ABI_LIST[@]}"
do
    ANDROID_ABI="${i}"
    echo "Start building ${ANDROID_ABI} version"

    if [ "${ANDROID_ABI}" = "armeabi" ]; then
        API_LEVEL=19
    else
        API_LEVEL=21
    fi

    temp_build_dir="${OPENCV_ROOT}/platforms/build_android_${ANDROID_ABI}"
    ### Remove the build folder first, and create it
    rm -rf "${temp_build_dir}"
    mkdir -p "${temp_build_dir}"
    cd "${temp_build_dir}"

    cmake -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
          -D CMAKE_TOOLCHAIN_FILE="${WD}/android-cmake/android.toolchain.cmake" \
          -D ANDROID_NDK="${NDK_ROOT}" \
          -D ANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
          -D ANDROID_ABI="${ANDROID_ABI}" \
          -D WITH_CUDA=ON \
          -D WITH_MATLAB=ON \
          -D WITH_CUBLAS=ON \
          -D CUDA_FAST_MATH=ON \
          -D WITH_CUFFT=ON \
          -D WITH_NVCUVID=ON \
          -D WITH_V4L=ON \
          -D WITH_LIBV4L=ON \
          -D WITH_OPENGL=ON \
          -D BUILD_ANDROID_EXAMPLES=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_TESTS=OFF \
          -D WITH_FFMPEG=ON \
          -D WITH_TBB=ON \
          -D WITH_IPP=ON \
          -D WITH_OPENCL=ON \
          -D WITH_OPENMP=ON \
          -D WITH_GTK=ON \
          -D BUILD_SHARED_LIBS=OFF \
          -D OPENCV_ENABLE_NONFREE=ON \
          -D OPENCV_EXTRA_MODULES_PATH="${WD}/opencv_contrib/modules/"  \
          -D CMAKE_INSTALL_PREFIX="${INSTALL_DIR}/opencv" \
          -D BUILD_ANDROID_PROJECTS=OFF \
          -D CMAKE_BUILD_TYPE=Release \
          -D CUDA_TOOLKIT_ROOT_DIR=$CUDA_ROOT \
          -D CUDA_ARCH_BIN='2.0 3.0 3.5 3.7 5.0 5.2 6.0 6.1' \
          -D CUDA_ARCH_PTX="" \
          ../..
    # Build it
    #make -j${N_JOBS}
    make
    # Install it
    make install/strip
    ### Remove temp build folder
    cd "${WD}"
    rm -rf "${temp_build_dir}"
    echo "end building ${ANDROID_ABI} version"
done
