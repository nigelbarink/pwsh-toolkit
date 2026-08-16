#Requires -Version 5.1
<#
.SYNOPSIS
    Composition example – shows how small tools chain together.
.DESCRIPTION
    Demonstrates the GNU mindset applied to PowerShell:
    each step in the pipeline does one thing, and results compose naturally.

    This example simulates a mini log-processing pipeline entirely in memory,
    showing how to use ScriptKit's Invoke-Pipeline for explicit chaining.

.EXAMPLE
    .\compose-tools.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
if (Test-Path $moduleRoot) { Import-Module $moduleRoot -Force }

# ---------------------------------------------------------------------------
# Simulated data – in a real script this would come from Get-Content, AWS, etc.
# ---------------------------------------------------------------------------
$rawLines = @(
    '[2024-08-01 09:00:01] [INFO]  Application started'
    '[2024-08-01 09:00:05] [INFO]  Listening on port 8080'
    '[2024-08-01 09:01:12] [WARN]  Memory usage above 80%'
    '[2024-08-01 09:02:34] [ERROR] Database connection timeout'
    '[2024-08-01 09:03:01] [INFO]  Retrying connection...'
    '[2024-08-01 09:03:05] [ERROR] Max retries exceeded'
    '[2024-08-01 09:03:06] [ERROR] Service shutting down'
)

# ---------------------------------------------------------------------------
# Step definitions – each is a focused, testable script block
# ---------------------------------------------------------------------------
$parseLines = {
    $_ | ForEach-Object {
        if ($_ -match '^\[(?<ts>[^\]]+)\]\s+\[(?<sev>[A-Z]+)\]\s+(?<msg>.+)$') {
            [PSCustomObject]@{
                Timestamp = $Matches['ts']
                Severity  = $Matches['sev']
                Message   = $Matches['msg']
            }
        }
    }
}

$filterErrors = {
    $_ | Where-Object { $_.Severity -in @('ERROR', 'WARN') }
}

$formatReport = {
    $_ | Select-Object Timestamp, Severity, Message
}

# ---------------------------------------------------------------------------
# Compose with Invoke-Pipeline (explicit, readable chain)
# ---------------------------------------------------------------------------
Write-Status "Running pipeline composition example..."

$report = Invoke-Pipeline -InputObject $rawLines -Steps @(
    $parseLines
    $filterErrors
    $formatReport
)

Write-Success "Pipeline complete. $($report.Count) issues found:"

# Output as a table – this is the final sink, not part of the pipeline
$report | Format-Table -AutoSize

# ---------------------------------------------------------------------------
# Alternative: native PowerShell pipeline (preferred for production)
# ---------------------------------------------------------------------------
Write-Info "Same result via native pipeline:"

$rawLines |
    ForEach-Object -Process $parseLines |
    ForEach-Object -Process $filterErrors |
    Format-Table Timestamp, Severity, Message -AutoSize
