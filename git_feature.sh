#!/bin/bash

# Check if feature name is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <feature-name>"
  exit 1
fi

FEATURE_NAME=$1

# Start feature
git checkout develop
git pull origin develop
git flow feature start $FEATURE_NAME

echo "You are now on the feature branch: $FEATURE_NAME"
echo "Make necessary changes and when ready, press enter to continue."
read -p "Press enter to continue"

# Add changes and commit
echo "Enter your commit message for this feature:"
read COMMIT_MESSAGE
git add .
git commit -m "$COMMIT_MESSAGE"

# Finish feature
git flow feature finish $FEATURE_NAME

# Push changes to develop
git checkout dev
git push origin dev

echo "Feature $FEATURE_NAME has been merged into develop and pushed to origin."
