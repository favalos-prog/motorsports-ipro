$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'post-discord-summary.ps1'
$logPath = Join-Path $env:TEMP ('discord-heartbeat-test-{0}.jsonl' -f ([guid]::NewGuid()))
$statePath = Join-Path $env:TEMP ('discord-heartbeat-state-{0}.json' -f ([guid]::NewGuid()))
$oldWebhook = $env:DISCORD_WEBHOOK_URL

try {
    $env:DISCORD_WEBHOOK_URL = 'dry-run-placeholder-webhook'
    $result = & $scriptPath -Content 'Durable heartbeat dry-run test.' -LogPath $logPath -DryRun

    if ($LASTEXITCODE -ne 0) {
        throw "Expected exit code 0, got $LASTEXITCODE"
    }

    if ($result -notmatch 'Dry run completed') {
        throw "Expected dry-run confirmation, got: $result"
    }

    if (-not (Test-Path -LiteralPath $logPath)) {
        throw 'Expected log file to be written.'
    }

    $lastLog = Get-Content -LiteralPath $logPath -Tail 1 | ConvertFrom-Json
    if ($lastLog.status -ne 'dry-run') {
        throw "Expected dry-run log status, got: $($lastLog.status)"
    }

    if ($lastLog.contentLength -le 0) {
        throw "Expected positive content length, got: $($lastLog.contentLength)"
    }

    $first = & $scriptPath -Content 'Same durable summary.' -LogPath $logPath -StatePath $statePath -SuppressDuplicate -DryRun
    if ($LASTEXITCODE -ne 0) {
        throw "Expected first duplicate-suppression dry-run exit code 0, got $LASTEXITCODE"
    }
    if ($first -notmatch 'Dry run completed') {
        throw "Expected first dry-run to complete, got: $first"
    }

    $second = & $scriptPath -Content 'Same durable summary.' -LogPath $logPath -StatePath $statePath -SuppressDuplicate -DryRun
    if ($LASTEXITCODE -ne 0) {
        throw "Expected duplicate suppression exit code 0, got $LASTEXITCODE"
    }
    if ($second -notmatch 'suppressed duplicate') {
        throw "Expected duplicate suppression confirmation, got: $second"
    }

    $suppressedLog = Get-Content -LiteralPath $logPath -Tail 1 | ConvertFrom-Json
    if ($suppressedLog.status -ne 'suppressed-duplicate') {
        throw "Expected suppressed-duplicate log status, got: $($suppressedLog.status)"
    }

    'PASS: post-discord-summary dry-run behavior'
}
finally {
    if ($null -eq $oldWebhook) {
        Remove-Item Env:\DISCORD_WEBHOOK_URL -ErrorAction SilentlyContinue
    }
    else {
        $env:DISCORD_WEBHOOK_URL = $oldWebhook
    }

    Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue
}
