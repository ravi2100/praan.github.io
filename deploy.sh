#!/bin/sh

# Build the Flutter web app
flutter build web

# Remove the old docs directory
rm -rf docs

# Rename the build output directory to docs
mv build/web docs

# Add, commit, and push the changes
git add docs
git commit -m "Deploy to GitHub Pages"
git push origin main
