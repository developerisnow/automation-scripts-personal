#!/bin/bash

# Specify the source and destination paths
SOURCE_PATH=~/.ssh/20231002_mine/id_rsa
DESTINATION_PATH=~/.ssh/id_rsa

# Copy id_rsa_git to id_rsa
cp $SOURCE_PATH $DESTINATION_PATH

# Specify the source and destination paths for id_rsa.pub
SOURCE_PUB_PATH=~/.ssh/20231002_mine/id_rsa.pub
DESTINATION_PUB_PATH=~/.ssh/id_rsa.pub

# Copy id_rsa_git.pub to id_rsa.pub
cp $SOURCE_PUB_PATH $DESTINATION_PUB_PATH

echo "SSH MINE keys copied successfully!"

# Show last 16 characters of the actual key content
echo "Current private key ends with: $(grep -v -- "-----" $DESTINATION_PATH | tr -d '\n' | tail -c 16)"

# Print public key information separately
echo -e "\nPublic key details:"
echo "Label: $(awk '{print $3}' $DESTINATION_PUB_PATH)"
echo -e "Key: $(awk '{print $2}' $DESTINATION_PUB_PATH)\n"
