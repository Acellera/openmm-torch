#! /bin/bash

set -e
set -x
  
# Install an older MacOS SDK
# This should guarantee OpenMM builds with extended compatibility across MacOS versions
# Adapted from conda-forge-ci-setup scripts:
# * https://github.com/conda-forge/conda-forge-ci-setup-feedstock/blob/dde296e/recipe/run_conda_forge_build_setup_osx
# * https://github.com/conda-forge/conda-forge-ci-setup-feedstock/blob/dde296e/recipe/download_osx_sdk.sh
#
# Some possible updates might involve upgrading the download link to future MacOS releases (10.15 to something else),
# depending on the version provided by the CI

OSX_SDK_DIR="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs"
export MACOSX_DEPLOYMENT_TARGET=10.9
export MACOSX_SDK_VERSION=10.9

export CMAKE_OSX_SYSROOT="${OSX_SDK_DIR}/MacOSX${MACOSX_SDK_VERSION}.sdk"

if [[ ! -d ${CMAKE_OSX_SYSROOT}} ]]; then
    echo "Downloading ${MACOSX_SDK_VERSION} sdk"
    curl -L -O --connect-timeout 5 --max-time 10 --retry 5  --retry-delay 0 --retry-max-time 40 --retry-connrefused --retry-all-errors \
        https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz
    tar -xf MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz -C "$(dirname ${CMAKE_OSX_SYSROOT})"
fi

if [[ "$MACOSX_DEPLOYMENT_TARGET" == 10.* ]]; then
# set minimum sdk version to our target
plutil -replace MinimumSDKVersion -string ${MACOSX_SDK_VERSION} $(xcode-select -p)/Platforms/MacOSX.platform/Info.plist
plutil -replace DTSDKName -string macosx${MACOSX_SDK_VERSION}internal $(xcode-select -p)/Platforms/MacOSX.platform/Info.plist
fi

########################################
brew install swig tree

# Configure pip to use PyTorch extra-index-url for CPU
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple" > $HOME/.config/pip/pip.conf

#################
pip install torch openmm==8.2.1rc1
SITE_PACKAGES=$(python -c 'import site; print(site.getsitepackages()[0])')

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

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