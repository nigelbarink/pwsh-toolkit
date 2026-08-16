function Get-Greeting {
    <#
    .SYNOPSIS
        Returns a greeting string for the given name.
    #>
    param([string]$Name = 'World')
    "Hello, $Name!"
}

function Format-Name {
    <#
    .SYNOPSIS
        Formats a name as 'LastName, FirstName'.
    #>
    param([string]$FirstName, [string]$LastName)
    "$LastName, $FirstName"
}

# Internal helper — should NOT be inlined
function _InternalHelper {
    <#
    .SYNOPSIS
        Internal helper that trims whitespace from text.
    #>
    param([string]$Text)
    $Text.Trim()
}
