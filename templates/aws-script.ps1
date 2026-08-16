#Requires -Version 5.1
<#
.SYNOPSIS
    AWS-aware script template with profile, region, and dry-run support.
.DESCRIPTION
    Starting point for any script that interacts with AWS via the AWS CLI.
    Handles credential profile selection, region defaulting, dry-run mode,
    and consistent colored output.

    Prerequisites:
        - AWS CLI installed and on $env:PATH
        - A valid named profile (or default credentials) configured

.PARAMETER Profile
    AWS named profile (maps to --profile).  Defaults to $env:AWS_PROFILE or
    "default".
.PARAMETER Region
    AWS region (maps to --region).  Defaults to $env:AWS_DEFAULT_REGION or
    "us-east-1".
.PARAMETER DryRun
    When set, shows what would happen without making any changes.
.EXAMPLE
    .\aws-script.ps1 -Profile dev -Region eu-west-1
.EXAMPLE
    .\aws-script.ps1 -DryRun
.NOTES
    Author:  Your Name
    Created: YYYY-MM-DD
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Profile = ($env:AWS_PROFILE -or 'default'),

    [string] $Region  = ($env:AWS_DEFAULT_REGION -or 'us-east-1'),

    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------
$moduleRoot = Join-Path $PSScriptRoot '../modules/ScriptKit/ScriptKit.psd1'
if (Test-Path $moduleRoot) {
    Import-Module $moduleRoot -Force
}

# ---------------------------------------------------------------------------
# Helper: run aws CLI and return parsed JSON
# ---------------------------------------------------------------------------
function Invoke-Aws {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
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

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
Write-Status "Checking AWS CLI availability..."
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "AWS CLI not found.  Install it from https://aws.amazon.com/cli/"
    exit 1
}

Write-Info "Profile : $Profile"
Write-Info "Region  : $Region"

if ($DryRun) {
    Write-Warn "DRY-RUN mode – no changes will be made."
}

# Verify the profile/credentials are valid
Write-Status "Validating credentials..."
try {
    $identity = Invoke-Aws -Arguments @('sts', 'get-caller-identity')
    Write-Success "Authenticated as: $($identity.Arn)"
}
catch {
    Write-ErrorMsg "Credential check failed: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Main logic – replace with your real AWS operations
# ---------------------------------------------------------------------------
Write-Status "Running main logic..."

try {
    if ($DryRun -or $PSCmdlet.ShouldProcess('AWS resources', 'Query')) {
        # Example: list S3 buckets
        $buckets = Invoke-Aws -Arguments @('s3api', 'list-buckets')
        $buckets.Buckets | ForEach-Object {
            Write-Info "  Bucket: $($_.Name)"
        }
    }

    Write-Success "Done."
}
catch {
    Write-ErrorMsg "Error: $_"
    exit 1
}
