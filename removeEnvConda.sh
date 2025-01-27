#!/bin/bash

# List of environments to exclude from removal
EXCLUDE_ENVS=("base")

# Get the list of all conda environments
ENVS=$(conda env list | awk '{print $1}' | grep -v "^#")

# Loop through each environment and remove it if it's not in the exclude list
for ENV in $ENVS; do
    if [[ ! " ${EXCLUDE_ENVS[@]} " =~ " ${ENV} " ]]; then
        echo "Removing environment: $ENV"
        conda remove --name $ENV --all -y
    else
        echo "Skipping environment: $ENV"
    fi
done

echo "All specified environments have been removed."