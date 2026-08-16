@{
    RootModule        = 'ScriptKit.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a3f1c2d4-5e6b-7890-abcd-ef1234567890'
    Author            = 'pwsh-toolkit contributors'
    Description       = 'Shared helper module for high-quality PowerShell scripting.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Write-Status'
        'Write-Success'
        'Write-Warn'
        'Write-ErrorMsg'
        'Write-Info'
        'Invoke-Pipeline'
    )
    PrivateData       = @{
        PSData = @{
            Tags       = @('scripting', 'toolkit', 'styling', 'pipeline')
            ProjectUri = 'https://github.com/nigelbarink/pwsh-toolkit'
        }
    }
}
