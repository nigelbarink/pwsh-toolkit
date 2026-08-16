#Requires -Version 5.1
<#
.SYNOPSIS
    Log analysis example – pipeline-style PowerShell.
.DESCRIPTION
    Demonstrates the GNU mindset: read a log file, filter interesting lines,
    group them by severity, and emit structured objects for further processing.

    Usage:
        .\log-analysis.ps1 -LogPath ./app.log
        .\log-analysis.ps1 -LogPath ./app.log | ConvertTo-Json > report.json
        .\log-analysis.ps1 -LogPath ./app.log | Export-Csv report.csv -NoTypeInformation

.PARAMETER LogPath
    Path to a plain-text log file (one entry per line).
.PARAMETER Severity
    Filter to a specific severity level (ERROR, WARN, INFO).  Default: all.
.PARAMETER Tail
    Process only the last N lines of the file.
.EXAMPLE
    .\log-analysis.ps1 -LogPath ./app.log -Severity ERROR
.EXAMPLE
    .\log-analysis.ps1 -LogPath ./app.log -Tail 500 | Group-Object Severity
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string] $LogPath,

    [ValidateSet('ERROR', 'WARN', 'INFO', 'DEBUG')]
    [string] $Severity,

    [int] $Tail = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
if (Test-Path $moduleRoot) { Import-Module $moduleRoot -Force }

# ---------------------------------------------------------------------------
# Step 1 – read
# ---------------------------------------------------------------------------
Write-Status "Reading: $LogPath" -Timestamp

$lines = if ($Tail -gt 0) {
    Get-Content -Path $LogPath -Tail $Tail
}
else {
    Get-Content -Path $LogPath
}

Write-Info "Lines loaded: $($lines.Count)"

# ---------------------------------------------------------------------------
# Step 2 – parse (simple pattern: [TIMESTAMP] [SEVERITY] message)
# ---------------------------------------------------------------------------
$pattern = '^\[(?<ts>[^\]]+)\]\s+\[(?<sev>[A-Z]+)\]\s+(?<msg>.+)$'

$parsed = $lines | ForEach-Object {
    if ($_ -match $pattern) {
        [PSCustomObject]@{
            Timestamp = $Matches['ts']
            Severity  = $Matches['sev']
            Message   = $Matches['msg']
        }
    }
}

Write-Info "Parsed entries: $($parsed.Count)"

# ---------------------------------------------------------------------------
# Step 3 – filter
# ---------------------------------------------------------------------------
$filtered = if ($Severity) {
    $parsed | Where-Object { $_.Severity -eq $Severity }
}
else {
    $parsed
}

# ---------------------------------------------------------------------------
# Step 4 – emit (callers decide what to do with the objects)
# ---------------------------------------------------------------------------
$errorCount = ($filtered | Where-Object Severity -eq 'ERROR').Count
$warnCount  = ($filtered | Where-Object Severity -eq 'WARN').Count

if ($errorCount -gt 0) {
    Write-Warn "Found $errorCount ERROR entries."
}
if ($warnCount -gt 0) {
    Write-Warn "Found $warnCount WARN entries."
}

Write-Success "Analysis complete. Emitting $($filtered.Count) entries."

$filtered   # emit to the pipeline
