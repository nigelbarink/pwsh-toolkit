# Styling Guide

Consistent, colorful, and clean output makes scripts a pleasure to use.  This
guide defines the conventions used in pwsh-toolkit.

---

## Color Semantics

| Color  | Meaning    | Function        | Prefix |
|--------|------------|-----------------|--------|
| Cyan   | In-progress | `Write-Status`  | `[~]`  |
| Green  | Success     | `Write-Success` | `[+]`  |
| Yellow | Warning     | `Write-Warn`    | `[!]`  |
| Red    | Error       | `Write-ErrorMsg`| `[x]`  |
| Blue   | Info        | `Write-Info`    | `[i]`  |

Use these consistently everywhere in the repository.

---

## Using the ScriptKit Messaging Functions

```powershell
Import-Module ./modules/ScriptKit/ScriptKit.psd1

Write-Status  "Connecting..."         # [~] Connecting...
Write-Success "Uploaded 42 files."    # [+] Uploaded 42 files.
Write-Warn    "No items found."       # [!] No items found.
Write-ErrorMsg "Auth failed."         # [x] Auth failed.
Write-Info    "Using region: eu-west-1" # [i] Using region: eu-west-1
```

### Timestamps

Any function accepts `-Timestamp` to prepend the current date/time:

```powershell
Write-Status "Scanning..." -Timestamp
# [~] [2024-08-16 14:03:22] Scanning...
```

### Log files

Pass `-LogPath` to append a plain-text copy (no ANSI codes) to a file:

```powershell
Write-Success "Done." -LogPath ./run.log
```

---

## PowerShell 7+ vs 5.1

All functions detect the PowerShell version at runtime:

- **PS 7+**: Uses `$PSStyle.Foreground.*` and `$PSStyle.Reset` for ANSI colour.
- **PS 5.1**: Falls back to `Write-Host -ForegroundColor`.

When `$PSStyle.OutputRendering` is set to `PlainText` (e.g. when output is
redirected), ANSI sequences are automatically stripped by the runtime.

---

## Output Rendering and Redirection

- **Status/warning/info messages** go to the *host* (via `Write-Host`).
  They do not pollute the *output stream* and are invisible when you redirect
  with `>` or pipe to the next command.
- **Data** is always emitted as objects via the output stream (`return` /
  implicit output).

This means:

```powershell
# Only objects appear in result.json; status messages appear on screen
.\my-script.ps1 | ConvertTo-Json > result.json
```

---

## Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Functions | Verb-Noun (approved verbs) | `Get-AwsTagReport` |
| Parameters | PascalCase | `$OutputPath` |
| Variables | camelCase | `$lineCount` |
| Private helpers | Verb-Noun in Private/ | `Format-MessageText` |
| Script files | kebab-case | `log-analysis.ps1` |

Use `Get-Verb` to check for approved verbs.

---

## Formatting Rules

- Indent with **4 spaces** (no tabs).
- Align `=` signs in hashtable literals for readability.
- Keep lines under **120 characters**.
- Always include comment-based help (`<# .SYNOPSIS ... #>`) on public functions.
