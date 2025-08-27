#! /bin/bash

set -e
set -x

# Install dependencies with yum
dnf install -y zip opencl-headers ocl-icd tree

# Check if we are running on aarch64
if [ "$(uname -m)" == "aarch64" ]; then
    dnf install -y libgfortran
    ln -s /usr/lib64/libgfortran.so.5.0.0 /usr/lib64/libgfortran-0b50f350.so.5.0.0
fi

# Configure pip to use PyTorch extra-index-url for CPU
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu" > $HOME/.config/pip/pip.conf

if [ "$ACCELERATOR" == "cu118" ]; then
    # Install CUDA 11.8
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-11-8-11.8.0-1 \
        cuda-libraries-11-8-11.8.0-1 \
        cuda-libraries-devel-11-8-11.8.0-1 \
        cuda-toolkit-11-8-11.8.0-1 \
        gcc-toolset-11
        
    ln -s cuda-11.8 /usr/local/cuda
    ln -s /opt/rh/gcc-toolset-11/root/usr/bin/gcc /usr/local/cuda/bin/gcc
    ln -s /opt/rh/gcc-toolset-11/root/usr/bin/g++ /usr/local/cuda/bin/g++
    ln -s /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1

    # Configure pip to use PyTorch extra-index-url for CUDA 11.8
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu118" > $HOME/.config/pip/pip.conf

    pip install openmm-unofficial-cu11
elif [ "$ACCELERATOR" == "cu120" ]; then
    # Install CUDA 12.0
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-12-0-12.0.1-1 \
        cuda-libraries-12-0-12.0.1-1 \
        cuda-libraries-devel-12-0-12.0.1-1 \
        cuda-toolkit-12-0-12.0.1-1 \
        gcc-toolset-11

    ln -s cuda-12.0 /usr/local/cuda
    ln -s /opt/rh/gcc-toolset-11/root/usr/bin/gcc /usr/local/cuda/bin/gcc
    ln -s /opt/rh/gcc-toolset-11/root/usr/bin/g++ /usr/local/cuda/bin/g++
    ln -s /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1

    # Configure pip to use PyTorch extra-index-url for CUDA 12.6
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu124" > $HOME/.config/pip/pip.conf

    pip install openmm-unofficial-cu12
elif [ "$ACCELERATOR" == "hip" ]; then
    # Install HIP 6.2
    dnf install -y https://repo.radeon.com/amdgpu-install/6.2.2/el/8.10/amdgpu-install-6.2.60202-1.el8.noarch.rpm
    dnf install -y rocm-device-libs hip-devel hip-runtime-amd hipcc
    pip install openmm-unofficial-cpu
else
    pip install openmm-unofficial-cpu
fi

#################
pip install torch==2.6.0
SITE_PACKAGES=$(python -c 'import site; print(site.getsitepackages()[0])')

CMAKE_FLAGS=""
if [ "$ACCELERATOR" == "cu118" ] || [ "$ACCELERATOR" == "cu120" ]; then
    ARCH_LIST=$(python -c "import torch; print(';'.join([f'{y[:-1]}.{y[-1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    # CMakeLists.txt seems to ignore the CMAKE_CUDA_ARCHITECTURES variable, instead, it is overwritten by TORCH_CUDA_ARCH_LIST
    ARCH_LIST_FMT=$(python -c "import torch; print(';'.join([y for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    export CUDA_HOME="/usr/local/cuda"
    CMAKE_FLAGS="    -DTORCH_CUDA_ARCH_LIST=${ARCH_LIST}"
    CMAKE_FLAGS+="    -DCMAKE_CUDA_ARCHITECTURES=${ARCH_LIST_FMT}"
    CMAKE_FLAGS+="    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_HOME}"
    CMAKE_FLAGS+="    -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc"
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CMAKE_FLAGS+=" -DOPENCL_INCLUDE_DIR=/usr/include/CL"
    CMAKE_FLAGS+=" -DOPENCL_LIBRARY=/usr/lib64/libOpenCL.so.1"
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
    ${CMAKE_FLAGS}

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