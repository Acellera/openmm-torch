#! /bin/bash

set -e
set -x

# Install dependencies with yum
dnf install -y zip opencl-headers ocl-icd tree

# Check if we are running on aarch64
if [ "$(uname -m)" == "aarch64" ]; then
    dnf install -y gfortran-aarch64-linux-gnu
fi

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
extra-index-url = https://download.pytorch.org/whl/cu118
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu118/simple" > $HOME/.config/pip/pip.conf

elif [ "$ACCELERATOR" == "cu124" ]; then
    # Install CUDA 12.4
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-12-4-12.4.1-1 \
        cuda-libraries-12-4-12.4.1-1 \
        cuda-libraries-devel-12-4-12.4.1-1 \
        cuda-toolkit-12-4-12.4.1-1 \
        gcc-toolset-13

    ln -s cuda-12.4 /usr/local/cuda
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/gcc /usr/local/cuda/bin/gcc
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/g++ /usr/local/cuda/bin/g++
    ln -s /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1

    # Configure pip to use PyTorch extra-index-url for CUDA 12.4
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu124
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu124/simple" > $HOME/.config/pip/pip.conf

elif [ "$ACCELERATOR" == "cu126" ]; then
    # Install CUDA 12.6
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-12-6-12.6.3-1 \
        cuda-libraries-12-6-12.6.3-1 \
        cuda-libraries-devel-12-6-12.6.3-1 \
        cuda-toolkit-12-6-12.6.3-1 \
        gcc-toolset-13

    ln -s cuda-12.6 /usr/local/cuda
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/gcc /usr/local/cuda/bin/gcc
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/g++ /usr/local/cuda/bin/g++
    ln -s /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1

    # Configure pip to use PyTorch extra-index-url for CUDA 12.6
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu126
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu126/simple" > $HOME/.config/pip/pip.conf

elif [ "$ACCELERATOR" == "cu128" ]; then
    # Install CUDA 12.8
    dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

    dnf install --setopt=obsoletes=0 -y \
        cuda-compiler-12-8-12.8.1-1 \
        cuda-libraries-12-8-12.8.1-1 \
        cuda-libraries-devel-12-8-12.8.1-1 \
        cuda-toolkit-12-8-12.8.1-1 \
        gcc-toolset-13

    ln -s cuda-12.8 /usr/local/cuda
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/gcc /usr/local/cuda/bin/gcc
    ln -s /opt/rh/gcc-toolset-13/root/usr/bin/g++ /usr/local/cuda/bin/g++
    ln -s /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/lib/libcuda.so.1

    # Configure pip to use PyTorch extra-index-url for CUDA 12.8
    mkdir -p $HOME/.config/pip
    echo "[global]
extra-index-url = https://download.pytorch.org/whl/cu128
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cu128/simple" > $HOME/.config/pip/pip.conf

elif [ "$ACCELERATOR" == "hip" ]; then
    # Install HIP 6.2
    dnf install -y https://repo.radeon.com/amdgpu-install/6.2.2/el/8.10/amdgpu-install-6.2.60202-1.el8.noarch.rpm
    dnf install -y rocm-device-libs hip-devel hip-runtime-amd hipcc
fi
