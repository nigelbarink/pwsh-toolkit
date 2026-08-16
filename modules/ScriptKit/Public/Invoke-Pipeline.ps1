function Invoke-Pipeline {
    <#
    .SYNOPSIS
        Chains a sequence of script blocks in a pipeline-like fashion.
    .DESCRIPTION
        Takes an initial value and passes it through each step (script block) in
        order.  Each step receives the previous output as $_.  This lets you compose
        pure PowerShell functions without relying on the shell pipeline when you
        want explicit, readable step-by-step transformation.
    .PARAMETER InputObject
        The initial value to feed into the first step.
    .PARAMETER Steps
        An ordered array of script blocks.  Each receives $_ as its input.
    .EXAMPLE
        Invoke-Pipeline -InputObject $lines -Steps @(
            { $_ | Where-Object { $_ -match 'ERROR' } }
            { $_ | Select-Object -First 10 }
            { $_ | ForEach-Object { $_.ToUpper() } }
        )
    .OUTPUTS
        Whatever the last step produces.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [scriptblock[]] $Steps
    )

    $current = $InputObject
    foreach ($step in $Steps) {
        $current = $current | ForEach-Object -Process $step
    }
    $current
}
