#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Pester tests for the ScriptKit module's messaging functions.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
    Import-Module $modulePath -Force
}

Describe 'Write-Status' {
    It 'writes to the host without throwing' {
        { Write-Status 'test status' } | Should -Not -Throw
    }

    It 'accepts pipeline input' {
        { 'piped message' | Write-Status } | Should -Not -Throw
    }

    It 'accepts -Timestamp switch without throwing' {
        { Write-Status 'with timestamp' -Timestamp } | Should -Not -Throw
    }

    It 'accepts -LogPath and writes to file' {
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Write-Status 'logged message' -LogPath $tmp
            $content = Get-Content $tmp -Raw
            $content | Should -Match 'logged message'
        }
        finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Write-Success' {
    It 'writes to the host without throwing' {
        { Write-Success 'all good' } | Should -Not -Throw
    }

    It 'accepts pipeline input' {
        { 'piped' | Write-Success } | Should -Not -Throw
    }
}

Describe 'Write-Warn' {
    It 'writes to the host without throwing' {
        { Write-Warn 'careful now' } | Should -Not -Throw
    }
}

Describe 'Write-ErrorMsg' {
    It 'writes to the host without throwing' {
        { Write-ErrorMsg 'something broke' } | Should -Not -Throw
    }
}

Describe 'Write-Info' {
    It 'writes to the host without throwing' {
        { Write-Info 'fyi' } | Should -Not -Throw
    }
}

Describe 'Invoke-Pipeline' {
    It 'passes input through a single identity step' {
        $result = Invoke-Pipeline -InputObject @(1, 2, 3) -Steps @(
            { $_ }
        )
        $result | Should -HaveCount 3
        $result[0] | Should -Be 1
        $result[1] | Should -Be 2
        $result[2] | Should -Be 3
    }

    It 'applies multiple steps in order' {
        $result = Invoke-Pipeline -InputObject @(1, 2, 3, 4, 5) -Steps @(
            { $_ | Where-Object { $_ -gt 2 } }
            { $_ | ForEach-Object { $_ * 10 } }
        )
        $result | Should -HaveCount 3
        $result[0] | Should -Be 30
        $result[1] | Should -Be 40
        $result[2] | Should -Be 50
    }

    It 'works with string input and transformation' {
        $result = Invoke-Pipeline -InputObject @('hello', 'world') -Steps @(
            { $_ | ForEach-Object { $_.ToUpper() } }
        )
        $result | Should -HaveCount 2
        $result[0] | Should -Be 'HELLO'
        $result[1] | Should -Be 'WORLD'
    }
}

Describe 'Private: Format-MessageText' {
    BeforeAll {
        # Access private function by dot-sourcing directly
        . (Join-Path $PSScriptRoot '../modules/ScriptKit/Private/Format-MessageText.ps1')
    }

    It 'formats prefix and message' {
        $result = Format-MessageText -Prefix '[~]' -Message 'hello'
        $result | Should -Be '[~] hello'
    }

    It 'includes timestamp when -Timestamp is set' {
        $result = Format-MessageText -Prefix '[+]' -Message 'done' -Timestamp
        $result | Should -Match '^\[\+\] \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] done$'
    }
}
