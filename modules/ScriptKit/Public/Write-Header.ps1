function Write-Header {
    <#
    .SYNOPSIS
        Writes a prominent section header to the host.
    .DESCRIPTION
        Outputs a boxed banner line useful for separating major sections in
        long-running scripts.  The width of the box adapts to the message length
        or the terminal width.  Uses $PSStyle on PowerShell 7+ and falls back
        to -ForegroundColor on Windows PowerShell 5.1.
    .PARAMETER Title
        The header text to display.
    .PARAMETER Width
        Total width of the header box.  Defaults to the lesser of the terminal
        width and 80.
    .PARAMETER Timestamp
        When specified, appends the current time to the title.
    .PARAMETER LogPath
        Optional path to a log file.  The plain-text header is appended.
    .EXAMPLE
        Write-Header "Phase 1: Discovery"
    .EXAMPLE
        Write-Header "Deploying to Production" -Timestamp -Width 100
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Title,

        [int] $Width = 0,

        [switch] $Timestamp,

        [string] $LogPath
    )

    process {
        if ($Timestamp) {
            $ts    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $Title = "$Title  [$ts]"
        }

        $termWidth = if ($Width -gt 0) {
            $Width
        }
        elseif ($Host.UI.RawUI.WindowSize.Width -gt 0) {
            [Math]::Min($Host.UI.RawUI.WindowSize.Width, 80)
        }
        else {
            80
        }

        $inner   = " $Title "
        $padLen  = [Math]::Max(0, $termWidth - $inner.Length - 2)
        $padLeft = [Math]::Floor($padLen / 2)
        $padRight= $padLen - $padLeft

        $top    = '#' * $termWidth
        $middle = '#' + (' ' * $padLeft) + $inner + (' ' * $padRight) + '#'
        $bottom = '#' * $termWidth

        $text = "$top`n$middle`n$bottom"

        if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSStyle) {
            Write-Host "$($PSStyle.Foreground.Cyan)$($PSStyle.Bold)${text}$($PSStyle.Reset)"
        }
        else {
            Write-Host $text -ForegroundColor Cyan
        }

        if ($LogPath) { Add-LogEntry -Path $LogPath -Text $text }
    }
}
