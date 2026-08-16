# pwsh-toolkit

A reusable, opinionated starter kit for writing high-quality PowerShell scripts.

## Philosophy

- **GNU / Unix mindset** – Small, focused tools that do one thing well and compose via pipelines.
- **Modern PowerShell style** – PowerShell 7+ first with `$PSStyle`, structured output, and consistent colorful messaging.
- **AWS-first practicality** – Easy patterns for AWS CLI and AWS Tools for PowerShell.
- **Batteries included but minimal** – Strong foundations without a heavy framework.
- **Discoverable & maintainable** – Clear structure, good docs, and examples that teach the style.

## Getting Started

```powershell
# Import the shared ScriptKit module
Import-Module ./modules/ScriptKit/ScriptKit.psd1

# Messaging functions
Write-Status  "Doing something..."
Write-Success "Done!"
Write-Warn    "Check your inputs."
Write-ErrorMsg "Something went wrong."
Write-Info    "Extra context here."
Write-Header  "Phase 1: Discovery"   # prominent section banner
```

Create a new script from a template in one command:

```powershell
# Basic script (default)
New-Script -Name "my-tool.ps1" -Destination ./scripts

# AWS-aware script
New-Script -Name "deploy.ps1" -Template Aws -Destination ./scripts -Open
```

Flatten nested objects for CSV export:

```powershell
$aws_response | ConvertTo-FlatObject | Export-Csv report.csv -NoTypeInformation
```

## VS Code

Open `pwsh-toolkit.code-workspace` for recommended settings and the PowerShell extension.

## Repository Structure

```
pwsh-toolkit/
├── .github/workflows/      # CI: PSScriptAnalyzer + Pester
├── docs/                   # Philosophy, styling guidelines, AWS patterns
├── modules/ScriptKit/      # Shared "stdlib" module
│   ├── Public/             # Exported functions
│   └── Private/            # Internal helpers
├── templates/              # Copy-and-start templates
├── examples/               # Realistic, runnable examples
├── tests/                  # Pester tests for ScriptKit
└── scripts/                # Your own scripts live here
```

## Running Tests

```powershell
# Install Pester 5 if needed
Install-Module Pester -MinimumVersion 5.0 -Force

# Run all tests
Invoke-Pester ./tests/ -Output Detailed
```

## Linting

```powershell
# Install PSScriptAnalyzer if needed
Install-Module PSScriptAnalyzer -Force

# Lint the whole repo
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./.psscriptanalyzer.psd1
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT – see [LICENSE](LICENSE).
