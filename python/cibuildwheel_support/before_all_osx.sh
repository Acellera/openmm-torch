#! /bin/bash

set -e
set -x
  
brew install swig tree

# Configure pip to use PyTorch extra-index-url for CPU
mkdir -p $HOME/.config/pip
echo "[global]
extra-index-url = https://download.pytorch.org/whl/cpu
                  https://us-central1-python.pkg.dev/pypi-packages-455608/cpu/simple" > $HOME/.config/pip/pip.conf

cp python/setup.py $HOME/setup.py.bkp