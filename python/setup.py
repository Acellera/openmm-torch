from setuptools import setup, Extension
import os
import platform

version = '@OPENMM_TORCH_VERSION@'
openmm_dir = '@OPENMM_DIR@'
torch_include_dirs = '@TORCH_INCLUDE_DIRS@'.split(';')
nn_plugin_header_dir = '@NN_PLUGIN_HEADER_DIR@'
nn_plugin_library_dir = '@NN_PLUGIN_LIBRARY_DIR@'
torch_dir, _ = os.path.split('@TORCH_LIBRARY@')

def _replace_name(name):
    import pathlib
    
    pyproject_path = pathlib.Path(__file__).parent / "pyproject.toml"
    with open(pyproject_path, 'r') as f:
        pyproject_text = f.read()
    pyproject_text = pyproject_text.replace("PLACEHOLDER", name)
    with open(pyproject_path, 'w') as f:
        f.write(pyproject_text)

if os.getenv("ACCELERATOR", "").startswith("cpu"):
    _replace_name("openmm-torch-unofficial-cpu")
if os.getenv("ACCELERATOR", "").startswith("cu"):
    cuda_ver = os.getenv("ACCELERATOR", "")[2:4]
    _replace_name(f"openmm-torch-unofficial-cu{cuda_ver}")

extra_compile_args = ['-std=c++17', '-D_GLIBCXX_USE_CXX11_ABI=0']
extra_link_args = []
libraries = ['OpenMM', 'OpenMMTorch', 'c10', 'torch', 'torch_cpu', 'torch_python']
extra_deps = []
if os.environ.get("ACCELERATOR", "").startswith("cu"):
    libraries += ['c10_cuda', 'torch_cuda']
    cuda_ver = os.getenv("ACCELERATOR", "")[2:4]
    extra_deps = [f'nvidia-cuda-runtime-cu{cuda_ver}']

runtime_library_dirs = ["$ORIGIN/../openmm/lib", "$ORIGIN/../torch/lib"]

# For Windows change the compiler flag to /std:c++17
if platform.system() == 'Windows':
    extra_compile_args = ['/std:c++17']
    runtime_library_dirs = None

# setup extra compile and link arguments on Mac
if platform.system() == 'Darwin':
    extra_compile_args += ['-stdlib=libc++', '-mmacosx-version-min=10.13']
    extra_link_args += ['-stdlib=libc++', '-mmacosx-version-min=10.13']
    runtime_library_dirs = ['@loader_path/../openmm/lib', '@loader_path/../torch/lib']

extension = Extension(name='openmmtorch._openmmtorch',
                      sources=['openmmtorch/TorchPluginWrapper.cpp'],
                      libraries=libraries,
                      include_dirs=[os.path.join(openmm_dir, 'include'), nn_plugin_header_dir] + torch_include_dirs,
                      library_dirs=[os.path.join(openmm_dir, 'lib'), nn_plugin_library_dir, torch_dir],
                      runtime_library_dirs=runtime_library_dirs,
                      extra_compile_args=extra_compile_args,
                      extra_link_args=extra_link_args
                     )

setup(
      version=version,
      py_modules=['openmmtorch'],
      ext_modules=[extension],
      install_requires=extra_deps
     )
