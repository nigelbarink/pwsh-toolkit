#Requires -Version 5.1
<#
.SYNOPSIS
    Pipeline filter tool – designed to sit in the middle of a pipeline.
.DESCRIPTION
    Reads objects from the pipeline, applies a transformation or filter, and emits
    results downstream.  Follows the GNU "do one thing well" principle.

    Usage in a pipeline:
        Get-Something | .\pipeline-tool.ps1 | Format-Something

.PARAMETER Pattern
    A regex pattern to filter input strings.
.PARAMETER Property
    When working with objects, the property name to inspect.
.PARAMETER Invert
    Invert the match (like grep -v).
.EXAMPLE
    Get-Content ./app.log | .\pipeline-tool.ps1 -Pattern 'ERROR'
.EXAMPLE
    Get-Process | .\pipeline-tool.ps1 -Property 'Name' -Pattern '^pwsh'
.NOTES
    Author:  Your Name
    Created: YYYY-MM-DD
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]
    [object] $InputObject,

    [Parameter(Mandatory)]
    [string] $Pattern,

    [string] $Property,

    [switch] $Invert
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $regex = [regex]::new($Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

process {
    if ($null -eq $InputObject) { return }

    $value = if ($Property) {
        $InputObject.$Property
    }
    else {
        $InputObject
    }

    $isMatch = $regex.IsMatch([string]$value)

    if ($Invert) { $isMatch = -not $isMatch }

    if ($isMatch) {
        $InputObject   # emit to the pipeline unchanged
    }
}

end {
    # Nothing to clean up; all output was emitted in process{}
}
