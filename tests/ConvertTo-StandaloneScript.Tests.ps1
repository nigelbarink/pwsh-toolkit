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
}
