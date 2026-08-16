function Write-ErrorMsg {
    <#
    .SYNOPSIS
        Writes an error message to the host.
    .DESCRIPTION
        Outputs a styled "[x]" prefix message in red. Uses Write-Host (not
        Write-Error) so the message appears on stdout and pipelines are not broken.
        Respects $PSStyle on PowerShell 7+ and falls back to -ForegroundColor.
    .PARAMETER Message
        The error message to display.
    .PARAMETER Timestamp
        When specified, prepends the current time to the message.
    .PARAMETER LogPath
        Optional path to a log file. The message (without color codes) is appended.
    .EXAMPLE
        Write-ErrorMsg "Failed to assume IAM role."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Message,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        $prefix = '[x]'
        $text   = Format-MessageText -Prefix $prefix -Message $Message -Timestamp:$Timestamp

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Red)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Red
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
