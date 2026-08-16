# Contributing

Thank you for your interest in contributing to pwsh-toolkit!

## Commit Messages

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) standard.

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.

Examples:

```
feat(ScriptKit): add Write-Info function
fix(templates): correct parameter block in aws-script
docs: expand AWS patterns guide
test(ScriptKit): add Pester tests for Write-Warn
```

## Pull Request Process

1. Fork the repo and create a feature branch: `git checkout -b feat/my-feature`
2. Follow the [styling guide](docs/styling.md) for any new PowerShell code.
3. Add or update Pester tests under `tests/` for any new public functions.
4. Run `Invoke-ScriptAnalyzer` and `Invoke-Pester` locally before pushing.
5. Open a PR against `main` with a clear description of *what* and *why*.

## Coding Style

- Prefer PowerShell 7+ features but note compatibility concerns in comments.
- Use `$PSStyle` for color output; fall back gracefully on PS 5.1.
- Write pipeline-friendly functions with `process { }` blocks where applicable.
- Keep functions small and single-purpose.
- See [docs/philosophy.md](docs/philosophy.md) and [docs/styling.md](docs/styling.md).
