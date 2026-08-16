function Write-Warn {
    <#
    .SYNOPSIS
        Writes a warning message to the host.
    .DESCRIPTION
        Outputs a styled "[!]" prefix message in yellow. Respects $PSStyle on
        PowerShell 7+ and falls back to -ForegroundColor on Windows PowerShell 5.1.
        Uses Write-Host (not Write-Warning) to keep output on stdout for pipelines.
    .PARAMETER Message
        The warning message to display.
    .PARAMETER Timestamp
        When specified, prepends the current time to the message.
    .PARAMETER LogPath
        Optional path to a log file. The message (without color codes) is appended.
    .EXAMPLE
        Write-Warn "Region not specified; defaulting to us-east-1."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Message,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        $prefix = '[!]'
        $text   = Format-MessageText -Prefix $prefix -Message $Message -Timestamp:$Timestamp

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Yellow)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Yellow
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
