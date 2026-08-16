#Requires -Version 5.1
<#
.SYNOPSIS
    One-line description of what this script does.
.DESCRIPTION
    Longer description.  What problem does this solve?  What are the inputs and
    outputs?  Any side-effects or prerequisites?
.PARAMETER InputPath
    Path to the input file or directory.
.PARAMETER OutputPath
    Where to write results. Defaults to the current directory.
.EXAMPLE
    .\basic-script.ps1 -InputPath ./data.csv
.EXAMPLE
    .\basic-script.ps1 -InputPath ./data.csv -OutputPath ./results/ -Verbose
.NOTES
    Author:  Your Name
    Created: YYYY-MM-DD
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string] $InputPath,

    [string] $OutputPath = '.',

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Bootstrap – import ScriptKit from a path relative to this script
# ---------------------------------------------------------------------------
$moduleRoot = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
if (Test-Path $moduleRoot) {
    Import-Module $moduleRoot -Force
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------
Write-Status "Starting $(Split-Path $PSCommandPath -Leaf)..."

try {
    # TODO: replace with your real logic
    $items = Get-Item -Path $InputPath

    Write-Info "Processing: $($items.Name)"

    # Example: do something with each item
    foreach ($item in $items) {
        if ($PSCmdlet.ShouldProcess($item.FullName, 'Process')) {
            Write-Status "  -> $($item.Name)"
            # ... your logic here ...
        }
    }

    Write-Success "Completed successfully."
}
catch {
    Write-ErrorMsg "Fatal error: $_"
    exit 1
}
