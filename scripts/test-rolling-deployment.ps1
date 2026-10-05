$ErrorActionPreference = "Stop"

$projectDirectory = Split-Path -Parent $PSScriptRoot
$wslProjectDirectory = (& wsl.exe -d Debian -- wslpath -a $projectDirectory).Trim()
$probeFile = Join-Path ([System.IO.Path]::GetTempPath()) ("onprem-ha-probes-{0}.log" -f [guid]::NewGuid())
$probeJob = $null
$playbookExitCode = 1

try {
    New-Item -ItemType File -Path $probeFile -Force | Out-Null

    $probeJob = Start-Job -ArgumentList $probeFile -ScriptBlock {
        param($OutputFile)

        while ($true) {
            $timestamp = [DateTime]::UtcNow.ToString("o")
            $statusCode = & curl.exe --noproxy '*' --connect-timeout 2 --max-time 5 `
                --silent --output NUL --write-out '%{http_code}' `
                http://192.168.56.100/health 2>$null

            if ([string]::IsNullOrWhiteSpace($statusCode)) {
                $statusCode = "000"
            }

            Add-Content -LiteralPath $OutputFile -Value "$timestamp $statusCode"
            Start-Sleep -Milliseconds 200
        }
    }

    Start-Sleep -Seconds 1
    & wsl.exe -d Debian -- bash "$wslProjectDirectory/scripts/ansible-playbook-wsl.sh" deploy.yml
    $playbookExitCode = $LASTEXITCODE
    Start-Sleep -Seconds 2
}
finally {
    if ($null -ne $probeJob) {
        Stop-Job -Job $probeJob -ErrorAction SilentlyContinue
        Receive-Job -Job $probeJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job -Job $probeJob -Force -ErrorAction SilentlyContinue
    }
}

$probeResults = @(Get-Content -LiteralPath $probeFile)
$failedProbes = @($probeResults | Where-Object { $_ -notmatch ' 200$' })

Write-Output "Rolling deployment HTTP probes: $($probeResults.Count)"
Write-Output "Failed HTTP probes: $($failedProbes.Count)"

if ($failedProbes.Count -gt 0) {
    Write-Output "Non-200 responses observed:"
    $failedProbes | Write-Output
}

Remove-Item -LiteralPath $probeFile -Force

if ($playbookExitCode -ne 0) {
    throw "The rolling deployment playbook failed with exit code $playbookExitCode."
}

if ($failedProbes.Count -ne 0) {
    throw "The rolling deployment had $($failedProbes.Count) failed HTTP probes."
}

Write-Output "Zero-downtime rolling deployment verified from Windows."
