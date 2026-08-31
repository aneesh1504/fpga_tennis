param(
    [ValidateSet('Probe', 'Synthesis', 'All')]
    [string]$Mode = 'All'
)

$ErrorActionPreference = 'Stop'

function Find-VivadoLauncher {
    $command = Get-Command vivado -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $uninstallRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $install = Get-ItemProperty $uninstallRoots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Vivado Design Suite' } |
        Sort-Object DisplayVersion -Descending |
        Select-Object -First 1

    if ($install.InstallLocation -and $install.DisplayVersion) {
        $registeredCandidate = Join-Path $install.InstallLocation "$($install.DisplayVersion)\Vivado\bin\vivado.bat"
        if (Test-Path -LiteralPath $registeredCandidate) {
            return $registeredCandidate
        }
    }

    $patterns = @(
        'C:\AMDDesignTools\*\Vivado\bin\vivado.bat',
        'C:\AMD\Vivado\*\bin\vivado.bat',
        'C:\Xilinx\Vivado\*\bin\vivado.bat'
    )
    foreach ($pattern in $patterns) {
        $candidate = Get-Item $pattern -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    throw 'Vivado was not found on PATH or in a supported registered/default installation location.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$vivado = Find-VivadoLauncher
Write-Output "Vivado launcher: $vivado"

Push-Location $repoRoot
try {
    if ($Mode -in @('Probe', 'All')) {
        & $vivado -mode batch -nolog -nojournal -notrace -source scripts/probe_boolean_board.tcl
        if ($LASTEXITCODE -ne 0) {
            throw "Vivado hardware probe failed with exit code $LASTEXITCODE"
        }
    }

    if ($Mode -in @('Synthesis', 'All')) {
        & $vivado -mode batch -nolog -nojournal -notrace -source scripts/synth_board_b_top_ooc.tcl
        if ($LASTEXITCODE -ne 0) {
            throw "Vivado Board B out-of-context synthesis failed with exit code $LASTEXITCODE"
        }

        & $vivado -mode batch -nolog -nojournal -notrace -source scripts/synth_board_a_system_ooc.tcl
        if ($LASTEXITCODE -ne 0) {
            throw "Vivado Board A out-of-context synthesis failed with exit code $LASTEXITCODE"
        }
    }
} finally {
    Pop-Location
}
