#!/bin/sh

# Build the Flutter web app
flutter build web

# Navigate to the build output directory
cd build/web

# Initialize a new Git repository
git init
git add .
git commit -m "Deploy to GitHub Pages"

# Push to the gh-pages branch
git push --force "https://github.com/ravi2100/praan.github.io.git" master:gh-pages

# Clean up
cd ../..
rm -rf build/web
