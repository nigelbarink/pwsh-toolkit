function Write-Status {
    <#
    .SYNOPSIS
        Writes a neutral status message to the host.
    .DESCRIPTION
        Outputs a styled "[~]" prefix message in cyan. Respects $PSStyle on
        PowerShell 7+ and falls back to -ForegroundColor on Windows PowerShell 5.1.
    .PARAMETER Message
        The status message to display.
    .PARAMETER Timestamp
        When specified, prepends the current time to the message.
    .PARAMETER LogPath
        Optional path to a log file. The message (without color codes) is appended.
    .EXAMPLE
        Write-Status "Connecting to AWS..."
    .EXAMPLE
        Write-Status "Processing..." -Timestamp
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Message,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        $prefix = '[~]'
        $text   = Format-MessageText -Prefix $prefix -Message $Message -Timestamp:$Timestamp

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Cyan)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Cyan
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
