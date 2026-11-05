# JARVIS on Windows 11

Installation and setup instructions for running JARVIS on Windows 11 with Docker Desktop, the shared Python chat client, and optional native Ollama.

JARVIS uses Docker Desktop to run Open WebUI. Python runs the shared JARVIS chat client on the Windows host. Ollama is optional; cloud models configured in Open WebUI work without it.

## 1. Requirements

- Windows 11 (64-bit).
- Git for Windows.
- Python 3.11 or newer.
- Docker Desktop with the WSL 2 backend and Linux containers.
- Internet access for cloning the repository and downloading the Open WebUI image.
- Git for Windows and internet access. If the repository is private, your GitHub account must have access.

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

The generated file automatically selects the **Windows 11** identity:
- `JARVIS_NAME=Dum-E — Windows`
- `JARVIS_DEPLOYMENT_ID=dum-e-windows`

Open WebUI uses `WEBUI_NAME` for the name in its default PWA manifest (and appends `(Open WebUI)`). This gives the Windows and CachyOS instances different install names when each is opened through its own Tailscale Serve hostname. Tailscale Serve publishes the local web app; it does not set the identity itself.

If `docker/.env` already existed before this update, the generator will leave it untouched. Update the two values above manually in that file; do not use `--force` unless you intend to regenerate the entire file.

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

### Optional Tailscale Serve and the Windows PWA

Tailscale is optional. Install Tailscale for Windows from the [official download page](https://tailscale.com/download/windows), sign in, and connect this PC to your tailnet. Tailscale Serve works the same way on Windows and Linux; only installation and service management differ.

In PowerShell, verify that Tailscale is connected:

```powershell
tailscale status
tailscale ip -4
```

**Automatic setup (recommended):** The Docker environment generator already selects the Windows/Dum-E PWA manifest for Windows installations. The URL is written to `EXTERNAL_PWA_MANIFEST_URL` in `docker/.env` when you generate the file in section 5. You do not need to edit it manually on a fresh installation.

**If you need to check or change it manually:** From the repository root, the environment file is `docker\.env` (the full default path is `%USERPROFILE%\JARVIS\docker\.env`). Open it with:

```powershell
notepad docker\.env
```

The Windows manifest URL should be:

```dotenv
EXTERNAL_PWA_MANIFEST_URL=https://raw.githubusercontent.com/romanianunion-glitch/JARVIS/main/pwa/manifest.json
```

The manifest file itself is `pwa/manifest.json` in the repository, and its Windows/Dum-E icon is `pwa/jarvis.svg`. These are hosted from the public GitHub repository so Open WebUI and the browser can retrieve them. The CachyOS guide uses `pwa/Arch/manifest.json` and `pwa/Arch/jarvis.svg` instead.

If `docker/.env` was generated by an older version of JARVIS, it will not be overwritten automatically. In that case, add or correct the setting manually as shown above.

Apply the setting by recreating the Open WebUI container from the repository root:

```powershell
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml up -d
```

After Open WebUI is running, publish it privately to your tailnet:

```powershell
tailscale serve --bg 3000
tailscale serve status
```

Open the HTTPS MagicDNS URL shown by Serve status on your other tailnet devices. Serve is private to your tailnet; do not use Funnel. To remove the Serve configuration, run `tailscale serve reset`.

**Install the Windows PWA:** Open the Windows instance's HTTPS MagicDNS URL in Chrome or Edge, then use the browser's **Install app** option. On Android, open that same URL in Chrome and choose **Add to Home screen** or **Install app**. Install it from the Windows instance's own hostname so it keeps the Windows/Dum-E identity.

Official references: [Tailscale Serve](https://tailscale.com/docs/reference/tailscale-cli/serve) · [Open WebUI PWA customization](https://docs.openwebui.com/getting-started/open-webui-as-app/).

## 7. Configure Open WebUI and choose your AI provider

Open `http://127.0.0.1:3000`, create or sign in to your Open WebUI administrator account, and open **Settings → Admin Settings → Connections**. The exact labels can vary slightly by Open WebUI version.

### Connect the provider you want

JARVIS is not locked to one AI provider. You can use any provider supported by your Open WebUI version:

1. Choose **OpenAI API** for an OpenAI-compatible provider, or choose its dedicated connection type if Open WebUI provides one.
2. Enter the provider's API base URL and the API key issued by that provider.
3. Save the connection and verify that it works.
4. Add or select the exact model ID offered by that provider. If automatic model discovery does not work, enter the model ID manually.
5. Make the selected model available to JARVIS using the model IDs below, or update the model mapping in the shared JARVIS configuration to match your chosen IDs.

Common OpenAI-compatible base URLs:

| Provider | Base URL |
|---|---|
| OpenAI | `https://api.openai.com/v1` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai/` |
| Groq | `https://api.groq.com/openai/v1` |
| OpenRouter | `https://openrouter.ai/api/v1` |
| Ollama in this Docker setup | `http://host.docker.internal:11434/v1` |

These URLs are examples, not API keys. Check your provider's current documentation for the correct endpoint, model ID, and compatibility. Providers using a different protocol (for example, Anthropic's native API) should use a dedicated supported connection type rather than an OpenAI-compatible connection.

**There are two different API keys in this setup:**

- **Provider API key:** issued by your chosen AI provider. Enter it in that provider's Open WebUI connection. Provider billing, model access, data handling, and privacy terms depend on that provider.
- **JARVIS API key:** generated by your Open WebUI account. This is the token the JARVIS command-line client uses to authenticate to your Open WebUI instance. Configure it in section 9 below.

Provider connections and their credentials are stored in Open WebUI's persistent data volume, not in this Git repository. A fresh installation must configure its own provider connection. Never commit provider keys, JARVIS tokens, passwords, or screenshots containing secrets.

Official Open WebUI guides:
- [Connect an AI provider](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/)
- [OpenAI-compatible providers](https://docs.openwebui.com/getting-started/quick-start/connect-a-provider/starting-with-openai-compatible/)

### JARVIS model IDs

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

## 13. Updates, backups, and maintenance

There are two separate things to update:

- Git updates the JARVIS repository files. It does not update the Open WebUI image or running container.
- Docker Compose pulls the configured Open WebUI image and recreates the container. The named Docker volume keeps your Open WebUI account, settings, provider connections, and other persistent data.

### Update the repository safely

From the JARVIS repository root in PowerShell:

```powershell
git status --short --branch
```

If you have local changes, commit them or safely stash them before pulling. Do not discard work just to make the update proceed. Then fast-forward to the latest published commit:

```powershell
git pull --ff-only
```

Do not use a force operation to overwrite local work. If Git reports that the branches have diverged, stop and inspect the local commits instead of forcing the update.

### Back up Open WebUI before updating its container

The default persistent Docker volume is `open-webui` (the actual name can be changed with `WEBUI_VOLUME` in `docker/.env`). The commands below identify the Compose-managed Open WebUI container and archive its mounted data volume, including when the volume has a custom name.

Run these commands in PowerShell from the repository root:

```powershell
$ComposeArgs = @("--project-directory", "$PWD", "--env-file", "docker/.env", "-f", "docker/compose.yaml")
$ContainerId = docker compose @ComposeArgs ps -q open-webui

if ($LASTEXITCODE -ne 0 -or -not $ContainerId) {
    throw "Open WebUI container was not found. Complete the first-time setup in section 6 first."
}

$BackupDir = Join-Path $PWD "backups"
$BackupName = "open-webui-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').tar.gz"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Stop writes so the archive is consistent.
docker compose @ComposeArgs stop open-webui
if ($LASTEXITCODE -ne 0) {
    throw "Could not stop Open WebUI. Backup was not started."
}

try {
    # Archive the persistent /app/backend/data volume.
    docker run --rm --volumes-from $ContainerId --mount "type=bind,source=$BackupDir,target=/backup" busybox sh -c "tar -czf '/backup/$BackupName' -C /app/backend/data ."
    if ($LASTEXITCODE -ne 0) {
        throw "Docker backup command failed."
    }

    $BackupFile = Join-Path $BackupDir $BackupName
    if (-not (Test-Path $BackupFile) -or (Get-Item $BackupFile).Length -lt 1) {
        throw "Backup archive was not created or is empty."
    }

    Write-Host "Backup created: $BackupFile"
}
finally {
    # Ensure Open WebUI is started again even if the backup fails.
    docker compose @ComposeArgs start open-webui
}
```

The repository's `.gitignore` excludes the `backups/` directory and archive files. Keep backups somewhere safe: they contain private Open WebUI data, including account and provider configuration. Do not upload them to GitHub or share them.

### Pull and apply the Open WebUI container update

The current repository configuration pins Open WebUI to `ghcr.io/open-webui/open-webui:v0.12.5`. The commands below re-pull the configured tag; they do not automatically switch to a newer Open WebUI release.

To upgrade to a different release, first choose a version you intend to run, then update both the `webui.image` value in `core/config/jarvis.yaml` and `WEBUI_IMAGE` in `docker/.env` to the same image tag. Existing `docker/.env` files are not overwritten by the configuration generator, so changing only the YAML file is not enough on an existing installation. Back up first.

After the repository update and a successful backup, run these commands from the repository root:

```powershell
docker compose @ComposeArgs pull open-webui
if ($LASTEXITCODE -ne 0) {
    throw "Open WebUI image pull failed. The current container has not been recreated."
}

docker compose @ComposeArgs up -d --remove-orphans
if ($LASTEXITCODE -ne 0) {
    throw "Open WebUI container recreation failed. Check the Compose output and logs."
}
```

Unlike `docker compose start`, `up -d` applies image and Compose configuration changes and recreates the container when needed. The named volume is reused, so your existing Open WebUI data remains in place.

Verify the result:

```powershell
docker compose @ComposeArgs ps
docker compose @ComposeArgs logs --tail=100 open-webui
```

Then open `http://127.0.0.1:3000` and confirm that your account, models, and provider connections are still present.

Never run `docker compose down -v` as a routine update command. The `-v` option removes named volumes and can delete your persistent Open WebUI data.

## 14. Security notes

- Keep `docker/.env` private and untracked.
- Keep API keys in user-level environment variables, not in the repository.
- Open WebUI binds to `127.0.0.1` by default.
- Do not expose Docker, Ollama, or Open WebUI directly to the internet without a deliberate security design.
- Back up the Open WebUI volume before major changes.
- Review configuration changes before applying them.

JARVIS keeps command execution approval explicit. Do not disable approval safeguards casually.
