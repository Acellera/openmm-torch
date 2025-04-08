# Install dependencies with pip
pip install torch openmm==8.2.1rc1
SITE_PACKAGES=$(python -c 'import site; print(site.getsitepackages()[0])')

# Configure build with Cmake
mkdir -p build
mkdir -p install
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENMM_DIR=$SITE_PACKAGES/openmm \
    -DPYTORCH_DIR=$SITE_PACKAGES/torch \
    -DTorch_DIR=$SITE_PACKAGES/torch/share/cmake/Torch \
    -DNN_BUILD_OPENCL_LIB=ON \
    -DOPENCL_INCLUDE_DIR=/usr/include/CL \
    -DOPENCL_LIBRARY=/usr/lib64/libOpenCL.so.1 \
    ${CMAKE_FLAGS}

# Build OpenMM
make -j4 install
make -j4 PythonInstall

cd ..

cp -r build/python/* python/
cp -r install/include python/
cp -r install/lib python/
