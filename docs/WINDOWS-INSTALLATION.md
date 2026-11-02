# JARVIS on Windows 11

Installation and setup instructions for running JARVIS on Windows 11 with Docker Desktop, the shared Python chat client, and optional native Ollama.

JARVIS uses Docker Desktop to run Open WebUI. Python runs the shared JARVIS chat client on the Windows host. Ollama is optional; cloud models configured in Open WebUI work without it.

## 1. Requirements

- Windows 11 (64-bit).
- Git for Windows.
- Python 3.11 or newer.
- Docker Desktop with the WSL 2 backend and Linux containers.
- Internet access for cloning the repository and downloading the Open WebUI image.
- A GitHub account with access to the private JARVIS repository.

Tailscale is optional. It is not required for local JARVIS use, and the Windows launcher does not configure Tailscale automatically.

## 2. Install the prerequisites

### Git

Install Git for Windows from the official Git website, then open a new PowerShell terminal and verify:

```powershell
git --version
```

### Python

Install Python 3 from the official Python website. Enable the option to add Python to PATH during installation if the installer offers it.

Verify:

```powershell
python --version
py --version
```

### Docker Desktop

Install Docker Desktop for Windows and use its WSL 2 backend. If WSL is not installed, open PowerShell as Administrator and run:

```powershell
wsl --install
```

Restart Windows if requested, finish the WSL setup, then open Docker Desktop and wait until its engine is running.

Verify Docker:

```powershell
docker version
docker compose version
docker info
```

The Docker commands must work without an error before continuing.

## 3. Clone the private repository

Sign in to GitHub through Git Credential Manager when prompted. Your GitHub account must have access to the private repository.

Clone the repository into your home directory:

```powershell
Set-Location $HOME
git clone https://github.com/romanianunion-glitch/JARVIS.git
Set-Location "$HOME\JARVIS"
```

If you already cloned JARVIS, open PowerShell in that repository and update it only after checking that your working tree is clean:

```powershell
git status
git pull --ff-only
```

## 4. Set up the Python environment

From the repository root:

```powershell
Set-Location "$HOME\JARVIS"
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

The project virtual environment keeps JARVIS dependencies separate from other Python projects.

## 5. Generate Docker configuration

Generate the Docker environment file from the shared JARVIS configuration:

```powershell
.\.venv\Scripts\python.exe -m core.python.docker_config
```

This creates `docker\.env`. If the file already exists, the generator will not overwrite it. Only regenerate it intentionally with:

```powershell
.\.venv\Scripts\python.exe -m core.python.docker_config --force
```

Review the generated file if needed. Do not put provider API keys in it, commit it, or share it.

## 6. First-time Open WebUI setup

The JARVIS `start` command starts an existing Open WebUI container. It does not create a container on a fresh installation.

From the repository root, create and start Open WebUI for the first time:

```powershell
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml up -d
```

Check the container:

```powershell
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml ps
```

Open WebUI should be available at:

```text
http://127.0.0.1:3000
```

The named Docker volume `open-webui` stores persistent Open WebUI data. Do not remove it when updating or restarting JARVIS. Avoid `docker compose down -v` unless you deliberately intend to delete that data.

## 7. Configure Open WebUI

Open `http://127.0.0.1:3000`, create or sign in to your Open WebUI account, and configure the model connections you want to use.

The model IDs must match the shared JARVIS configuration:

- Cloud model: `-jarvis-cloud`
- Private/local model: `-jarvis-local`

The cloud model needs a working provider connection. The private/local model needs Ollama to be installed, running, and reachable from Open WebUI.

Open WebUI configuration and its database are stored in its Docker volume. A fresh Windows or Linux installation does not automatically inherit another machine's provider settings or API keys.

## 8. Optional Ollama setup

Ollama is optional. Skip this section if you only intend to use cloud models.

Install Ollama for Windows from its official website and make sure its local API responds:

```powershell
Invoke-RestMethod http://127.0.0.1:11434/api/version
```

The Open WebUI container is configured to reach the Windows host through `host.docker.internal:11434`. Confirm that Open WebUI can reach Ollama and that the local model connection uses the correct model ID.

Do not expose the Ollama API indiscriminately to your network or the internet.

## 9. Configure the JARVIS API key

Create an API key in your Open WebUI account settings.

Store it as a **user-level Windows environment variable**:

1. Open Start and search for **Edit environment variables for your account**.
2. Under **User variables**, select **New**.
3. Set the variable name to `JARVIS_API_KEY`.
4. Paste your Open WebUI API key as the variable value and save.
5. Close and reopen PowerShell or Windows Terminal so the new variable is loaded.

You can verify that it exists without printing the secret:

```powershell
if ($env:JARVIS_API_KEY) { "JARVIS_API_KEY is set" } else { "JARVIS_API_KEY is missing" }
```

The Windows chat adapter also reads the user-level value when it is not already present in the current process environment.

Never put API keys in source files, documentation, Git commits, or screenshots.

## 10. Add JARVIS to your Windows PATH

This lets you run `jarvis` from any directory, including a fresh terminal opened at your home prompt.

The folder that must be added is the repository's Windows launcher directory:

```text
%USERPROFILE%\JARVIS\platforms\windows\bin
```

If you cloned the repository somewhere else, use that location instead.

### Add it through Windows Settings

1. Open Start and search for **Edit environment variables for your account**.
2. Under **User variables**, select the `Path` variable and choose **Edit**.
3. Select **New**.
4. Add the full path to `JARVIS\platforms\windows\bin`.
5. Confirm every dialog with **OK**.
6. Close and reopen Windows Terminal or PowerShell.

### Or add it with PowerShell

Run this in a normal, non-Administrator PowerShell window. It adds the default clone path to your user PATH without replacing existing entries:

```powershell
$JarvisBin = Join-Path $HOME "JARVIS\platforms\windows\bin"

if (-not (Test-Path (Join-Path $JarvisBin "jarvis.cmd"))) {
    throw "jarvis.cmd was not found. Check your JARVIS repository location."
}

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$Entries = @($UserPath -split ";" | Where-Object { $_ })

if (-not ($Entries | Where-Object { $_.TrimEnd("\") -ieq $JarvisBin.TrimEnd("\") })) {
    $NewPath = (@($Entries) + $JarvisBin) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    "Added JARVIS to your user PATH."
}
else {
    "JARVIS is already on your user PATH."
}
```

Close and reopen the terminal after changing PATH. Then verify:

```powershell
Get-Command jarvis
jarvis help
```

## 11. Start and use JARVIS

Once the first-time Open WebUI container exists, start JARVIS:

```powershell
jarvis start
jarvis status
```

Ask JARVIS using the cloud model:

```powershell
jarvis "Good evening, JARVIS."
```

Use the private/local model:

```powershell
jarvis --local "Summarize this locally."
```

Other service commands:

```powershell
jarvis stop
jarvis restart
jarvis logs
jarvis help
```

You can run these commands from any directory after adding the launcher folder to PATH. The launcher locates the repository automatically.

## 12. Troubleshooting

### `jarvis` is not recognized

- Confirm that the PATH entry points to the folder containing `jarvis.cmd`.
- Close and reopen the terminal.
- Run `Get-Command jarvis` to check whether PowerShell can find it.

### Docker is unavailable

- Open Docker Desktop and wait for its engine to finish starting.
- Run `docker info` and `docker compose version`.
- Confirm Docker Desktop is using Linux containers with the WSL 2 backend.

### Open WebUI container is missing

Complete the first-time `docker compose ... up -d` command in section 6. The JARVIS `start` command does not create a missing container.

### Chat authentication fails

Confirm that `JARVIS_API_KEY` is set in the new terminal and that it belongs to the Open WebUI account whose model connections you configured.

### Local model is unavailable

Confirm Ollama is running at `http://127.0.0.1:11434`, then check the Ollama connection and model ID in Open WebUI.

## 13. Updates and backups

Before updating, check for local changes:

```powershell
git status
git pull --ff-only
```

Back up the Open WebUI Docker volume before major upgrades. Do not use `docker compose down -v` unless you intentionally want to delete the volume and all data stored in it.

## 14. Security notes

- Keep `docker/.env` private and untracked.
- Keep API keys in user-level environment variables, not in the repository.
- Open WebUI binds to `127.0.0.1` by default.
- Do not expose Docker, Ollama, or Open WebUI directly to the internet without a deliberate security design.
- Back up the Open WebUI volume before major changes.
- Review configuration changes before applying them.

JARVIS keeps command execution approval explicit. Do not disable approval safeguards casually.
