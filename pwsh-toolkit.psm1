Set-StrictMode -Version Latest

function Resolve-ToolkitModuleScriptPath {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleReference
    )

    if ([string]::IsNullOrWhiteSpace($ModuleReference)) {
        throw 'Module reference cannot be empty.'
    }

    $candidate = $ModuleReference
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $moduleInfo = Get-Module -ListAvailable -Name $candidate | Select-Object -First 1
        if (-not $moduleInfo) {
            throw "Unable to resolve module '$ModuleReference'."
        }

        $candidate = $moduleInfo.Path
    }

    if (-not (Test-Path -LiteralPath $candidate)) {
        throw "Module path '$candidate' does not exist."
    }

    $item = Get-Item -LiteralPath $candidate
    if ($item.PSIsContainer) {
        $moduleScript = Join-Path -Path $item.FullName -ChildPath ($item.BaseName + '.psm1')
        if (Test-Path -LiteralPath $moduleScript) {
            return $moduleScript
        }

        $moduleManifest = Join-Path -Path $item.FullName -ChildPath ($item.BaseName + '.psd1')
        if (Test-Path -LiteralPath $moduleManifest) {
            $candidate = $moduleManifest
        }
        else {
            throw "Could not find a .psm1 or .psd1 in '$($item.FullName)'."
        }
    }

    switch ([System.IO.Path]::GetExtension($candidate).ToLowerInvariant()) {
        '.psm1' {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        '.psd1' {
            $manifest = Import-PowerShellDataFile -LiteralPath $candidate
            if (-not $manifest.ContainsKey('RootModule') -or [string]::IsNullOrWhiteSpace([string]$manifest.RootModule)) {
                throw "Module manifest '$candidate' does not specify RootModule."
            }

            $rootModulePath = Join-Path -Path (Split-Path -LiteralPath $candidate -Parent) -ChildPath ([string]$manifest.RootModule)
            if (-not (Test-Path -LiteralPath $rootModulePath)) {
                throw "RootModule '$rootModulePath' from '$candidate' does not exist."
            }

            return (Resolve-Path -LiteralPath $rootModulePath).Path
        }
        default {
            throw "Module path '$candidate' is not a .psm1 or .psd1 file."
        }
    }
}

function Remove-ExportModuleMemberStatements {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleContent
    )

    $parseErrors = $null
    $moduleAst = [System.Management.Automation.Language.Parser]::ParseInput($ModuleContent, [ref]$null, [ref]$parseErrors)

    if ($parseErrors.Count -gt 0) {
        return $ModuleContent
    }

    $lineBreakPattern = "`r`n|`n|`r"
    $moduleLines = [System.Text.RegularExpressions.Regex]::Split($ModuleContent, $lineBreakPattern)
    $linesToRemove = New-Object 'System.Collections.Generic.HashSet[int]'

    $exportCalls = $moduleAst.FindAll({
            param($ast)
            if ($ast -isnot [System.Management.Automation.Language.CommandAst]) {
                return $false
            }

            $commandName = $ast.GetCommandName()
            return $commandName -eq 'Export-ModuleMember'
        }, $true)

    foreach ($exportCall in $exportCalls) {
        for ($line = $exportCall.Extent.StartLineNumber; $line -le $exportCall.Extent.EndLineNumber; $line++) {
            [void]$linesToRemove.Add($line - 1)
        }
    }

    if ($linesToRemove.Count -eq 0) {
        return $ModuleContent
    }

    $filteredLines = for ($index = 0; $index -lt $moduleLines.Length; $index++) {
        if (-not $linesToRemove.Contains($index)) {
            $moduleLines[$index]
        }
    }

    return ($filteredLines -join [Environment]::NewLine)
}

function ConvertTo-StandaloneScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Position = 1)]
        [string]$OutputPath,

        [string[]]$Module
    )

    $resolvedInputPath = (Resolve-Path -LiteralPath $Path).Path
    $scriptContent = Get-Content -LiteralPath $resolvedInputPath -Raw

    $tokens = $null
    $parseErrors = $null
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors.Count -gt 0) {
        throw "The input script '$resolvedInputPath' cannot be parsed."
    }

    $moduleReferences = New-Object System.Collections.Generic.List[string]
    if ($Module) {
        foreach ($entry in $Module) {
            if (-not [string]::IsNullOrWhiteSpace($entry)) {
                $moduleReferences.Add($entry)
            }
        }
    }

    $importCommands = $scriptAst.FindAll({
            param($ast)
            if ($ast -isnot [System.Management.Automation.Language.CommandAst]) {
                return $false
            }

            return $ast.GetCommandName() -eq 'Import-Module'
        }, $true)

    foreach ($command in $importCommands) {
        $elements = $command.CommandElements
        if ($elements.Count -ge 2 -and
            $elements[1] -isnot [System.Management.Automation.Language.CommandParameterAst] -and
            $elements[1] -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $moduleReferences.Add($elements[1].Value)
        }

        for ($index = 0; $index -lt $elements.Count; $index++) {
            if ($elements[$index] -isnot [System.Management.Automation.Language.CommandParameterAst]) {
                continue
            }

            $parameterAst = [System.Management.Automation.Language.CommandParameterAst]$elements[$index]
            if ($parameterAst.ParameterName -ne 'Name') {
                continue
            }

            if ($parameterAst.Argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $moduleReferences.Add($parameterAst.Argument.Value)
                continue
            }

            if ($index + 1 -lt $elements.Count -and $elements[$index + 1] -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $moduleReferences.Add($elements[$index + 1].Value)
            }
        }
    }

    if ($moduleReferences.Count -eq 0) {
        throw 'No module references were provided or discovered in Import-Module statements.'
    }

    $uniqueModuleReferences = $moduleReferences | Select-Object -Unique

    $lineBreakPattern = "`r`n|`n|`r"
    $scriptLines = [System.Text.RegularExpressions.Regex]::Split($scriptContent, $lineBreakPattern)
    $importLines = New-Object 'System.Collections.Generic.HashSet[int]'

    foreach ($command in $importCommands) {
        for ($line = $command.Extent.StartLineNumber; $line -le $command.Extent.EndLineNumber; $line++) {
            [void]$importLines.Add($line - 1)
        }
    }

    $scriptBodyLines = for ($index = 0; $index -lt $scriptLines.Length; $index++) {
        if (-not $importLines.Contains($index)) {
            $scriptLines[$index]
        }
    }

    $inlinedModules = New-Object System.Collections.Generic.List[string]
    foreach ($reference in $uniqueModuleReferences) {
        $moduleScriptPath = Resolve-ToolkitModuleScriptPath -ModuleReference $reference
        $moduleContent = Get-Content -LiteralPath $moduleScriptPath -Raw
        $cleanedModuleContent = Remove-ExportModuleMemberStatements -ModuleContent $moduleContent
        $moduleBanner = "# Begin inlined module: $reference ($moduleScriptPath)"
        $moduleFooter = "# End inlined module: $reference"
        $inlinedModules.Add(($moduleBanner + [Environment]::NewLine + $cleanedModuleContent.Trim() + [Environment]::NewLine + $moduleFooter))
    }

    if (-not $OutputPath) {
        $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedInputPath)
        $scriptDirectory = Split-Path -LiteralPath $resolvedInputPath -Parent
        $OutputPath = Join-Path -Path $scriptDirectory -ChildPath ($scriptName + '.standalone.ps1')
    }

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)

    $header = @(
        '# This file was generated by ConvertTo-StandaloneScript.',
        "# Source script: $resolvedInputPath"
    ) -join [Environment]::NewLine

    $scriptBody = $scriptBodyLines -join [Environment]::NewLine
    $scriptBody = [System.Text.RegularExpressions.Regex]::Replace($scriptBody, '^(?:[ \t]*\r?\n)+', '')

    $finalContent = @(
        $header,
        ($inlinedModules -join ([Environment]::NewLine + [Environment]::NewLine)),
        $scriptBody
    ) -join ([Environment]::NewLine + [Environment]::NewLine)

    Set-Content -LiteralPath $resolvedOutputPath -Value $finalContent
    return $resolvedOutputPath
}

Export-ModuleMember -Function ConvertTo-StandaloneScript
