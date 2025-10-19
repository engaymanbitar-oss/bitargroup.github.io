<#
Simple site tests for a static HTML file (PowerShell version).

Checks:
- <title> exists and non-empty
- meta viewport present
- <html> has lang attribute
- <link rel="canonical"> present
- all <img> tags have non-empty alt attributes
- internal anchor hrefs (href="#id") point to existing id attributes

Usage: .\tools\site_test.ps1 -Path .\index.html
#>

param(
    [string]$Path = "index.html"
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 2
}

$text = Get-Content -Raw -Encoding UTF8 -Path $Path
$failures = @()

function Find-Regex($pattern) {
    $opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
    return [System.Text.RegularExpressions.Regex]::Match($text, $pattern, $opts)
}

# Title
if ($text -match "<title\s*>(.*?)</title>") {
    $titleVal = $matches[1].Trim()
    if ([string]::IsNullOrWhiteSpace($titleVal)) { $failures += 'Missing or empty title' } else { Write-Output "Title: $titleVal" }
} else {
    $failures += 'Missing or empty title'
}

# Meta viewport (simple check for presence of the word 'viewport' in a meta tag)
if ($text -notmatch '<meta[^>]*viewport') { $failures += 'Missing meta viewport' }

# html lang — extract the <html> tag first, then look for lang attribute inside it
$htmlTagMatch = [System.Text.RegularExpressions.Regex]::Match($text, '<html\b[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($htmlTagMatch.Success) {
    $htmlTag = $htmlTagMatch.Value
    $langMatch = [System.Text.RegularExpressions.Regex]::Match($htmlTag, 'lang\s*=\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $langMatch.Success) {
        $langMatch = [System.Text.RegularExpressions.Regex]::Match($htmlTag, "lang\s*=\s*'([^']+)'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    if ($langMatch.Success) {
        Write-Output "HTML lang: $($langMatch.Groups[1].Value)"
    } else {
        $failures += 'Missing lang attribute on html element'
    }
} else {
    $failures += 'Missing html element'
}

# canonical
if ($text -notmatch '<link[^>]*rel[^>]*canonical') { $failures += 'Missing link rel=canonical' }

# Images
$imgTags = [System.Text.RegularExpressions.Regex]::Matches($text, '<img\b[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Value }
$imgNoAlt = @()
$imgEmptyAlt = @()
foreach ($img in $imgTags) {
    $alt1 = [System.Text.RegularExpressions.Regex]::Match($img, 'alt\s*=\s*"([^"]*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $alt2 = [System.Text.RegularExpressions.Regex]::Match($img, "alt\s*=\s*'([^']*)'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $alt1.Success -and -not $alt2.Success) {
        $imgNoAlt += $img
    } elseif ($alt1.Success -and [string]::IsNullOrWhiteSpace($alt1.Groups[1].Value)) {
        $imgEmptyAlt += $img
    } elseif ($alt2.Success -and [string]::IsNullOrWhiteSpace($alt2.Groups[1].Value)) {
        $imgEmptyAlt += $img
    }
}
if ($imgNoAlt.Count -gt 0) { $failures += "$($imgNoAlt.Count) image(s) missing alt attribute" }
if ($imgEmptyAlt.Count -gt 0) { $failures += "$($imgEmptyAlt.Count) image(s) with empty alt" }

# Internal links
     # Internal links: collect href="#id" from double-quoted and single-quoted variants
     $internalTargets = @()
     $m1 = [System.Text.RegularExpressions.Regex]::Matches($text, 'href\s*=\s*"#([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
     foreach ($mm in $m1) { $internalTargets += $mm.Groups[1].Value }
     $m2 = [System.Text.RegularExpressions.Regex]::Matches($text, "href\s*=\s*'#([^']+)'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
     foreach ($mm in $m2) { $internalTargets += $mm.Groups[1].Value }

     # IDs: collect id="x" and id='x'
     $ids = @()
     $i1 = [System.Text.RegularExpressions.Regex]::Matches($text, 'id\s*=\s*"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
     foreach ($ii in $i1) { $ids += $ii.Groups[1].Value }
     $i2 = [System.Text.RegularExpressions.Regex]::Matches($text, "id\s*=\s*'([^']+)'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
     foreach ($ii in $i2) { $ids += $ii.Groups[1].Value }

     $broken = @()
     foreach ($t in $internalTargets) { if ($ids -notcontains $t) { $broken += $t } }
     if ($broken.Count -gt 0) { $failures += "$($broken.Count) internal link(s) target missing id: $([string]::Join(', ', $broken))" }

Write-Output "`nChecks run: title, viewport, lang, canonical, img alt, internal links`n"
if ($failures.Count -gt 0) {
    Write-Output "FAILURES:"
    $failures | ForEach-Object { Write-Output " - $_" }
    Write-Output "`nResult: FAIL"
    exit 1
} else {
    Write-Output "Result: PASS"
    exit 0
}
