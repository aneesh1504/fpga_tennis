$ErrorActionPreference = 'Stop'

python scripts/build_assets.py --check
if ($LASTEXITCODE -ne 0) { throw "Asset verification failed with exit code $LASTEXITCODE" }

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw 'WSL is required on Windows. On Linux or macOS run sim/video/run_video_tests.sh directly.'
}

wsl -e sh sim/video/run_video_tests.sh
if ($LASTEXITCODE -ne 0) { throw "Video simulation failed with exit code $LASTEXITCODE" }
