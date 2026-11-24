[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateRange(600, 1200)]
    [int]$DurationSeconds = 1200
)

$ErrorActionPreference = 'Stop'

foreach ($tool in @('terraform', 'aws')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Required command '$tool' was not found on PATH."
    }
}

Push-Location $PSScriptRoot
try {
    $instanceId = (& terraform output -raw instance_id).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not read instance_id from Terraform output. Apply the project first.'
    }
}
finally {
    Pop-Location
}

if ($instanceId -notmatch '^i-[0-9a-f]{8,17}$') {
    throw "Terraform returned an invalid EC2 instance ID: '$instanceId'."
}

$region = 'ap-south-1'
$remoteCommand = 'timeout --signal=TERM {0}s yes > /dev/null; status=$?; if [ "$status" -eq 124 ] || [ "$status" -eq 143 ]; then echo "CPU load completed after {0} seconds."; exit 0; fi; exit "$status"' -f $DurationSeconds

$request = @{
    DocumentName = 'AWS-RunShellScript'
    InstanceIds  = @($instanceId)
    Parameters   = @{
        commands        = @($remoteCommand)
        executionTimeout = @("$($DurationSeconds + 60)")
    }
    Comment       = "Bounded CPU load for $DurationSeconds seconds"
}

if ($PSCmdlet.ShouldProcess("$instanceId in $region", "Run CPU load for $DurationSeconds seconds")) {
    $requestPath = Join-Path ([IO.Path]::GetTempPath()) ("ssm-cpu-load-{0}.json" -f [guid]::NewGuid())
    try {
        $request | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $requestPath -Encoding ASCII
        $responseText = & aws ssm send-command --cli-input-json "file://$requestPath" --region $region --output json
        if ($LASTEXITCODE -ne 0) {
            throw 'AWS Systems Manager rejected the command. Check AWS credentials, permissions, and instance connectivity.'
        }

        $response = $responseText | ConvertFrom-Json
        if (-not $response.Command.CommandId) {
            throw 'AWS Systems Manager returned no command ID.'
        }

        Write-Output "Submitted SSM command $($response.Command.CommandId) for $instanceId."
        Write-Output 'The CPU load runs for a bounded duration; check Run Command in Systems Manager for status.'
    }
    finally {
        if (Test-Path -LiteralPath $requestPath) {
            Remove-Item -LiteralPath $requestPath -Force
        }
    }
}
