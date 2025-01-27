#!/bin/bash

# Create logs directory if it doesn't exist
mkdir -p ./logs

# Set log file name with current date and time
log_file="./logs/python-$(date +%Y-%m-%d_%H-%M).log"

# Function to run command and log output
run_and_log() {
    echo "=== $1 ===" | tee -a "$log_file"
    eval "$2" 2>&1 | tee -a "$log_file"
    echo "" | tee -a "$log_file"
}

# Python and package managers
run_and_log "Python Version" "python --version"
run_and_log "Pip Version" "pip --version"
run_and_log "Pip List" "pip list"

# Pyenv
run_and_log "Pyenv Version" "pyenv --version"
run_and_log "Pyenv Versions" "pyenv versions"
run_and_log "All Pyenv Installed Versions" "ls -1 $(pyenv root)/versions"

# Poetry
run_and_log "Poetry Version" "poetry --version"
run_and_log "Poetry Environment Info" "poetry env info"
run_and_log "Global Poetry Installations" "ls -1 $HOME/.poetry/lib/poetry/_vendor/py*"

# Pipx
run_and_log "Pipx Version" "pipx --version"
run_and_log "Pipx List" "pipx list"

# Virtual Environments
run_and_log "Virtualenv Version" "virtualenv --version"
run_and_log "Current Virtual Environment" "echo \$VIRTUAL_ENV"

# System-wide Python installations
run_and_log "System Python Versions" "ls -1 /usr/local/bin/python* 2>/dev/null"

# Local project check
if [ -f "pyproject.toml" ]; then
    run_and_log "Local Poetry Project" "poetry show --tree"
fi

# Conda (if installed)
if command -v conda &> /dev/null; then
    run_and_log "Conda Version" "conda --version"
    run_and_log "Conda Environments" "conda env list"
fi

echo "Review complete. Log file saved to: $log_file"