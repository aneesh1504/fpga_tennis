$ErrorActionPreference = 'Stop'

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw 'WSL is required on Windows. On Linux or macOS run sim/game/run_game_tests.sh.'
}

wsl -e sh sim/game/run_game_tests.sh
if ($LASTEXITCODE -ne 0) {
    throw "Gameplay/audio regression failed with exit code $LASTEXITCODE"
}
