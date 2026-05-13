param(
    [Parameter(Mandatory = $false)]
    [string] $Content,

    [Parameter(Mandatory = $false)]
    [string] $ContentFile,

    [Parameter(Mandatory = $false)]
    [string] $LogPath,

    [Parameter(Mandatory = $false)]
    [string] $StatePath,

    [Parameter(Mandatory = $false)]
    [switch] $SuppressDuplicate,

    [Parameter(Mandatory = $false)]
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

function Get-DefaultLogPath {
    $homePath = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        $homePath = $HOME
    }
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        $homePath = [Environment]::GetFolderPath('UserProfile')
    }
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        throw 'Unable to resolve a user home directory for the default log path.'
    }
    return (Join-Path $homePath '.codex\discord-heartbeat\send-log.jsonl')
}

function Get-DefaultStatePath {
    $homePath = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        $homePath = $HOME
    }
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        $homePath = [Environment]::GetFolderPath('UserProfile')
    }
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        throw 'Unable to resolve a user home directory for the default state path.'
    }
    return (Join-Path $homePath '.codex\discord-heartbeat\last-send-state.json')
}

function Get-ContentHash {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $normalized = ($Value -replace '\r\n', "`n").Trim()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Write-HeartbeatLog {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $false)]
        [string] $ErrorMessage,

        [Parameter(Mandatory = $true)]
        [int] $ContentLength
    )

    $logDir = Split-Path -Parent $LogPath
    if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $entry = [ordered]@{
        timestampUtc  = (Get-Date).ToUniversalTime().ToString('o')
        status        = $Status
        contentLength = $ContentLength
    }

    if ($ErrorMessage) {
        $entry.error = $ErrorMessage
    }

    ($entry | ConvertTo-Json -Compress) | Add-Content -LiteralPath $LogPath -Encoding UTF8
}

function Read-LastSendState {
    if (-not (Test-Path -LiteralPath $StatePath)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-LastSendState {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContentHash
    )

    $stateDir = Split-Path -Parent $StatePath
    if ($stateDir -and -not (Test-Path -LiteralPath $stateDir)) {
        New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    }

    $state = [ordered]@{
        lastContentHash = $ContentHash
        lastSentAtUtc   = (Get-Date).ToUniversalTime().ToString('o')
    }
    ($state | ConvertTo-Json -Compress) | Set-Content -LiteralPath $StatePath -Encoding UTF8
}

try {
    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        $LogPath = Get-DefaultLogPath
    }
    if ([string]::IsNullOrWhiteSpace($StatePath)) {
        $StatePath = Get-DefaultStatePath
    }

    if ($ContentFile) {
        if (-not (Test-Path -LiteralPath $ContentFile)) {
            throw "ContentFile not found: $ContentFile"
        }
        $Content = Get-Content -LiteralPath $ContentFile -Raw
    }

    if ([string]::IsNullOrWhiteSpace($Content)) {
        throw 'Content is required. Pass -Content or -ContentFile.'
    }

    $webhook = $env:DISCORD_WEBHOOK_URL
    if ([string]::IsNullOrWhiteSpace($webhook)) {
        throw 'DISCORD_WEBHOOK_URL is not set.'
    }

    $body = @{ content = $Content } | ConvertTo-Json -Compress
    $contentHash = Get-ContentHash -Value $Content

    if ($SuppressDuplicate) {
        $lastState = Read-LastSendState
        if ($lastState -and $lastState.lastContentHash -eq $contentHash) {
            Write-HeartbeatLog -Status 'suppressed-duplicate' -ContentLength $Content.Length
            'No changes since last Discord summary; suppressed duplicate post.'
            exit 0
        }
    }

    if ($DryRun) {
        Write-HeartbeatLog -Status 'dry-run' -ContentLength $Content.Length
        if ($SuppressDuplicate) {
            Write-LastSendState -ContentHash $contentHash
        }
        'Dry run completed.'
        exit 0
    }

    Invoke-RestMethod -Uri $webhook -Method Post -ContentType 'application/json' -Body $body | Out-Null
    Write-HeartbeatLog -Status 'sent' -ContentLength $Content.Length
    if ($SuppressDuplicate) {
        Write-LastSendState -ContentHash $contentHash
    }
    'Discord summary posted.'
    exit 0
}
catch {
    $message = $_.Exception.Message
    Write-HeartbeatLog -Status 'failed' -ErrorMessage $message -ContentLength $(if ($Content) { $Content.Length } else { 0 })
    Write-Error $message
    exit 1
}
