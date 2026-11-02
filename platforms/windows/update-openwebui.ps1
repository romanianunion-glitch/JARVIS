param(
    [string]$Version,          # optional, example: v0.12.4 (empty = auto-detect latest release)
    [int]$KeepBackups = 2,     # how many backups to keep
    [switch]$AutoRestart,      # start the container automatically after reboots
    [string]$ExternalPwaManifestUrl = $env:EXTERNAL_PWA_MANIFEST_URL, # optional custom PWA manifest URL
    [switch]$Yes               # skip the confirmation question
)

$Name       = "open-webui"
$Volume     = "open-webui"
$Image      = "ghcr.io/open-webui/open-webui"
$BackupDir  = "$HOME\openwebui-backups"
$Stamp      = Get-Date -Format "yyyy-MM-dd_HH-mm"
$BackupFile = "openwebui-$Stamp.tar.gz"

function Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    exit 1
}

function Start-OpenWebUI($tag) {
    $runArgs = @(
        "run", "-d",
        "-p", "127.0.0.1:3000:8080",
        "--add-host=host.docker.internal:host-gateway",
        "-v", "${Volume}:/app/backend/data",
        "-e", "OLLAMA_BASE_URL=http://host.docker.internal:11434",
        "-e", "WEBUI_NAME=Dum-E",
        "--name", $Name
    )
    if ($ExternalPwaManifestUrl) {
        $runArgs += @("-e", "EXTERNAL_PWA_MANIFEST_URL=$ExternalPwaManifestUrl")
    }
    if ($AutoRestart) { $runArgs += @("--restart", "unless-stopped") }
    $runArgs += "${Image}:$tag"

    docker @runArgs | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "docker run failed for tag $tag" }
}

function Wait-Healthy([int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        $status = docker inspect --format '{{.State.Health.Status}}' $Name 2>$null
        if ($status -eq "healthy") {
            try {
                $r = Invoke-WebRequest -Uri "http://127.0.0.1:3000/health" -UseBasicParsing -TimeoutSec 5
                if ($r.StatusCode -eq 200) { return $true }
            } catch { }
        }
        Start-Sleep -Seconds 5
    }
    return $false
}

# ---------- Pre-checks ----------
docker info *> $null
if ($LASTEXITCODE -ne 0) { Fail "Docker is not running. Start Docker Desktop first." }

$OldImage = docker inspect $Name --format '{{.Config.Image}}' 2>$null
if ($LASTEXITCODE -ne 0 -or -not $OldImage) {
    Fail "Container '$Name' not found. Start your current version first, then run this script."
}
$OldTag = $OldImage.Split(":")[-1]

# ---------- Find the version ----------
$ReleaseUrl = "https://github.com/open-webui/open-webui/releases"
if (-not $Version) {
    Write-Host "Looking up the latest Open WebUI release..." -ForegroundColor Cyan
    try {
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/open-webui/open-webui/releases/latest" `
                                 -Headers @{ "User-Agent" = "update-openwebui-script" } -TimeoutSec 15
        $Version    = $rel.tag_name
        $ReleaseUrl = $rel.html_url
    } catch {
        Fail "Could not read the latest release from GitHub. Pass it yourself: .\update-openwebui.ps1 -Version v0.12.4"
    }
}
if ($Version -notmatch '^v?\d+\.\d+\.\d+$' -and $Version -ne "main") {
    Fail "'$Version' doesn't look like a real version (example: v0.12.4)."
}

if ($OldTag -eq $Version) {
    Write-Host "Already running $Version. Nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "Current: $OldTag  ->  New: $Version" -ForegroundColor Cyan
Write-Host "Release notes (check for breaking changes!): $ReleaseUrl" -ForegroundColor Yellow
if (-not $Yes) {
    $answer = Read-Host "Continue with the update? (y/n)"
    if ($answer -notmatch '^[yY]') { Write-Host "Cancelled. Nothing was changed."; exit 0 }
}

# ---------- 1. Pull (app keeps running) ----------
Write-Host "Pulling ${Image}:$Version ..." -ForegroundColor Cyan
docker pull "${Image}:$Version"
if ($LASTEXITCODE -ne 0) { Fail "Pull failed (wrong version tag?). Nothing was changed." }
$NewVer = docker image inspect "${Image}:$Version" --format '{{index .Config.Labels "org.opencontainers.image.version"}}' 2>$null
if ($NewVer) { Write-Host "Image reports version: $NewVer" -ForegroundColor Green }

# ---------- 2. Stop for a clean backup ----------
Write-Host "Stopping container..." -ForegroundColor Cyan
docker stop $Name | Out-Null

# ---------- 3. Backup ----------
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
Write-Host "Backing up volume to $BackupDir\$BackupFile ..." -ForegroundColor Cyan
docker run --rm -v "${Volume}:/data" -v "${BackupDir}:/backup" alpine tar czf "/backup/$BackupFile" -C /data .
$tarExit = $LASTEXITCODE
$file = Get-Item "$BackupDir\$BackupFile" -ErrorAction SilentlyContinue
if ($tarExit -ne 0 -or -not $file -or $file.Length -lt 1MB) {
    docker start $Name | Out-Null
    Fail "Backup failed or looks too small. Old container restarted, nothing changed."
}
Write-Host ("Backup OK: {0:N0} MB" -f ($file.Length / 1MB)) -ForegroundColor Green

# ---------- 4. Replace container (volume stays untouched) ----------
docker rm $Name | Out-Null

Write-Host "Starting $Version ..." -ForegroundColor Cyan
try {
    Start-OpenWebUI $Version
} catch {
    Write-Host "Could not start new container. Rolling back..." -ForegroundColor Red
    docker rm -f $Name 2>$null | Out-Null
    Start-OpenWebUI $OldTag
    Fail "Rolled back to $OldTag."
}

# ---------- 5. Health check + rollback ----------
Write-Host "Waiting for healthy status (migrations can take a minute)..." -ForegroundColor Cyan
if (Wait-Healthy 150) {
    Write-Host "Done! Open WebUI $Version is running at http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "New version is NOT healthy. Last logs:" -ForegroundColor Red
    docker logs $Name --tail 30
    docker rm -f $Name | Out-Null
    Start-OpenWebUI $OldTag
    Write-Host "Rolled back to $OldTag. If it complains about the database, restore: $BackupDir\$BackupFile" -ForegroundColor Yellow
    exit 1
}

# ---------- 6. Keep only the newest backups ----------
Get-ChildItem $BackupDir -Filter "openwebui-20*.tar.gz" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $KeepBackups |
    Remove-Item -Force

# ---------- 7. Tailscale / PWA reminder ----------
if (Get-Command tailscale -ErrorAction SilentlyContinue) {
    Write-Host "`nTailscale serve status (should point to 127.0.0.1:3000):" -ForegroundColor Cyan
    tailscale serve status
}
Write-Host "`nOld image $OldTag is still on disk for rollback. Remove it after a few days: docker image rm ${Image}:$OldTag" -ForegroundColor DarkGray