#! /bin/bash

set -e
set -x

# Install dependencies with yum
dnf install -y zip opencl-headers ocl-icd

CMAKE_FLAGS=" -DENABLE_CUDA=OFF"
# Configure pip to use PyTorch extra-index-url for CPU
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple" > $HOME/.config/pip/pip.conf

if [ "$ACCELERATOR" == "cu118" ]; then
    # Install CUDA 11.8
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-11-8-11.8.0-1 \
        cuda-libraries-11-8-11.8.0-1 \
        cuda-libraries-devel-11-8-11.8.0-1
        
    ln -s cuda-11.8 /usr/local/cuda

    export CUDA_HOME="/usr/local/cuda"
    ARCH_LIST=$(${PYTHON} -c "import torch; print(';'.join([f'{y[0]}.{y[1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    # CMakeLists.txt seems to ignore the CMAKE_CUDA_ARCHITECTURES variable, instead, it is overwritten by TORCH_CUDA_ARCH_LIST
    CMAKE_FLAGS=" -DTORCH_CUDA_ARCH_LIST=${ARCH_LIST}"

    # Configure pip to use PyTorch extra-index-url for CUDA 11.8
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu118
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu118/simple" > $HOME/.config/pip/pip.conf

fi

if [ "$ACCELERATOR" == "cu124" ]; then
    # Install CUDA 12.4
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-12-4-12.4.1-1 \
        cuda-libraries-12-4-12.4.1-1 \
        cuda-libraries-devel-12-4-12.4.1-1

    ln -s cuda-12.4 /usr/local/cuda

    export CUDA_HOME="/usr/local/cuda"
    ARCH_LIST=$(${PYTHON} -c "import torch; print(';'.join([f'{y[0]}.{y[1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))")
    # CMakeLists.txt seems to ignore the CMAKE_CUDA_ARCHITECTURES variable, instead, it is overwritten by TORCH_CUDA_ARCH_LIST
    CMAKE_FLAGS=" -DTORCH_CUDA_ARCH_LIST=${ARCH_LIST}"

    # Configure pip to use PyTorch extra-index-url for CUDA 12.4
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu124
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu124/simple" > $HOME/.config/pip/pip.conf

fi

if [ "$ACCELERATOR" == "hip" ]; then
    # Install HIP 6.2
    dnf install -y https://repo.radeon.com/amdgpu-install/6.2.2/el/8.10/amdgpu-install-6.2.60202-1.el8.noarch.rpm
    dnf install -y rocm-device-libs hip-devel hip-runtime-amd hipcc
fi
