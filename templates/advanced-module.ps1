#Requires -Version 5.1
<#
.SYNOPSIS
    Advanced module skeleton – promotes a script into a proper PowerShell module.
.DESCRIPTION
    This file is a reference/template showing the recommended layout when a
    script grows beyond a single file and needs proper module organisation.

    To scaffold a real module, run:
        New-ModuleManifest -Path ./MyModule/MyModule.psd1 -RootModule MyModule.psm1

    Then copy the pattern below into your Public/ functions.

    STRUCTURE:
        MyModule/
        ├── Public/
        │   ├── Get-MyThing.ps1
        │   └── Set-MyThing.ps1
        ├── Private/
        │   └── Invoke-InternalHelper.ps1
        ├── MyModule.psd1
        └── MyModule.psm1
#>

# ---------------------------------------------------------------------------
# Example public function – copy to Public/<FunctionName>.ps1
# ---------------------------------------------------------------------------
function Get-MyThing {
    <#
    .SYNOPSIS
        Gets a thing.
    .DESCRIPTION
        Extended description.
    .PARAMETER Name
        Name of the thing to get.
    .EXAMPLE
        Get-MyThing -Name 'foo'
    .OUTPUTS
        [PSCustomObject] with Name, Value, CreatedAt properties.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name
    )

    process {
        # Call private helpers freely; they are dot-sourced by the .psm1
        $result = Invoke-InternalHelper -Name $Name

        [PSCustomObject]@{
            Name      = $Name
            Value     = $result
            CreatedAt = Get-Date
        }
    }
}

# ---------------------------------------------------------------------------
# Example private helper – copy to Private/<FunctionName>.ps1
# ---------------------------------------------------------------------------
function Invoke-InternalHelper {
    [CmdletBinding()]
    param([string] $Name)

    # Simulate work
    "Processed-$Name"
}

# ---------------------------------------------------------------------------
# Example .psm1 loader (content for MyModule/MyModule.psm1)
# ---------------------------------------------------------------------------
<#
    $Private = Get-ChildItem "$PSScriptRoot/Private" -Filter '*.ps1' -ErrorAction SilentlyContinue
    $Public  = Get-ChildItem "$PSScriptRoot/Public"  -Filter '*.ps1' -ErrorAction SilentlyContinue

    foreach ($file in @($Private) + @($Public)) {
        . $file.FullName
    }

    Export-ModuleMember -Function $Public.BaseName
#>
