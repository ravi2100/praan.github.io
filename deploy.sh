#!/bin/sh

set -e

# Pull the latest changes
git pull origin main

# Build the Flutter web app
flutter build web

# Clean the docs directory
git clean -fdx docs

# Rename the build output directory to docs
mv build/web docs

# Clean the .git directory from docs
git clean -fdx docs/.git

# Add, commit, and push the changes
git add -f docs
git commit -m "Deploy to GitHub Pages"
git push origin main
