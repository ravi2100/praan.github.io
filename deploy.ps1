# Stop on error
$ErrorActionPreference = "Stop"

try {
    Write-Host "Pulling latest changes..."
    git pull origin main

    Write-Host "Cleaning the docs directory..."
    if (Test-Path -Path "docs") {
        Remove-Item -Recurse -Force "docs"
    }

    Write-Host "Building Flutter web app..."
    flutter build web

    Write-Host "Creating docs directory..."
    New-Item -ItemType Directory -Force -Path "docs"

    Write-Host "Copying build output to docs..."
    Copy-Item -Path "build/web/*" -Destination "docs" -Recurse

    Write-Host "Cleaning the .git directory from docs..."
    if (Test-Path -Path "docs/.git") {
        Remove-Item -Recurse -Force "docs/.git"
    }

    Write-Host "Adding, committing, and pushing the changes..."
    git add -f docs
    git commit -m "Deploy to GitHub Pages"
    git push origin main

    Write-Host "Deployment successful!"
}
catch {
    Write-Host "An error occurred during deployment:"
    Write-Host $_
    exit 1
}
