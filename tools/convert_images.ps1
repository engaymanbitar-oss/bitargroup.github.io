# Converts JPG/JPEG images in the cv/ folder to PNG format and optionally updates HTML references.
#
# Usage:
#   .\tools\convert_images.ps1        # runs in current repo root

param(
    [string]$ImagesDir = "cv",
    [switch]$UpdateHtml
)

try {

# repoRoot is the script folder; project root is its parent
    $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = Resolve-Path (Join-Path $repoRoot "..")
    $imagesPath = Join-Path $projectRoot $ImagesDir
    if (-not (Test-Path $imagesPath)) {
        Write-Output "No '$ImagesDir' directory found in the repo. Nothing to convert."
        exit 0
    }

    $imagesPath = (Resolve-Path $imagesPath).Path
Write-Output "Converting images in: $imagesPath"

$jpgFiles = Get-ChildItem -Path $imagesPath -Include *.jpg, *.jpeg -File -ErrorAction SilentlyContinue
if (-not $jpgFiles) {
    Write-Output "No JPG/JPEG files found in $imagesPath."
    exit 0
}

# Try to load System.Drawing.Common (works on Windows PowerShell if available)
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null

foreach ($f in $jpgFiles) {
    $pngPath = [System.IO.Path]::ChangeExtension($f.FullName, '.png')
    try {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        $img.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $img.Dispose()
        Write-Output "Converted: $($f.Name) -> $(Split-Path $pngPath -Leaf)"
    } catch {
        Write-Warning "Failed to convert $($f.Name): $_"
    }
}

    if ($UpdateHtml) {
    $htmlPath = Join-Path $repoRoot "..\index.html"
    if (Test-Path $htmlPath) {
        $html = Get-Content -Raw -Path $htmlPath -Encoding UTF8
        $updated = $false
        foreach ($jpg in $jpgFiles) {
            $jpgName = $jpg.Name
            $pngName = [System.IO.Path]::ChangeExtension($jpgName, '.png')
            if ($html -match [regex]::Escape($jpgName)) {
                $html = $html -replace [regex]::Escape($jpgName), $pngName
                $updated = $true
                Write-Output "Replaced reference $jpgName -> $pngName in index.html"
            }
        }
        if ($updated) { Set-Content -Path $htmlPath -Value $html -Encoding UTF8; Write-Output "Updated index.html references." }
        else { Write-Output "No references to JPG files found in index.html to update." }
    } else {
        Write-Output "index.html not found to update references."
    }
    }

    Write-Output "Done."
} catch {
    Write-Error "An error occurred during conversion: $_"
    exit 1
}