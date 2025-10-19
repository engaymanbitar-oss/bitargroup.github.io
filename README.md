This repository contains a simple static site for BitarGroup.

Developer notes:
- Run quick site checks locally (PowerShell):
	- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\site_test.ps1 -Path index.html`
- Convert images locally (PowerShell):
	- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\convert_images.ps1`

CI workflows:
- `.github/workflows/site-tests.yml` runs quick HTML checks on push/PR
- `.github/workflows/convert-images.yml` can convert JPG files in `cv/` to PNG and commit the results (manual dispatch or on push)

Placeholders: small placeholder PNGs were added under `cv/` to avoid broken image links. Replace them with real optimized images when available.

