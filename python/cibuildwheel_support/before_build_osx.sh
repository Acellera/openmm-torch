#! /bin/bash

set -e
set -x

pip install torch openmm==8.2.1rc1
unset SITE_PACKAGES
SITE_PACKAGES=$(python -c 'import site; print(site.getsitepackages()[0])')

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

CC=/usr/bin/clang
CXX=/usr/bin/clang++
CMAKE_CXX_FLAGS="-mmacosx-version-min=10.7"
CMAKE_SHARED_LINKER_FLAGS="-mmacosx-version-min=10.7"

cmake .. \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENMM_DIR=${SITE_PACKAGES}/openmm \
    -DPYTORCH_DIR=${SITE_PACKAGES}/torch \
    -DTorch_DIR=${SITE_PACKAGES}/torch/share/cmake/Torch \
    -DNN_BUILD_OPENCL_LIB=ON

# Build OpenMMTorch
make -j4 install
make -j4 PythonInstall

cd ..

cp build/python/setup.py python/
cp build/python/openmmtorch.py python/openmmtorch/
cp build/python/TorchPluginWrapper.cpp python/openmmtorch/
cp -r install/include python/openmmtorch/

# Copy the libraries of openmm
mkdir -p python/openmm/
cp -r install/lib python/openmm/lib

# Uninstall the libraries
pip uninstall torch openmm -y