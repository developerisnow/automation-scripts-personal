#!/bin/bash
# Add changes and commit
git checkout main
git branch
git log -1
git status
git add .
aicommits


# Check if hotfix version is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <hotfix-version>"
  exit 1
fi

HOTFIX_VERSION=$1

# Specify the SSH key for git operations
# export GIT_SSH_COMMAND="ssh -i ~/.ssh/git"

# Start hotfix
git flow hotfix start $HOTFIX_VERSION

# Add changes and commit
echo "Enter your commit message:"
read COMMIT_MESSAGE
git add .
git commit -m "$COMMIT_MESSAGE"

git branch

git checkout main

# Finish hotfix
git flow hotfix finish "$HOTFIX_VERSION"

# Push changes and tags to origin
git push origin --all && git push origin --tags

# Checkout develop branch
git checkout main

git branch
