function Add-LogEntry {
    <#
    .SYNOPSIS
        Internal helper – appends a plain-text line to a log file.
    #>
    [CmdletBinding()]
    param(
        [string] $Path,
        [string] $Text
    )

    try {
        Add-Content -Path $Path -Value $Text -Encoding UTF8
    }
    catch {
        Write-Warning "ScriptKit: Could not write to log '$Path': $_"
    }
}
