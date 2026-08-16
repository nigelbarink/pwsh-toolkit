# AWS Patterns

Common patterns for integrating with AWS from PowerShell scripts.

---

## Choosing Your AWS Interface

| Option | When to use |
|--------|-------------|
| **AWS CLI** (`aws …`) | Quick one-liners, shell scripts, CI pipelines |
| **AWS Tools for PowerShell** (`AWS.Tools.*`) | Complex logic, typed objects, idiomatic PS |

The templates in this repo default to AWS CLI because it is universally
available.  Switch to `AWS.Tools.*` when you need rich object output or
are building a module.

---

## AWS CLI Pattern

```powershell
function Invoke-Aws {
    [CmdletBinding()]
    param(
        [string]   $Profile,
        [string]   $Region,
        [string[]] $Arguments
    )

    $allArgs = @('--profile', $Profile, '--region', $Region, '--output', 'json') + $Arguments

    Write-Verbose "aws $($allArgs -join ' ')"
    $json = aws @allArgs 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI error (exit $LASTEXITCODE): $json"
    }

    $json | ConvertFrom-Json
}

# Usage
$instances = Invoke-Aws -Profile dev -Region eu-west-1 -Arguments @(
    'ec2', 'describe-instances',
    '--filters', 'Name=instance-state-name,Values=running'
)
```

**Key points:**
- Always pass `--output json` and parse with `ConvertFrom-Json`.
- Capture `2>&1` so CLI errors are caught by `$LASTEXITCODE`.
- Throw on non-zero exit so the caller can use `try/catch`.

---

## Credential / Profile Checks

Verify credentials before doing real work:

```powershell
Write-Status "Validating credentials..."
try {
    $identity = Invoke-Aws -Profile $Profile -Region $Region -Arguments @('sts', 'get-caller-identity')
    Write-Success "Authenticated as: $($identity.Arn)"
}
catch {
    Write-ErrorMsg "Credential check failed: $_"
    exit 1
}
```

---

## Parameter Conventions

Always expose `-Profile` and `-Region` as parameters with sensible defaults:

```powershell
param(
    [string] $Profile = ($env:AWS_PROFILE     -or 'default'),
    [string] $Region  = ($env:AWS_DEFAULT_REGION -or 'us-east-1')
)
```

This lets callers override from the CLI *or* inherit from environment variables.

---

## Dry-Run Support

Add `-DryRun` to any script that modifies resources:

```powershell
param([switch] $DryRun)

if ($DryRun) {
    Write-Warn "DRY-RUN – no changes will be made."
}

if (-not $DryRun -and $PSCmdlet.ShouldProcess($resourceId, 'Delete')) {
    Invoke-Aws -Arguments @('ec2', 'terminate-instances', '--instance-ids', $resourceId)
}
```

---

## AWS Tools for PowerShell Pattern

```powershell
# Install once
Install-Module AWS.Tools.EC2 -Scope CurrentUser

Import-Module AWS.Tools.EC2

Set-AWSCredential -ProfileName $Profile
Set-DefaultAWSRegion -Region $Region

$instances = Get-EC2Instance -Filter @(
    @{ Name = 'instance-state-name'; Values = 'running' }
)

$instances.Instances | ForEach-Object {
    [PSCustomObject]@{
        InstanceId = $_.InstanceId
        Type       = $_.InstanceType
        LaunchTime = $_.LaunchTime
    }
}
```

---

## Common AWS Queries

### List all S3 buckets

```powershell
Invoke-Aws -Arguments @('s3api', 'list-buckets') | Select-Object -ExpandProperty Buckets
```

### Get running EC2 instances

```powershell
$result = Invoke-Aws -Arguments @(
    'ec2', 'describe-instances',
    '--filters', 'Name=instance-state-name,Values=running',
    '--query', 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]',
    '--output', 'json'
)
$result | ForEach-Object {
    [PSCustomObject]@{ InstanceId = $_[0]; Type = $_[1]; Name = $_[2] }
}
```

### Tag a resource

```powershell
Invoke-Aws -Arguments @(
    'ec2', 'create-tags',
    '--resources', $InstanceId,
    '--tags', "Key=Environment,Value=$Environment"
)
```

---

## Error Handling

- Always check `$LASTEXITCODE` after AWS CLI calls (or use the `Invoke-Aws` wrapper above).
- Use `try/catch` around AWS operations and surface errors with `Write-ErrorMsg`.
- Log the raw error message at `-Verbose` level so it can be retrieved in CI.

---

## Output Formatting

Emit structured objects from your AWS functions, not formatted text:

```powershell
# Good – downstream can filter/sort/export
[PSCustomObject]@{ BucketName = $b.Name; Region = $b.Region }

# Bad – downstream is stuck with a string
"$($b.Name) in $($b.Region)"
```
