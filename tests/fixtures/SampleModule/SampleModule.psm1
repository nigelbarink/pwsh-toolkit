function Get-Greeting {
    param([string]$Name = 'World')
    "Hello, $Name!"
}

function Format-Name {
    param([string]$FirstName, [string]$LastName)
    "$LastName, $FirstName"
}

# Internal helper — should NOT be inlined
function _InternalHelper {
    param([string]$Text)
    $Text.Trim()
}
