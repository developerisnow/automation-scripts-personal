#!/bin/bash

# Install required Python versions using pyenv
pyenv install 3.8.12
pyenv install 3.10
pyenv install 3.11
pyenv install 3.12

# Set global Python version to 3.11
pyenv global 3.11

echo "Python versions 3.8.12, 3.10, 3.11, and 3.12 have been installed and 3.11 is set as the global version."
