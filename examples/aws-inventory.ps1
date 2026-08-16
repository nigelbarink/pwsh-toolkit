#Requires -Version 5.1
<#
.SYNOPSIS
    AWS inventory example – lists running EC2 instances across regions.
.DESCRIPTION
    Demonstrates AWS CLI integration patterns: profile/region parameters,
    credential checking, structured output, and dry-run support.

    Usage:
        .\aws-inventory.ps1 -Profile dev -Region eu-west-1
        .\aws-inventory.ps1 | Export-Csv inventory.csv -NoTypeInformation

.PARAMETER Profile
    AWS named profile.  Defaults to $env:AWS_PROFILE or "default".
.PARAMETER Region
    AWS region.  Defaults to $env:AWS_DEFAULT_REGION or "us-east-1".
.EXAMPLE
    .\aws-inventory.ps1 -Profile prod -Region us-east-1
.EXAMPLE
    .\aws-inventory.ps1 -Verbose | Format-Table -AutoSize
#>
[CmdletBinding()]
param(
    [string] $Profile = $(if ($env:AWS_PROFILE)        { $env:AWS_PROFILE }        else { 'default' }),
    [string] $Region  = $(if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { 'us-east-1' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
if (Test-Path $moduleRoot) { Import-Module $moduleRoot -Force }

# ---------------------------------------------------------------------------
# AWS CLI wrapper
# ---------------------------------------------------------------------------
function Invoke-Aws {
    [CmdletBinding()]
    param([string[]] $Arguments)

    $allArgs = @('--profile', $Profile, '--region', $Region, '--output', 'json') + $Arguments
    Write-Verbose "aws $($allArgs -join ' ')"

    $json = aws @allArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "AWS CLI error (exit $LASTEXITCODE): $json" }
    $json | ConvertFrom-Json
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "AWS CLI not found."
    exit 1
}

Write-Info "Profile : $Profile  |  Region : $Region"

Write-Status "Validating credentials..."
try {
    $identity = Invoke-Aws -Arguments @('sts', 'get-caller-identity')
    Write-Success "Authenticated: $($identity.Arn)"
}
catch {
    Write-ErrorMsg "Credential check failed: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Inventory: EC2
# ---------------------------------------------------------------------------
Write-Status "Fetching running EC2 instances..."

try {
    $result = Invoke-Aws -Arguments @(
        'ec2', 'describe-instances',
        '--filters', 'Name=instance-state-name,Values=running'
    )

    $instances = $result.Reservations | ForEach-Object {
        $_.Instances
    } | ForEach-Object {
        $nameTag = ($_.Tags | Where-Object Key -eq 'Name').Value
        [PSCustomObject]@{
            InstanceId   = $_.InstanceId
            Name         = $nameTag
            Type         = $_.InstanceType
            State        = $_.State.Name
            LaunchTime   = $_.LaunchTime
            PrivateIp    = $_.PrivateIpAddress
            Region       = $Region
        }
    }

    Write-Success "Found $($instances.Count) running instance(s)."
    $instances   # emit to pipeline
}
catch {
    Write-ErrorMsg "EC2 query failed: $_"
    exit 1
}
