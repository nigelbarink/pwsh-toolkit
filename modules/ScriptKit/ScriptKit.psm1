#Requires -Version 5.1
<#
.SYNOPSIS
    ScriptKit – shared module entry point.
.DESCRIPTION
    Dot-sources all Public and Private functions, then exports the Public ones.
#>

$Private = Get-ChildItem -Path "$PSScriptRoot/Private" -Filter '*.ps1' -ErrorAction SilentlyContinue
$Public  = Get-ChildItem -Path "$PSScriptRoot/Public"  -Filter '*.ps1' -ErrorAction SilentlyContinue

foreach ($file in @($Private) + @($Public)) {
    try {
        . $file.FullName
    }
    catch {
        Write-Error "Failed to import '$($file.FullName)': $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
