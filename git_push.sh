#!/bin/bash

# Add changes and commit
git branch
git log -1
git status

# Push changes and tags to origin
git push origin --all && git push origin --tags
git status
git branch
# Checkout develop branch
# git checkout main

# git branch -a
