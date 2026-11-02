param(
    [ValidateSet("start", "stop", "restart", "status", "logs", "help")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"
$global:LASTEXITCODE = 0

$Container = "open-webui"
$OllamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$OllamaUrl = "http://127.0.0.1:11434/api/version"

$DockerCandidates = @(
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe"
)

function Test-Ollama {
    try {
        Invoke-RestMethod $OllamaUrl -TimeoutSec 3 | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-Docker {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return $false
    }

    docker info *> $null
    return ($LASTEXITCODE -eq 0)
}

function Wait-Until {
    param(
        [scriptblock]$Test,
        [int]$Seconds,
        [string]$Label
    )

    $deadline = (Get-Date).AddSeconds($Seconds)

    while (-not (& $Test)) {
        if ((Get-Date) -gt $deadline) {
            throw "Timed out waiting for $Label."
        }

        Start-Sleep -Seconds 2
    }
}

function Test-Container {
    docker inspect $Container *> $null
    return ($LASTEXITCODE -eq 0)
}

function Get-ContainerState {
    if (-not (Test-Container)) {
        return "missing"
    }

    $state = docker inspect -f '{{.State.Status}}' $Container

    if ($LASTEXITCODE -ne 0) {
        throw "Could not inspect Open WebUI."
    }

    return $state
}

function Start-Docker {
    if (Test-Docker) {
        Write-Host "Docker: already running"
        return
    }

    $DockerExe = $DockerCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $DockerExe) {
        throw "Docker Desktop executable was not found."
    }

    Write-Host "Docker: starting..."
    Start-Process -FilePath $DockerExe

    Wait-Until { Test-Docker } 180 "Docker Desktop"
    Write-Host "Docker: ready"
}

function Start-Ollama {
    if (Test-Ollama) {
        Write-Host "Ollama: already running"
        return
    }

    if (-not (Test-Path $OllamaExe)) {
        Write-Host "Ollama: not installed; skipping."
        return
    }

    Write-Host "Ollama: starting..."
    Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden

    Wait-Until { Test-Ollama } 60 "Ollama API"
    Write-Host "Ollama: ready"
}

function Wait-For-WebUI {
    Wait-Until {
        if (-not (Test-Container)) {
            return $false
        }

        $state = docker inspect -f '{{.State.Status}}' $Container
        $health = docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $Container

        return (
            $LASTEXITCODE -eq 0 -and
            $state -eq "running" -and
            $health -in @("healthy", "none")
        )
    } 180 "Open WebUI"

    Write-Host "Open WebUI: ready"
}

function Start-Stack {
    Start-Docker
    Start-Ollama

    $state = Get-ContainerState

    if ($state -eq "missing") {
        throw "Existing Open WebUI container '$Container' was not found. No replacement was created."
    }

    if ($state -ne "running") {
        Write-Host "Open WebUI: starting..."
        docker start $Container | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start Open WebUI."
        }
    }
    else {
        Write-Host "Open WebUI: already running"
    }

    Wait-For-WebUI
}

function Stop-Stack {
    if (-not (Test-Docker)) {
        Write-Host "Docker: unavailable; nothing to stop."
        return
    }

    $state = Get-ContainerState

    if ($state -eq "running") {
        docker stop $Container | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stop Open WebUI."
        }

        Write-Host "Open WebUI: stopped"
    }
    elseif ($state -eq "missing") {
        Write-Host "Open WebUI: container not found"
    }
    else {
        Write-Host "Open WebUI: already stopped"
    }

    Write-Host "Docker and Ollama were left running."
}

function Restart-Stack {
    Start-Docker

    $state = Get-ContainerState

    if ($state -eq "missing") {
        throw "Existing Open WebUI container '$Container' was not found."
    }

    if ($state -eq "running") {
        docker restart $Container | Out-Null
    }
    else {
        docker start $Container | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to restart Open WebUI."
    }

    Wait-For-WebUI
}

function Show-Status {
    $dockerRunning = Test-Docker
    $ollamaRunning = Test-Ollama

    Write-Host "Docker: $(if ($dockerRunning) { 'running' } else { 'stopped' })"
    Write-Host "Ollama: $(if ($ollamaRunning) { 'running' } else { 'stopped' })"

    if ($dockerRunning) {
        $state = Get-ContainerState

        if ($state -eq "missing") {
            Write-Host "Open WebUI: container not found"
        }
        else {
            $health = docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' $Container
            Write-Host "Open WebUI: $state / $health"
        }
    }
    else {
        Write-Host "Open WebUI: unknown (Docker unavailable)"
    }

    Write-Host "Tailscale Serve: not managed automatically"
}

function Show-Help {
    Write-Host "JARVIS Windows Control"
    Write-Host ""
    Write-Host "Usage: jarvis {start|stop|restart|status|logs|help}"
    Write-Host '       jarvis "question"'
    Write-Host '       jarvis --local "question"'
}

try {
    switch ($Action) {
        "start"   { Start-Stack }
        "stop"    { Stop-Stack }
        "restart" { Restart-Stack }
        "status"  { Show-Status }
        "logs" {
            if (-not (Test-Docker)) {
                throw "Docker is unavailable."
            }

            if (-not (Test-Container)) {
                throw "Open WebUI container not found."
            }

            docker logs --tail 100 -f $Container

            if ($LASTEXITCODE -ne 0) {
                throw "Docker logs returned an error."
            }
        }
        "help" { Show-Help }
    }

    $global:LASTEXITCODE = 0
}
catch {
    Write-Error $_
    $global:LASTEXITCODE = 1
}
