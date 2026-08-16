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

# Use the messaging functions
Write-Status  "Doing something..."
Write-Success "Done!"
Write-Warn    "Check your inputs."
Write-ErrorMsg "Something went wrong."
Write-Info    "Extra context here."
```

Copy a template to start a new script:

```powershell
Copy-Item ./templates/basic-script.ps1 ./scripts/my-new-script.ps1
```

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
