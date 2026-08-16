function Write-Success {
    <#
    .SYNOPSIS
        Writes a success message to the host.
    .DESCRIPTION
        Outputs a styled "[+]" prefix message in green. Respects $PSStyle on
        PowerShell 7+ and falls back to -ForegroundColor on Windows PowerShell 5.1.
    .PARAMETER Message
        The success message to display.
    .PARAMETER Timestamp
        When specified, prepends the current time to the message.
    .PARAMETER LogPath
        Optional path to a log file. The message (without color codes) is appended.
    .EXAMPLE
        Write-Success "Deployment complete."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Message,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        $prefix = '[+]'
        $text   = Format-MessageText -Prefix $prefix -Message $Message -Timestamp:$Timestamp

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Green)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Green
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
