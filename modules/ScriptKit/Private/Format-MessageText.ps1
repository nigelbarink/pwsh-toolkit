function Format-MessageText {
    <#
    .SYNOPSIS
        Internal helper – formats a log/display string with optional timestamp.
    #>
    [CmdletBinding()]
    param(
        [string] $Prefix,
        [string] $Message,
        [switch] $Timestamp
    )

    if ($Timestamp) {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        return "$Prefix [$ts] $Message"
    }
    return "$Prefix $Message"
}
