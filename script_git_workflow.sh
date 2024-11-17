#!/bin/bash

# Personal Access Token and GitHub Username
GITHUB_TOKEN="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" # Replace with your actual token
GITHUB_USER="web3stealth" # Replace with your GitHub username

# Step 1: Extract the repository name from .git/config BEFORE modifying it
# REPO_NAME=$(grep 'url = https://github.com/' .git/config | sed 's|.*github.com/.*/\(.*\).git|\1|')
REPO_NAME=$(grep 'url = https://' .git/config | sed -E 's|.*\/([^\/]+)\.git|\1|')

# Check if the repository name was correctly extracted
if [ -z "$REPO_NAME" ]; then
    echo "Failed to extract repository name from .git/config."
    exit 1
fi

# Step 2: Modify the URL in .git/config to include the personal access token
sed -i '' "s|https://github.com/.*/${REPO_NAME}.git|https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git|" .git/config

# Step 3: Create a new branch 'dev' and switch to it
git checkout -b dev

# Step 4: Use curl to create a repository on GitHub with your personal access token
JSON_DATA=$(jq -n --arg name "$REPO_NAME" --arg private "true" '{name: $name, private: $private}')
curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Content-Type: application/json" \
     -d "$JSON_DATA" \
     "https://api.github.com/user/repos"

# Check if the repo was created successfully and then set the new remote
if [ $? -eq 0 ]; then
    echo "Repository $REPO_NAME created successfully."
    # Set the new remote URL, which includes the token for authentication
    NEW_REMOTE_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git"
    git remote set-url origin $NEW_REMOTE_URL
else
    echo "Failed to create repository. Check your token permissions and internet connection."
    exit 1
fi

# Step 5: Push all branches to the new origin
git push origin --all
