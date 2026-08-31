$ErrorActionPreference = 'Stop'

node scripts/check_protocol_vectors.mjs
node scripts/check_markdown_links.mjs

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    wsl -e sh scripts/run_sim_wsl.sh
    if ($LASTEXITCODE -ne 0) { throw "WSL simulation failed with exit code $LASTEXITCODE" }
    exit 0
}

throw 'WSL was not found. On Linux or macOS, install Icarus Verilog and run scripts/run_sim.sh directly.'
