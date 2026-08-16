BeforeAll {
    # Load the module under test
    Import-Module "$PSScriptRoot/../src/PwshToolkit/PwshToolkit.psd1" -Force
}

Describe 'Convert-ToStandaloneScript' {

    Context 'Basic conversion of a script with a local module dependency' {
        BeforeAll {
            $srcScript  = "$PSScriptRoot/fixtures/SampleScript.ps1"
            $outScript  = "$TestDrive/SampleScript.standalone.ps1"

            Convert-ToStandaloneScript -Path $srcScript -OutputPath $outScript -Force
        }

        It 'creates the output file' {
            $outScript | Should -Exist
        }

        It 'removes the Import-Module line' {
            $content = Get-Content $outScript -Raw
            $content | Should -Not -Match 'Import-Module'
        }

        It 'inlines Get-Greeting function' {
            $content = Get-Content $outScript -Raw
            $content | Should -Match 'function Get-Greeting'
        }

        It 'inlines Format-Name function' {
            $content = Get-Content $outScript -Raw
            $content | Should -Match 'function Format-Name'
        }

        It 'does not inline private/unexported functions' {
            $content = Get-Content $outScript -Raw
            $content | Should -Not -Match 'function _InternalHelper'
        }

        It 'the standalone script produces correct output when executed' {
            $result = pwsh -NoProfile -NonInteractive -File $outScript 2>&1
            $result | Should -Contain 'Hello, PowerShell!'
            $result | Should -Contain 'Doe, John'
        }
    }

    Context 'Output path defaulting' {
        It 'defaults to <BaseName>.standalone.ps1 next to the source' {
            $srcScript = "$PSScriptRoot/fixtures/SampleScript.ps1"
            $expected  = "$PSScriptRoot/fixtures/SampleScript.standalone.ps1"

            try {
                Convert-ToStandaloneScript -Path $srcScript -Force
                $expected | Should -Exist
            } finally {
                if (Test-Path $expected) { Remove-Item $expected -Force }
            }
        }
    }

    Context 'Guard against overwriting without -Force' {
        It 'throws when output already exists and -Force is not specified' {
            $srcScript = "$PSScriptRoot/fixtures/SampleScript.ps1"
            $out       = "$TestDrive/guard_test.ps1"
            Set-Content $out -Value '# placeholder'

            { Convert-ToStandaloneScript -Path $srcScript -OutputPath $out } |
                Should -Throw
        }
    }

    Context '-WhatIf support' {
        It 'does not create file when -WhatIf is used' {
            $srcScript = "$PSScriptRoot/fixtures/SampleScript.ps1"
            $out       = "$TestDrive/whatif_test.standalone.ps1"

            Convert-ToStandaloneScript -Path $srcScript -OutputPath $out -WhatIf
            $out | Should -Not -Exist
        }
    }
}
