# jarvis.ps1 - start / stop / status for the JARVIS stack
param(
    [ValidateSet("start", "stop", "status")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"
$Container  = "open-webui"
$OllamaExe  = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$DockerExe  = "C:\Users\neluv\AppData\Local\Programs\DockerDesktop\Docker Desktop.exe"
$OllamaUrl  = "http://localhost:11434/api/version"

function Test-Ollama {
    try { Invoke-RestMethod $OllamaUrl -TimeoutSec 3 | Out-Null; $true } catch { $false }
}

function Test-Docker {
    # cmd keeps Docker's "engine not running" message from becoming a PowerShell error
    cmd /c "docker info >nul 2>&1"
    return ($LASTEXITCODE -eq 0)
}

function Wait-Until($test, [int]$seconds, [string]$label) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while (-not (& $test)) {
        if ((Get-Date) -gt $deadline) { throw "Timed out waiting for $label" }
        Start-Sleep -Seconds 2
    }
}

function Start-Stack {
    # 1. Ollama
    if (Test-Ollama) { "Ollama: already running" }
    else {
        if (-not (Test-Path $OllamaExe)) { throw "Ollama not found at $OllamaExe" }
        Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden
        Wait-Until { Test-Ollama } 30 "Ollama"
        "Ollama: started"
    }

    # 2. Docker Desktop
    if (Test-Docker) { "Docker: already running" }
    else {
        if (-not (Test-Path $DockerExe)) { throw "Docker Desktop not found at $DockerExe" }
        Start-Process -FilePath $DockerExe
        "Docker: starting, this can take a minute or two..."
        Wait-Until { Test-Docker } 180 "Docker Desktop"
        "Docker: started"
    }

    # 3. Open WebUI container
    docker start $Container | Out-Null
    Wait-Until { (docker inspect -f '{{.State.Health.Status}}' $Container) -eq "healthy" } 180 "Open WebUI health check"
    "Open WebUI: healthy"

    # 4. Tailnet-only HTTPS (never Funnel)
    tailscale serve --bg 3000 | Out-Null
    "Tailscale serve: on (tailnet only)"
}

function Stop-Stack {
    # 1. Phone access off first (safe to run even if already off)
    # cmd /c "tailscale serve --https=443 off >nul 2>&1"
    # "Tailscale serve: off"

    # 2. Web app container (its data stays on disk)
    if (Test-Docker) {
        docker stop $Container | Out-Null
        "Open WebUI: stopped"
    }
    else { "Open WebUI: Docker already stopped" }

    # 3. Docker Desktop
    if (Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue) {
        Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
        "Docker Desktop: quit"
    }
    else { "Docker Desktop: already closed" }

    # 4. Ollama (server + tray app)
    if (Get-Process -Name "ollama","ollama app" -ErrorAction SilentlyContinue) {
        Get-Process -Name "ollama","ollama app" -ErrorAction SilentlyContinue | Stop-Process -Force
        "Ollama: stopped"
    }
    else { "Ollama: already stopped" }
}

function Show-Status {
    "Ollama:     " + $(if (Test-Ollama) { "running" } else { "stopped" })
    "Docker:     " + $(if (Test-Docker) { "running" } else { "stopped" })
    "Open WebUI: " + $(if (Test-Docker) {
        docker inspect -f '{{.State.Status}} / {{.State.Health.Status}}' $Container
    } else { "unknown (Docker is stopped)" })
    "Tailscale serve:"
    cmd /c "tailscale serve status 2>&1"
}

switch ($Action) {
    "start" { Start-Stack }
    "stop"  { Stop-Stack }
    default { Show-Status }
}
