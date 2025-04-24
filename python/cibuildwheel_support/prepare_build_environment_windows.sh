#!/bin/bash

set -e
set -x

# Create pip directory if it doesn't exist
mkdir -p "C:\ProgramData\pip"

# Create pip.ini file with PyTorch CPU index
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple" > "C:\ProgramData\pip\pip.ini"


if [ "$ACCELERATOR" == "cu118" ]; then
    CUDA_ROOT="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.8"
    curl --netrc-optional -L -nv -o cuda.exe https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_522.06_windows.exe
    ./cuda.exe -s nvcc_11.8 nvrtc_11.8 nvrtc_dev_11.8 cudart_11.8 cufft_11.8 cufft_dev_11.8 cuda_profiler_api_11.8
    rm cuda.exe

    # Create pip.ini file with PyTorch CUDA 11.8 index
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu118
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu118/simple" > "C:\ProgramData\pip\pip.ini"
fi

if [ "$ACCELERATOR" == "cu126" ]; then
    CUDA_ROOT="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.6"
    curl --netrc-optional -L -nv -o cuda.exe https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda_12.6.0_551.61_windows.exe
    ./cuda.exe -s nvcc_12.6 nvrtc_12.6 nvrtc_dev_12.6 cudart_12.6 cufft_12.6 cufft_dev_12.6 cuda_profiler_api_12.6
    rm cuda.exe

    # Create pip.ini file with PyTorch CUDA 12.6 index
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu126
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu126/simple" > "C:\ProgramData\pip\pip.ini"
fi

if [ "$ACCELERATOR" == "cu128" ]; then
    CUDA_ROOT="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8"
    curl --netrc-optional -L -nv -o cuda.exe https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_551.61_windows.exe
    ./cuda.exe -s nvcc_12.8 nvrtc_12.8 nvrtc_dev_12.8 cudart_12.8 cufft_12.8 cufft_dev_12.8 cuda_profiler_api_12.8
    rm cuda.exe

    # Create pip.ini file with PyTorch CUDA 12.8 index
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu128
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu128/simple" > "C:\ProgramData\pip\pip.ini"
fi

if [ "$ACCELERATOR" == "hip" ]; then
    curl.exe --output HIP.exe --url https://download.amd.com/developer/eula/rocm-hub/AMD-Software-PRO-Edition-24.Q3-Win10-Win11-For-HIP.exe
    ./HIP.exe -install
    rm HIP.exe
fi

# Download and extract OpenCL
curl --netrc-optional -L -nv -o OpenCL-SDK.zip https://github.com/KhronosGroup/OpenCL-SDK/releases/download/v2024.10.24/OpenCL-SDK-v2024.10.24-Win-x64.zip
unzip OpenCL-SDK.zip
OPENCL_PATH="$(pwd)/OpenCL-SDK-v2024.10.24-Win-x64"


# Configure build with Cmake
mkdir -p build
mkdir -p openmm-install
cd build
cmake -G "NMake Makefiles JOM" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=openmm-install \
    -DCMAKE_PREFIX_PATH="openmm-install;C:\Program Files\AMD\ROCm\6.1" \
    -DCMAKE_CXX_COMPILER=cl.exe \
    -DCMAKE_C_COMPILER=cl.exe \
    -DOPENCL_INCLUDE_DIR="${OPENCL_PATH}/include" \
    -DOPENCL_LIBRARY="${OPENCL_PATH}/lib/OpenCL.lib" \
    -DHIP_PLATFORM=amd \
    ..

# Build OpenMM
jom -j 4 install
jom -j 4 PythonInstall

cd ..

cp -r build/python/* wrappers/python/
cp -r build/openmm-install/include wrappers/python/openmm/
cp -r build/openmm-install/lib wrappers/python/openmm/
