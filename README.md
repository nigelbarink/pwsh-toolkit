# pwsh-toolkit

## Convert a module-based script to a standalone script

Use `ConvertTo-StandaloneScript` to inline module content into a script and remove its `Import-Module` statements.

```powershell
Import-Module ./pwsh-toolkit.psd1
ConvertTo-StandaloneScript -Path ./script.ps1 -OutputPath ./script.standalone.ps1
```

When `-OutputPath` is omitted, the command writes `<script-name>.standalone.ps1` next to the original script.
