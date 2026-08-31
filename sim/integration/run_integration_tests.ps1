$ErrorActionPreference = 'Stop'

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw 'WSL is required on Windows. On Linux or macOS run sim/integration/run_integration_tests.sh directly.'
}

wsl -e sh sim/integration/run_integration_tests.sh
if ($LASTEXITCODE -ne 0) { throw "Integration simulation failed with exit code $LASTEXITCODE" }
