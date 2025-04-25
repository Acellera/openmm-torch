#! /bin/bash

set -e
set -x

# Install dependencies with pip
pip install torch openmm==8.2.1rc1
SITE_PACKAGES=$(python -c 'import site; print(site.getsitepackages()[0])')

if [ "$ACCELERATOR" == "cu118" ] || [ "$ACCELERATOR" == "cu126" ] || [ "$ACCELERATOR" == "cu128" ]; then
    ARCH_LIST=$(python -c "import torch; print(';'.join([f'{y[0]}.{y[1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    # CMakeLists.txt seems to ignore the CMAKE_CUDA_ARCHITECTURES variable, instead, it is overwritten by TORCH_CUDA_ARCH_LIST
    ARCH_LIST_FMT=$(python -c "import torch; print(';'.join([f'{y[0]}{y[1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    CMAKE_FLAGS="    -DTORCH_CUDA_ARCH_LIST=${ARCH_LIST}"
    CMAKE_FLAGS+="    -DCMAKE_CUDA_ARCHITECTURES=${ARCH_LIST_FMT}"
    CMAKE_FLAGS+="    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME}"
    CMAKE_FLAGS+="    -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc"
fi

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

echo $CMAKE_FLAGS
export LD_LIBRARY_PATH=/usr/lib/:/usr/local/cuda/targets/x86_64-linux/lib/:$LD_LIBRARY_PATH

cmake .. \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENMM_DIR=${SITE_PACKAGES}/openmm \
    -DPYTORCH_DIR=${SITE_PACKAGES}/torch \
    -DTorch_DIR=${SITE_PACKAGES}/torch/share/cmake/Torch \
    -DNN_BUILD_OPENCL_LIB=ON \
    -DOPENCL_INCLUDE_DIR=/usr/include/CL \
    -DOPENCL_LIBRARY=/usr/lib64/libOpenCL.so.1 \
    ${CMAKE_FLAGS}

# Build OpenMM
make -j4 install
make -j4 PythonInstall

cd ..

cp build/python/setup.py python/
cp build/python/openmmtorch.py python/openmmtorch/
cp build/python/TorchPluginWrapper.cpp python/openmmtorch/
cp -r install/include python/openmmtorch/

# Copy the libraries of openmm
mkdir -p python/openmm/
cp -r install/lib/ python/openmm/
