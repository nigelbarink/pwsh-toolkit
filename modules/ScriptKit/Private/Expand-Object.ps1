function Expand-Object {
    <#
    .SYNOPSIS
        Internal recursive helper for ConvertTo-FlatObject.
    #>
    [CmdletBinding()]
    param(
        [object]     $InputObject,
        [string]     $Prefix,
        [System.Collections.IDictionary]  $Target,
        [string]     $Separator,
        [int]        $Depth,
        [int]        $MaxDepth
    )

    if ($null -eq $InputObject -or $Depth -ge $MaxDepth) {
        $key = if ($Prefix) { $Prefix } else { 'Value' }
        $Target[$key] = $InputObject
        return
    }

    $type = $InputObject.GetType()

    # Primitive or string – store directly
    if ($type.IsPrimitive -or $InputObject -is [string] -or $InputObject -is [datetime] -or $InputObject -is [enum]) {
        $key = if ($Prefix) { $Prefix } else { 'Value' }
        $Target[$key] = $InputObject
        return
    }

    # Array / list
    if ($InputObject -is [System.Collections.IEnumerable]) {
        $items = @($InputObject)
        if ($items.Count -eq 0) {
            if ($Prefix) { $Target[$Prefix] = $null }
            return
        }

        $firstType = $items[0].GetType()
        if ($firstType.IsPrimitive -or $items[0] -is [string]) {
            # Join primitive arrays as comma-separated string
            $key = if ($Prefix) { $Prefix } else { 'Values' }
            $Target[$key] = $items -join ','
        }
        else {
            # Expand object arrays with index suffix
            for ($i = 0; $i -lt $items.Count; $i++) {
                $childPrefix = if ($Prefix) { "$Prefix$Separator$i" } else { "$i" }
                Expand-Object -InputObject $items[$i] -Prefix $childPrefix -Target $Target `
                    -Separator $Separator -Depth ($Depth + 1) -MaxDepth $MaxDepth
            }
        }
        return
    }

    # PSCustomObject or regular object – recurse over properties
    $properties = $InputObject.PSObject.Properties
    foreach ($prop in $properties) {
        $childPrefix = if ($Prefix) { "$Prefix$Separator$($prop.Name)" } else { $prop.Name }
        Expand-Object -InputObject $prop.Value -Prefix $childPrefix -Target $Target `
            -Separator $Separator -Depth ($Depth + 1) -MaxDepth $MaxDepth
    }
}
