#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Pester tests for the Phase 4 ScriptKit additions.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
    Import-Module $modulePath -Force
}

# ---------------------------------------------------------------------------
# Write-Header
# ---------------------------------------------------------------------------
Describe 'Write-Header' {
    It 'writes to the host without throwing' {
        { Write-Header 'Section One' } | Should -Not -Throw
    }

    It 'accepts pipeline input' {
        { 'My Section' | Write-Header } | Should -Not -Throw
    }

    It 'accepts -Timestamp without throwing' {
        { Write-Header 'Phase Start' -Timestamp } | Should -Not -Throw
    }

    It 'accepts -Width parameter without throwing' {
        { Write-Header 'Custom Width' -Width 60 } | Should -Not -Throw
    }

    It 'writes to a log file' {
        $tmp = [System.IO.Path]::GetTempFileName()
        try {
            Write-Header 'Logged Section' -LogPath $tmp
            $content = Get-Content $tmp -Raw
            $content | Should -Match 'Logged Section'
        }
        finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# New-Script
# ---------------------------------------------------------------------------
Describe 'New-Script' {
    BeforeEach {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $tmpDir | Out-Null
    }

    AfterEach {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates a Basic script file' {
        $file = New-Script -Name 'test-basic' -Destination $tmpDir
        $file | Should -Not -BeNullOrEmpty
        $file.Name | Should -Be 'test-basic.ps1'
        $file.Exists | Should -BeTrue
    }

    It 'auto-appends .ps1 extension' {
        $file = New-Script -Name 'no-extension' -Destination $tmpDir
        $file.Name | Should -Be 'no-extension.ps1'
    }

    It 'creates an Aws template' {
        $file = New-Script -Name 'aws-tool' -Template Aws -Destination $tmpDir
        $content = Get-Content $file.FullName -Raw
        $content | Should -Match '-Profile'
    }

    It 'creates a Pipeline template' {
        $file = New-Script -Name 'filter-tool' -Template Pipeline -Destination $tmpDir
        $content = Get-Content $file.FullName -Raw
        $content | Should -Match 'process \{'
    }

    It 'throws when file exists and -Force not set' {
        New-Script -Name 'dupe' -Destination $tmpDir | Out-Null
        { New-Script -Name 'dupe' -Destination $tmpDir } | Should -Throw
    }

    It 'overwrites when -Force is set' {
        New-Script -Name 'overwrite-me' -Destination $tmpDir | Out-Null
        { New-Script -Name 'overwrite-me' -Destination $tmpDir -Force } | Should -Not -Throw
    }

    It 'creates destination directory if it does not exist' {
        $nested = Join-Path -Path $tmpDir -ChildPath 'sub' -AdditionalChildPath 'dir'
        $file = New-Script -Name 'nested' -Destination $nested
        $file.Exists | Should -BeTrue
    }
}

# ---------------------------------------------------------------------------
# ConvertTo-FlatObject
# ---------------------------------------------------------------------------
Describe 'ConvertTo-FlatObject' {
    It 'passes through a flat object unchanged' {
        $obj = [PSCustomObject]@{ Name = 'foo'; Value = 42 }
        $flat = $obj | ConvertTo-FlatObject
        $flat.Name  | Should -Be 'foo'
        $flat.Value | Should -Be 42
    }

    It 'flattens one level of nesting' {
        $obj = [PSCustomObject]@{
            Name = 'bar'
            Meta = [PSCustomObject]@{ Env = 'prod'; Owner = 'ops' }
        }
        $flat = $obj | ConvertTo-FlatObject
        $flat.Name     | Should -Be 'bar'
        $flat.Meta_Env | Should -Be 'prod'
        $flat.Meta_Owner | Should -Be 'ops'
    }

    It 'joins primitive arrays as comma-separated string' {
        $obj = [PSCustomObject]@{ Tags = @('a', 'b', 'c') }
        $flat = $obj | ConvertTo-FlatObject
        $flat.Tags | Should -Be 'a,b,c'
    }

    It 'uses custom separator' {
        $obj = [PSCustomObject]@{
            Info = [PSCustomObject]@{ Region = 'eu-west-1' }
        }
        $flat = $obj | ConvertTo-FlatObject -Separator '.'
        $flat.'Info.Region' | Should -Be 'eu-west-1'
    }

    It 'handles null nested value gracefully' {
        $obj = [PSCustomObject]@{ Name = 'x'; Child = $null }
        { $obj | ConvertTo-FlatObject } | Should -Not -Throw
    }

    It 'accepts pipeline input of multiple objects' {
        $objects = @(
            [PSCustomObject]@{ A = 1 }
            [PSCustomObject]@{ A = 2 }
        )
        $results = $objects | ConvertTo-FlatObject
        $results | Should -HaveCount 2
        $results[0].A | Should -Be 1
        $results[1].A | Should -Be 2
    }
}
