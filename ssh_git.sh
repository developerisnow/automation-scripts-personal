#!/bin/bash

# Specify the source and destination paths
SOURCE_PATH=~/.ssh/id_rsa_git
DESTINATION_PATH=~/.ssh/id_rsa

# Copy id_rsa_git to id_rsa
cp $SOURCE_PATH $DESTINATION_PATH

# Specify the source and destination paths for id_rsa.pub
SOURCE_PUB_PATH=~/.ssh/id_rsa_git.pub
DESTINATION_PUB_PATH=~/.ssh/id_rsa.pub

# Copy id_rsa_git.pub to id_rsa.pub
cp $SOURCE_PUB_PATH $DESTINATION_PUB_PATH

echo "SSH GIT keys copied successfully!"