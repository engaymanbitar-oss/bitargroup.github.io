# Deploy script for BitarGroup website
# Usage: Run this from PowerShell as administrator or normal user with Git installed.
# It will initialize a repo (if missing), add files, commit, and push to the provided remote.

param(
    [string]$remoteUrl = 'https://github.com/engaymanbitar-oss/bitargroup.github.io.git',
    [string]$branch = 'main'
)

function Check-Git {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Error "Git is not installed or not in PATH. Please install Git: https://git-scm.com/downloads"
        exit 1
    }
}

Check-Git

Set-Location -Path "${env:USERPROFILE}\OneDrive\Desktop"

if (-not (Test-Path .git)) {
    git init
    Write-Host "Initialized new git repository"
}

git add .

git commit -m "Deploy: update site" -a 2>$null

# set remote if not set or different
$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    git remote add origin $remoteUrl
    Write-Host "Added remote origin: $remoteUrl"
} elseif ($existing -ne $remoteUrl) {
    git remote set-url origin $remoteUrl
    Write-Host "Updated remote origin to: $remoteUrl"
}

# Ensure branch exists
git branch -M $branch

# Push
Write-Host "Pushing to $remoteUrl (branch: $branch) ..."

try {
    git push -u origin $branch
    Write-Host "Push complete. If this is a Pages repo, enable Pages in repository Settings."
} catch {
    Write-Error "Push failed. Please check authentication and remote URL. If you use 2FA, use a personal access token (PAT)."
}
