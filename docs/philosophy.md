# Philosophy: The GNU / Unix Mindset in PowerShell

## Core Principle

> "Do one thing, and do it well."  — Doug McIlroy, co-creator of Unix pipes

This starter kit applies that principle to PowerShell scripting.  Each script or
function should have a single, clear responsibility.  Composition of small tools
beats a large monolithic script every time.

---

## Why This Matters for PowerShell

PowerShell is a *pipeline-oriented* shell.  Objects flow through the pipeline the
same way text flows through Unix pipes.  Embracing this means:

1. **Functions emit objects, not text.**  Downstream commands can filter, sort,
   and format without parsing strings.

2. **`process {}` blocks make your function a pipeline citizen.**  A function
   with a `process {}` block processes one item at a time from the pipeline,
   keeping memory usage low and enabling streaming.

3. **Single-responsibility functions compose cleanly.**
   ```powershell
   Get-AwsInstances | Select-StoppedInstances | ConvertTo-CsvReport
   ```
   Each link in this chain knows nothing about the others.

---

## Preferred Patterns

### Filter functions (pipeline-friendly)

```powershell
function Select-ActiveItems {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object] $InputObject
    )

    process {
        if ($InputObject.Status -eq 'Active') {
            $InputObject   # pass downstream unchanged
        }
    }
}
```

### Structured output

Return `[PSCustomObject]` instead of formatted strings:

```powershell
[PSCustomObject]@{
    InstanceId = $id
    State      = $state
    Region     = $region
}
```

### Avoid side-effects in the middle of a pipeline

A function that *both* queries AWS *and* prints a formatted table mixes concerns.
Instead:

- Query → emit objects
- Caller formats or logs as needed

---

## What to Avoid

| Anti-pattern | Better approach |
|---|---|
| `Write-Host` for data | Emit objects; use `Write-Host` only for status/UI |
| `Out-String` in the middle of a pipeline | Keep objects flowing |
| One 500-line script | Several focused functions in a module |
| Hardcoded region / profile | Parameters with sensible defaults |
| `$result = @(); foreach { $result += ... }` | Use `[System.Collections.Generic.List[object]]` or pipeline |

---

## Further Reading

- [The Art of Unix Programming](http://www.catb.org/esr/writings/taoup/) – Eric S. Raymond
- [PowerShell Pipeline](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/04-pipelines) – Microsoft Docs
- [Advanced Functions](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-functions)
