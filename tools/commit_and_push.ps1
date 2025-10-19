<#
Helper script to stage, commit, and push changes from the repo root.
Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\commit_and_push.ps1 -Message "Your commit message"
If -Message is omitted, you'll be prompted to enter one.
#>
param(
    [string]$Message
)

function Check-GitInstalled {
    try {
        git --version > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

if (-not (Check-GitInstalled)) {
    Write-Error "Git is not installed or not in PATH.\nInstall Git for Windows: https://git-scm.com/download/win\nOr use GitHub Desktop or VS Code built-in Git."
    exit 1
}

# Ensure script is run from repository folder (script may live in tools/)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

# Show current branch
$branch = git rev-parse --abbrev-ref HEAD
Write-Output "Current branch: $branch"

# Show status
Write-Output "\nWorking tree status (unstaged/staged):"
git status --short

if (-not $Message) {
    $Message = Read-Host "Enter commit message"
}
if (-not $Message) {
    Write-Error "Commit message is required. Aborting."
    exit 1
}

Write-Output "\nStaging all changes..."
git add -A

Write-Output "Committing with message: $Message"
$commit = git commit -m "$Message" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Commit failed: $commit"
    exit $LASTEXITCODE
}

Write-Output "Pushing to origin/$branch..."
$push = git push origin $branch 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed: $push"
    exit $LASTEXITCODE
}

Write-Output "Done. Changes pushed to origin/$branch."