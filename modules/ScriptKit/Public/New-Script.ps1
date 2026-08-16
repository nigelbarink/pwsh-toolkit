function New-Script {
    <#
    .SYNOPSIS
        Creates a new script file from a starter template.
    .DESCRIPTION
        Copies one of the built-in templates to a target path so you can start
        writing a new script with the recommended structure already in place.
        Opens the file in the default editor when -Open is specified.
    .PARAMETER Name
        File name for the new script (e.g. "my-tool.ps1").  A ".ps1" extension
        is added automatically if omitted.
    .PARAMETER Template
        Template to use.  One of: Basic, Pipeline, Aws, Module.
        Defaults to "Basic".
    .PARAMETER Destination
        Directory where the new script will be created.
        Defaults to the current working directory.
    .PARAMETER Open
        When specified, opens the new file in the default editor ($env:EDITOR,
        or 'code' if VS Code is available, otherwise Notepad on Windows).
    .PARAMETER Force
        Overwrite the destination file if it already exists.
    .EXAMPLE
        New-Script -Name "get-inventory.ps1"
    .EXAMPLE
        New-Script -Name "deploy.ps1" -Template Aws -Destination ./scripts -Open
    .OUTPUTS
        [System.IO.FileInfo] The newly created script file.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [ValidateSet('Basic', 'Pipeline', 'Aws', 'Module')]
        [string] $Template = 'Basic',

        [string] $Destination = (Get-Location).Path,

        [switch] $Open,

        [switch] $Force
    )

    # Ensure .ps1 extension
    if (-not $Name.EndsWith('.ps1')) { $Name = "$Name.ps1" }

    $templateMap = @{
        Basic    = 'basic-script.ps1'
        Pipeline = 'pipeline-tool.ps1'
        Aws      = 'aws-script.ps1'
        Module   = 'advanced-module.ps1'
    }

    $templateFile = Join-Path $PSScriptRoot "../../../../templates/$($templateMap[$Template])"
    $templateFile = [System.IO.Path]::GetFullPath($templateFile)

    if (-not (Test-Path $templateFile)) {
        throw "Template file not found: $templateFile"
    }

    if (-not (Test-Path $Destination)) {
        if ($PSCmdlet.ShouldProcess($Destination, 'Create directory')) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
    }

    $targetPath = Join-Path $Destination $Name

    if ((Test-Path $targetPath) -and -not $Force) {
        throw "File already exists: $targetPath  Use -Force to overwrite."
    }

    if ($PSCmdlet.ShouldProcess($targetPath, 'Create script from template')) {
        Copy-Item -Path $templateFile -Destination $targetPath -Force:$Force
        Write-Success "Created: $targetPath  (template: $Template)"

        if ($Open) {
            $editor = $env:EDITOR
            if (-not $editor) {
                if (Get-Command code -ErrorAction SilentlyContinue) { $editor = 'code' }
                elseif ($IsWindows) { $editor = 'notepad' }
            }
            if ($editor) {
                & $editor $targetPath
            }
            else {
                Write-Warn 'Could not determine an editor. Set $env:EDITOR or install VS Code.'
            }
        }

        Get-Item -Path $targetPath
    }
}
