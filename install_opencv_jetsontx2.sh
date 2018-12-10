#!/bin/bash -x

# This is the script to install OpenCV 3.4.3 and OpenCV_contrib 3.4.3 onto Jetson TX2.
# You need to flash JetPack 3.3 at 
# https://developer.nvidia.com/embedded/downloads#?search=jetpack first.

WHEREAMI=$PWD

# Repository setup
sudo apt-add-repository universe
sudo apt-get update

# Download dependencies for the desired configuration (copied from JetsonHacks github).
sudo apt-get install -y \
    cmake \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libeigen3-dev \
    libglew-dev \
    libgtk2.0-dev \
    libgtk-3-dev \
    libjasper-dev \
    libjpeg-dev \
    libpng12-dev \
    libpostproc-dev \
    libswscale-dev \
    libtbb-dev \
    libtiff5-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    qt5-default \
    zlib1g-dev \
    pkg-config
    
# Apply patch to a known CUDA GL header error.
echo "Backing up original /usr/local/cuda/include/cuda_gl_interop.h"
sudo mv /usr/local/cuda/include/cuda_gl_interop.h{,.orig}
echo "Adding patched cuda_gl_interop.h"
sudo cp $WHEREAMI/cuda_gl_interop.h /usr/local/cuda/include/cuda_gl_interop.h

# Clean up the OpenGL tegra libs that usually get crushed (copied from JetsonHacks gitbub).
cd /usr/lib/aarch64-linux-gnu/
sudo ln -sf tegra/libGL.so libGL.so

# Python 2.7
sudo apt-get install -y python-dev python-numpy python-py python-pytest
# Python 3.5
sudo apt-get install -y python3-dev python3-numpy python3-py python3-pytest

# GStreamer support
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev 

# Start opencv setup
echo "Creating OpenCV working directory"
mkdir ~/OpenCV
cd ~/OpenCV
echo "Downloading opencv 3.4.3"
curl -o opencv-3.4.3.zip https://github.com/opencv/opencv/archive/3.4.3.zip
unzip opencv-3.4.3.zip
echo "Downloading opencv_contrib 3.4.3"
curl -o opencv_contrib-3.4.3.zip https://github.com/opencv/opencv_contrib/archive/3.4.3.zip
unzip opencv_contrib-3.4.3.zip
cd opencv-3.4.3/
mkdir build
cd build/

# start build/install opencv
echo ""
time cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr/local \
		-D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-3.4.3/modules \
		-D WITH_CUDA=ON \
		-D CUDA_ARCH_BIN="6.2" 
		-D CUDA_ARCH_PTX="" \
		-D ENABLE_FAST_MATH=ON \
		-D CUDA_FAST_MATH=ON \
		-D ENABLE_NEON=ON \
		-D WITH_CUBLAS=ON \
		-D WITH_GSTREAMER=ON \
		-D WITH_GSTREAMER_0_10=OFF \
		-D WITH_LIBV4L=ON \
		-D BUILD_TESTS=OFF \
		-D BUILD_PERF_TESTS=OFF \
		-D BUILD_EXAMPLES=OFF \
		-D WITH_QT=ON \
		-D OPENCV_ENABLE_NONFREE=ON \
		-D WITH_OPENGL=ON ..

if [ $? -eq 0 ] ; then
  echo "CMake configuration make successful"
else
  # Try to make again
  echo "CMake issues " >&2
  echo "Please check the configuration being used"
  exit 1
fi

make -j4
sudo make install



