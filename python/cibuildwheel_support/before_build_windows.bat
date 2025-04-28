@echo on
setlocal enabledelayedexpansion

:: Install dependencies with pip
pip install torch openmm==8.2.1rc1
for /f "tokens=*" %%i in ('python -c "import site; print(site.getsitepackages()[0])"') do set PYTHONPREFIX=%%i
set SITE_PACKAGES=%PYTHONPREFIX%\Lib\site-packages

:: Set CUDA paths based on accelerator
if "%ACCELERATOR%"=="cu118" (
    set "CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
) else if "%ACCELERATOR%"=="cu126" (
    set "CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6"
) else if "%ACCELERATOR%"=="cu128" (
    set "CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
)
set CUDA_PATH=%CUDA_HOME%

:: Configure CUDA architecture flags if using CUDA
if "%ACCELERATOR%"=="cu118" (
    for /f "tokens=*" %%i in ('python -c "import torch; print(';'.join([f'{y[:-1]}.{y[-1]}' for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))"') do set ARCH_LIST=%%i
    for /f "tokens=*" %%i in ('python -c "import torch; print(';'.join([y for y in [x[3:] for x in torch._C._cuda_getArchFlags().split() if x.startswith('sm_')]]))"') do set ARCH_LIST_FMT=%%i
    
    set CMAKE_FLAGS=-DTORCH_CUDA_ARCH_LIST=%ARCH_LIST%
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DCMAKE_CUDA_ARCHITECTURES=%ARCH_LIST_FMT%
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DCUDA_TOOLKIT_ROOT_DIR="%CUDA_HOME%"
    set CMAKE_FLAGS=!CMAKE_FLAGS! -DCMAKE_CUDA_COMPILER="%CUDA_HOME%\bin\nvcc.exe"
)

:: Set OpenCL path
set OPENCL_PATH=%CD%\OpenCL-SDK-v2024.10.24-Win-x64

:: Create build and install directories
if not exist build mkdir build
if not exist install mkdir install
cd build

echo %CMAKE_FLAGS%

:: Configure build with CMake
cmake .. -G "NMake Makefiles JOM" ^
    -DCMAKE_INSTALL_PREFIX=../install ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH=%SITE_PACKAGES% ^
    -DCUDA_DRIVER_LIBRARY_PATH=%PYTHONPREFIX%/Library/lib/ ^
    -DUSE_SYSTEM_NVTX=1 ^
    -DCMAKE_CXX_COMPILER=cl.exe ^
    -DCMAKE_C_COMPILER=cl.exe ^
    -DOPENMM_DIR=%SITE_PACKAGES%/openmm ^
    -DPYTORCH_DIR=%SITE_PACKAGES%/torch ^
    -DTorch_DIR=%SITE_PACKAGES%/torch/share/cmake/Torch ^
    -DNN_BUILD_OPENCL_LIB=ON ^
    -DOPENCL_INCLUDE_DIR="%OPENCL_PATH%\include" ^
    -DOPENCL_LIBRARY="%OPENCL_PATH%\lib\OpenCL.lib" ^
    %CMAKE_FLAGS%

:: Build OpenMMTorch
jom -j 4 install
jom -j 4 PythonInstall

cd ..

:: Copy files
copy build\python\setup.py python\
copy build\python\openmmtorch.py python\openmmtorch\
copy build\python\TorchPluginWrapper.cpp python\openmmtorch\
xcopy /E /I install\include python\openmmtorch\include

:: Copy the libraries of openmm
if not exist python\openmm mkdir python\openmm
xcopy /E /I install\lib python\openmm\lib

endlocal