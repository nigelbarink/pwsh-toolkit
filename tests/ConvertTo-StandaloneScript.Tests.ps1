$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'pwsh-toolkit.psd1') -Force

Describe 'ConvertTo-StandaloneScript' {
    It 'inlines module content and removes Import-Module statements' {
        $tempRoot = Join-Path -Path $TestDrive -ChildPath 'fixture'
        $null = New-Item -Path $tempRoot -ItemType Directory -Force

        $modulePath = Join-Path -Path $tempRoot -ChildPath 'SampleModule.psm1'
        @'
function Get-Greeting {
    'hello'
}

Export-ModuleMember -Function Get-Greeting
'@ | Set-Content -LiteralPath $modulePath

        $scriptPath = Join-Path -Path $tempRoot -ChildPath 'input.ps1'
        @"
Import-Module '$modulePath'
Get-Greeting
"@ | Set-Content -LiteralPath $scriptPath

        $outputPath = Join-Path -Path $tempRoot -ChildPath 'output.ps1'
        ConvertTo-StandaloneScript -Path $scriptPath -OutputPath $outputPath | Out-Null

        $outputPath | Should -Exist

        $outputContent = Get-Content -LiteralPath $outputPath -Raw
        $outputContent | Should -Match 'function Get-Greeting'
        $outputContent | Should -Not -Match 'Import-Module'
        $outputContent | Should -Not -Match 'Export-ModuleMember'

        $executionResult = & $outputPath
        $executionResult | Should -Be 'hello'
    }

    It 'detects Import-Module -Name with a separate argument token' {
        $tempRoot = Join-Path -Path $TestDrive -ChildPath 'fixture-named'
        $null = New-Item -Path $tempRoot -ItemType Directory -Force

        $modulePath = Join-Path -Path $tempRoot -ChildPath 'NamedModule.psm1'
        @'
function Invoke-NamedModule {
    'named'
}

Export-ModuleMember -Function Invoke-NamedModule
'@ | Set-Content -LiteralPath $modulePath

        $scriptPath = Join-Path -Path $tempRoot -ChildPath 'input.ps1'
        @"
Import-Module -Name '$modulePath'
Invoke-NamedModule
"@ | Set-Content -LiteralPath $scriptPath

        $outputPath = Join-Path -Path $tempRoot -ChildPath 'output.ps1'
        ConvertTo-StandaloneScript -Path $scriptPath -OutputPath $outputPath | Out-Null

        $executionResult = & $outputPath
        $executionResult | Should -Be 'named'
    }

    It 'preserves leading indentation on the first remaining script line' {
        $tempRoot = Join-Path -Path $TestDrive -ChildPath 'fixture-indent'
        $null = New-Item -Path $tempRoot -ItemType Directory -Force

        $modulePath = Join-Path -Path $tempRoot -ChildPath 'IndentModule.psm1'
        "function Invoke-Indent { 'indent' }`nExport-ModuleMember -Function Invoke-Indent" | Set-Content -LiteralPath $modulePath

        $scriptPath = Join-Path -Path $tempRoot -ChildPath 'input.ps1'
        @"
Import-Module '$modulePath'
    Invoke-Indent
"@ | Set-Content -LiteralPath $scriptPath

        $outputPath = Join-Path -Path $tempRoot -ChildPath 'output.ps1'
        ConvertTo-StandaloneScript -Path $scriptPath -OutputPath $outputPath | Out-Null

        $outputContent = Get-Content -LiteralPath $outputPath -Raw
        $outputContent | Should -Match "(?m)^    Invoke-Indent$"
    }
}
