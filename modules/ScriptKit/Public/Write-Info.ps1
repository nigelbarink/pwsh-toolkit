function Write-Info {
    <#
    .SYNOPSIS
        Writes an informational message to the host.
    .DESCRIPTION
        Outputs a styled "[i]" prefix message in blue. Intended for verbose context
        that the user may want to see but that is not a warning or error.
        Respects $PSStyle on PowerShell 7+ and falls back to -ForegroundColor.
    .PARAMETER Message
        The informational message to display.
    .PARAMETER Timestamp
        When specified, prepends the current time to the message.
    .PARAMETER LogPath
        Optional path to a log file. The message (without color codes) is appended.
    .EXAMPLE
        Write-Info "Using profile: dev-account"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Message,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        $prefix = '[i]'
        $text   = Format-MessageText -Prefix $prefix -Message $Message -Timestamp:$Timestamp

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Blue)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Blue
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
