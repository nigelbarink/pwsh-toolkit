function ConvertTo-FlatObject {
    <#
    .SYNOPSIS
        Flattens a nested PSCustomObject into a single-level object for CSV export.
    .DESCRIPTION
        Recursively expands nested objects by concatenating property names with a
        separator (default: "_").  Arrays of primitives are joined with a comma.
        Nested arrays of objects are expanded with an index suffix.

        This is useful when piping complex AWS or API responses into Export-Csv
        without losing nested data.
    .PARAMETER InputObject
        The object to flatten.  Accepts pipeline input.
    .PARAMETER Separator
        Character(s) used to join nested property names.  Defaults to "_".
    .PARAMETER MaxDepth
        Maximum recursion depth.  Defaults to 5.
    .EXAMPLE
        [PSCustomObject]@{ Name = 'foo'; Tags = [PSCustomObject]@{ Env = 'prod'; Owner = 'ops' } } |
            ConvertTo-FlatObject
        # => Name, Tags_Env, Tags_Owner

    .EXAMPLE
        Get-EC2Instance | ConvertTo-FlatObject | Export-Csv report.csv -NoTypeInformation
    .OUTPUTS
        [PSCustomObject] with all properties on a single level.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] $InputObject,

        [string] $Separator = '_',

        [int] $MaxDepth = 5
    )

    process {
        $flat = [ordered]@{}
        Expand-Object -InputObject $InputObject -Prefix '' -Target $flat -Separator $Separator -Depth 0 -MaxDepth $MaxDepth
        [PSCustomObject] $flat
    }
}
