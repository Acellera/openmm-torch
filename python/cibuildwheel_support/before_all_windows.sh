#!/bin/bash

set -e
set -x

# Create pip directory if it doesn't exist
mkdir -p "C:\ProgramData\pip"

# Create pip.ini file with PyTorch CPU index
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu" > "C:\ProgramData\pip\pip.ini"


if [ "$ACCELERATOR" == "cu118" ]; then
    curl --netrc-optional -L -nv -o cuda.exe https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_522.06_windows.exe
    ./cuda.exe -s nvcc_11.8 nvrtc_11.8 nvrtc_dev_11.8 cudart_11.8 cufft_11.8 cufft_dev_11.8 cuda_profiler_api_11.8 nvtx_11.8
    rm cuda.exe
    # Move CUDA folder to a path without spaces
    mv "/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.8" /d/cuda

    # Create pip.ini file with PyTorch CUDA 11.8 index
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu118" > "C:\ProgramData\pip\pip.ini"
    
    pip install openmm-unofficial-cu11
elif [ "$ACCELERATOR" == "cu120" ]; then
    curl --netrc-optional -L -nv -o cuda.exe https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_527.41_windows.exe
    ./cuda.exe -s nvcc_12.0 nvrtc_12.0 nvrtc_dev_12.0 cudart_12.0 cufft_12.0 cufft_dev_12.0 cuda_profiler_api_12.0
    rm cuda.exe
    # Move CUDA folder to a path without spaces
    mv "/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.0" /c/CUDA
    # Create pip.ini file with PyTorch CUDA 12.6 index
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu126" > "C:\ProgramData\pip\pip.ini"

    pip install openmm-unofficial-cu12
elif [ "$ACCELERATOR" == "hip" ]; then
    curl.exe --output HIP.exe --url https://download.amd.com/developer/eula/rocm-hub/AMD-Software-PRO-Edition-24.Q3-Win10-Win11-For-HIP.exe
    ./HIP.exe -install
    rm HIP.exe
    pip install openmm-unofficial-cpu
else
    pip install openmm-unofficial-cpu
fi

# Download and extract OpenCL
curl --netrc-optional -L -nv -o OpenCL-SDK.zip https://github.com/KhronosGroup/OpenCL-SDK/releases/download/v2024.10.24/OpenCL-SDK-v2024.10.24-Win-x64.zip
unzip OpenCL-SDK.zip
OPENCL_PATH="$(pwd)/OpenCL-SDK-v2024.10.24-Win-x64"
 

######################################
# Install dependencies with pip
pip install torch==2.7.1
PYTHONPREFIX=$(python -c 'import site; print(site.getsitepackages()[0])')
SITE_PACKAGES="$PYTHONPREFIX/Lib/site-packages/"

CMAKE_FLAGS="-DENABLE_CUDA=OFF"
if [ "$ACCELERATOR" == "cu118" ] || [ "$ACCELERATOR" == "cu120" ]; then
    ARCH_LIST=$(python -c "import torch; print(';'.join([f'{y[:-1]}.{y[-1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    # CMakeLists.txt seems to ignore the CMAKE_CUDA_ARCHITECTURES variable, instead, it is overwritten by TORCH_CUDA_ARCH_LIST
    ARCH_LIST_FMT=$(python -c "import torch; print(';'.join([y for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")

    export CUDA_PATH="/d/cuda"
    CMAKE_FLAGS="-DTORCH_CUDA_ARCH_LIST=${ARCH_LIST}"
    CMAKE_FLAGS+=" -DCMAKE_CUDA_ARCHITECTURES=${ARCH_LIST_FMT}"
    CMAKE_FLAGS+=" -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_PATH}"
    CMAKE_FLAGS+=" -DCUDA_NVCC_EXECUTABLE=${CUDA_PATH}/bin/nvcc.exe"
    CMAKE_FLAGS+=" -DCMAKE_CUDA_COMPILER=${CUDA_PATH}/bin/nvcc.exe"
    CMAKE_FLAGS+=" -DCUDA_DRIVER_LIBRARY_PATH=${CUDA_PATH}/lib/x64/"
fi

OPENCL_PATH="$(pwd)/OpenCL-SDK-v2024.10.24-Win-x64"

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

echo $CMAKE_FLAGS
export LD_LIBRARY_PATH=/usr/lib/:/usr/local/cuda/targets/x86_64-linux/lib/:$LD_LIBRARY_PATH

cmake .. -G "NMake Makefiles JOM" \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${SITE_PACKAGES} \
    -DUSE_SYSTEM_NVTX=1 \
    -DCMAKE_CXX_COMPILER=cl.exe \
    -DCMAKE_C_COMPILER=cl.exe \
    -DOPENMM_DIR=${SITE_PACKAGES}/openmm \
    -DPYTORCH_DIR=${SITE_PACKAGES}/torch \
    -DTorch_DIR=${SITE_PACKAGES}/torch/share/cmake/Torch \
    -DNN_BUILD_OPENCL_LIB=ON \
    -DOPENCL_INCLUDE_DIR="${OPENCL_PATH}/include" \
    -DOPENCL_LIBRARY="${OPENCL_PATH}/lib/OpenCL.lib" \
    $CMAKE_FLAGS

# Build OpenMMTorch
jom -j 4 install
jom -j 4 PythonInstall

cd ..

cp build/python/setup.py python/
cp build/python/openmmtorch.py python/openmmtorch/
cp build/python/TorchPluginWrapper.cpp python/openmmtorch/
cp -r install/include python/openmmtorch/

# Copy the libraries of openmm
mkdir -p python/openmm/
cp -r install/lib/ python/openmm/