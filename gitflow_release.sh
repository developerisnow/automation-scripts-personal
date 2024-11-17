#!/bin/bash
# Check if release version is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <release-version>"
  exit 1
fi

RELEASE_VERSION=$1

# Checkout main branch and fetch latest changes
git checkout main
git pull origin main

# Start release with Git Flow
git flow release start $RELEASE_VERSION

# Notify user to make necessary changes and commit them
echo "Make necessary changes now, then press enter to continue"
read -p "Press enter to continue"

# Add changes and commit
echo "Enter your commit message for the release:"
read COMMIT_MESSAGE
git add .
git commit -m "$COMMIT_MESSAGE"

# Finish release
git flow release finish "$RELEASE_VERSION"

# Push changes and tags to origin
git push origin --all
git push origin --tags

echo "Release $RELEASE_VERSION finished and pushed to origin."

# Checkout develop branch
git checkout main

git branch
