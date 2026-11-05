# JARVIS on CachyOS/Arch-based

Installation and setup instructions for running JARVIS natively on CachyOS/Arch-based distros.

JARVIS uses a shared Python core, Docker Compose for Open WebUI, and optionally native Ollama for local inference.

## 1. Architecture

- Python: shared configuration and chat client.
- Docker: runs Open WebUI.
- Ollama: optional native service for local inference.
- Open WebUI: web interface and model connections.
- `platforms/linux/bin/jarvis`: Linux service and chat interface.

Default configuration:

| Component | Default |
|---|---|
| Web interface | `http://127.0.0.1:3000` |
| Open WebUI container | `open-webui` |
| Docker volume | `open-webui` |
| Ollama API | `http://127.0.0.1:11434` |
| Cloud model ID | `-jarvis-cloud` |
| Private model ID | `-jarvis-local` |

## 2. Prerequisites

Install the required packages:

```bash
sudo pacman -S --needed git python python-pip curl docker docker-compose
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Verify Docker and Compose:

```bash
docker info
docker compose version
```

Grant your user permission to run Docker commands:

```bash
sudo usermod -aG docker "$USER"
```

Log out and back in for group membership to take effect.
This permission is required by the current JARVIS launcher unless you configure Docker rootless mode separately.
**Security note:** membership in the Docker group grants privileges effectively equivalent to root. Only do this if you understand and accept that risk.


### Tailscale (optional, for access from your other devices)

Tailscale is not required to run JARVIS locally. Install it if you want to reach this CachyOS instance from other devices in your tailnet.

Install the Arch package and start its daemon:

~~~bash
sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled
~~~

Join your tailnet and authenticate using the URL printed by the command:

~~~bash
sudo tailscale up
~~~

Verify the connection:

~~~bash
tailscale status
tailscale ip -4
~~~

To make the local Open WebUI available to your tailnet over HTTPS, first complete the Open WebUI setup in section 6, then run:

~~~bash
tailscale serve --bg 3000
tailscale serve status
~~~

Use the HTTPS hostname shown by the Serve status on your other tailnet devices. Tailscale Serve is private to your tailnet; do not use Tailscale Funnel for this setup. Serve may prompt you to enable HTTPS certificates for your tailnet. Access is still governed by your tailnet access controls. To remove the Serve configuration later, run tailscale serve reset.

Official references: [Tailscale on Linux](https://tailscale.com/docs/install/linux) · [Tailscale Serve](https://tailscale.com/docs/reference/tailscale-cli/serve).

## 3. Clone the repository

```bash
git clone https://github.com/romanianunion-glitch/JARVIS.git
cd JARVIS
```

If you already have the repository, simply enter its directory and update it when appropriate.

## 4. Set up Python

Create and activate a virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
```

Install project dependencies:

```bash
python -m pip install -r requirements.txt
```

## 5. Generate Docker configuration

Generate the Docker environment file from the shared JARVIS configuration:

```bash
.venv/bin/python -m core.python.docker_config
```

This creates `docker/.env`. If you intentionally want to regenerate an existing file, use:

```bash
.venv/bin/python -m core.python.docker_config --force
```

Review `docker/.env` before starting services. Never commit this file or put API keys in it.

The generated file automatically selects the **CachyOS** identity:
- `JARVIS_NAME=JARVIS — CachyOS`
- `JARVIS_DEPLOYMENT_ID=jarvis-cachyos`

Open WebUI uses `WEBUI_NAME` for the name in its default PWA manifest (and appends `(Open WebUI)`). This gives the Windows and CachyOS instances different install names when each is opened through its own Tailscale Serve hostname. Tailscale Serve publishes the local web app; it does not set the identity itself.

If `docker/.env` already existed before this update, the generator will leave it untouched. Update the two values above manually in that file; do not use `--force` unless you intend to regenerate the entire file.

## 6. First-time Open WebUI setup

The JARVIS `start` command starts an existing container. It does not create a new container on a fresh installation.

Create and start Open WebUI for the first time:

```bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml up -d
```

Check its status:

```bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml ps
```

Open WebUI should become available at `http://127.0.0.1:3000`.

The named Docker volume (default: `open-webui`, configurable through `WEBUI_VOLUME` in `core/config/jarvis.yaml`) stores persistent application data. Do not remove it when updating or restarting JARVIS.

For subsequent starts, use `./platforms/linux/bin/jarvis start` from the repository directory.

### Use the custom CachyOS PWA through Tailscale Serve

Tailscale Serve works the same way on Arch/CachyOS and Windows. The platform-specific pieces are the Tailscale installation/service commands and the manifest URL.

After completing the first-time Open WebUI setup in section 6, open `docker/.env` from the repository root with nano:

```bash
nano docker/.env
```

Set the external manifest URL to the **Arch/CachyOS manifest**:

```dotenv
EXTERNAL_PWA_MANIFEST_URL=https://raw.githubusercontent.com/romanianunion-glitch/JARVIS/main/pwa/Arch/manifest.json
```

Save the file, then apply the setting by recreating the Open WebUI container:

```bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml up -d
```

The external manifest uses the Arch-themed SVG icon. Open WebUI fetches the manifest URL from its server when serving `/manifest.json`; therefore the URL must be reachable from the Open WebUI container/server. The icon URL in the manifest is an absolute GitHub raw URL so browsers can retrieve it.

Now publish Open WebUI privately to your tailnet:

```bash
tailscale serve --bg 3000
tailscale serve status
```

Open the HTTPS MagicDNS hostname shown by Serve status on your other tailnet devices. Tailscale Serve is private to your tailnet; do not use Funnel. To remove the Serve configuration later, run `tailscale serve reset`.

**Install the CachyOS PWA:** Open this instance's HTTPS MagicDNS hostname in Chrome or Edge and choose **Install app**. On Android, open it in Chrome and choose **Add to Home screen** or **Install app**. Install from this CachyOS instance's hostname to keep the Arch/JARVIS branding separate from the Windows instance.

Official references: [Tailscale Serve](https://tailscale.com/docs/reference/tailscale-cli/serve) · [Open WebUI PWA customization](https://docs.openwebui.com/getting-started/open-webui-as-app/).

## 7. Optional Ollama setup

Ollama is optional. JARVIS can use cloud models configured in Open WebUI without a local Ollama installation.

If Ollama is installed natively on CachyOS, enable its service:

```bash
sudo systemctl enable --now ollama
```

Verify that its API responds:

```bash
curl http://127.0.0.1:11434/api/version
```

The Docker container reaches the host through `host.docker.internal:11434`. Ollama may need a suitable host binding for container access. Configure this deliberately and restrict access with firewall rules. Do not expose the Ollama API indiscriminately to your network or the internet.

## 8. Configure Open WebUI models

Open `http://127.0.0.1:3000` and sign in.

Configure your cloud and local model connections in Open WebUI. Their model IDs must match the shared JARVIS configuration:

- Cloud: `-jarvis-cloud`
- Private/local: `-jarvis-local`

The local model requires Ollama to be running and reachable by Open WebUI. The cloud model requires a working provider connection.

### Choose and connect your AI provider

JARVIS is not locked to one AI provider. Open `http://127.0.0.1:3000`, sign in as an Open WebUI administrator, and open **Settings → Admin Settings → Connections**. The exact labels can vary slightly by Open WebUI version.

1. Choose **OpenAI API** for an OpenAI-compatible provider, or use the provider's dedicated connection type if Open WebUI offers one.
2. Enter the provider's API base URL and the API key issued by that provider.
3. Save the connection and verify that it works.
4. Add or select the exact model ID offered by the provider. If automatic model discovery does not work, enter the model ID manually.
5. Make the model available to JARVIS using the model IDs below, or update the model mapping in the shared JARVIS configuration to match your chosen IDs.

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

## 9. Configure the API key

Create an API key in your Open WebUI account settings.

Set it in your current shell without displaying it:

```bash
read -rsp "JARVIS API key: " JARVIS_API_KEY; echo
export JARVIS_API_KEY
```

The key is available to JARVIS chat commands launched from this shell. Set it again in a new terminal session, or configure it through a secure user-level environment mechanism.

Never paste API keys into source files, documentation, Git commits, or shared screenshots.

## 10. Add JARVIS to PATH

The launcher can resolve the repository directory itself, so you can create a small symlink in `~/.local/bin` and run `jarvis` from any directory.

The commands below assume you cloned the repository to `~/JARVIS`, as in section 3. If you chose another location, replace that path with your actual repository directory.

Create the user-local command:

```bash
mkdir -p "$HOME/.local/bin"
ln -sfn "$HOME/JARVIS/platforms/linux/bin/jarvis" "$HOME/.local/bin/jarvis"
```

Make sure `~/.local/bin` is on your PATH.

### Fish shell (CachyOS default on many installations)

```fish
fish_add_path "$HOME/.local/bin"
```

`fish_add_path` saves the path for future Fish sessions. Open a new terminal if needed.

### Bash or Zsh

Add this line to `~/.bashrc` (Bash) or `~/.zshrc` (Zsh):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload the matching file, for example:

```bash
source ~/.bashrc
```

Verify that the command resolves:

```bash
command -v jarvis
jarvis help
```

You can now run JARVIS from your home prompt or any other directory:

```bash
cd "$HOME"
jarvis start
jarvis status
jarvis "Good evening, JARVIS."
```

The symlink points to the launcher inside your repository. Keep the repository in place; moving it requires recreating the symlink.

## 11. JARVIS commands

From the repository directory:

```bash
./platforms/linux/bin/jarvis help
./platforms/linux/bin/jarvis start
./platforms/linux/bin/jarvis status
./platforms/linux/bin/jarvis logs
./platforms/linux/bin/jarvis stop
./platforms/linux/bin/jarvis restart
```

Chat using the cloud model:

```bash
./platforms/linux/bin/jarvis "Hello, JARVIS."
```

Chat using the private/local model:

```bash
./platforms/linux/bin/jarvis --local "Hello, JARVIS."
```

## 12. Troubleshooting

### Docker is unavailable

Check the Docker service:

```bash
systemctl status docker
docker info
```

### Open WebUI is not running

Check the container and its logs:

```bash
docker ps -a
./platforms/linux/bin/jarvis logs
```

On a fresh installation, make sure the one-time `docker compose ... up -d` command from section 6 was completed.

### Local model is unavailable

Check Ollama and its API:

```bash
systemctl status ollama
curl http://127.0.0.1:11434/api/version
```

Also verify that Open WebUI can reach the Ollama host endpoint and that the configured model ID is correct.

### Chat authentication fails

Check that `JARVIS_API_KEY` is set in the current shell and that it belongs to the correct Open WebUI account.

## 13. Updates, backups, and maintenance

There are two separate things to update:

- Git pull updates the JARVIS repository files. It does not update the Open WebUI image or the running container.
- Docker Compose pulls the configured Open WebUI image and recreates the container. The named Docker volume keeps your Open WebUI account, settings, provider connections, and other persistent data.

### Update the repository safely

From the JARVIS repository root:

~~~bash
git status --short --branch
~~~

If you have local changes, commit them or safely stash them before pulling. Do not discard work just to make the update proceed. Then fast-forward to the latest published commit:

~~~bash
git pull --ff-only
~~~

Do not use a force operation to overwrite local work. If Git reports that the branches have diverged, stop and inspect the local commits instead of forcing the update.

### Back up Open WebUI before updating its container

The default persistent Docker volume is open-webui (the actual name can be changed with WEBUI_VOLUME in docker/.env). The backup below identifies the existing Compose container and archives its mounted data volume, so it also works when the volume has a custom name.

Run the following commands in Bash from the repository root. If your terminal is Fish, enter bash first:

~~~bash
mkdir -p backups

WEBUI_CONTAINER_ID=$(docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml ps -aq open-webui)

if [[ -z "$WEBUI_CONTAINER_ID" ]]; then
    echo "Open WebUI container was not found. Complete the first-time setup in section 6 first."
    exit 1
fi

BACKUP_NAME="open-webui-$(date +%F-%H%M%S).tar.gz"

# Stop writes so the archive is consistent.
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml stop open-webui

# Archive the persistent /app/backend/data volume.
docker run --rm \
    --volumes-from "$WEBUI_CONTAINER_ID" \
    -v "$PWD/backups:/backup" \
    busybox sh -c 'tar -czf "/backup/$1" -C /app/backend/data .' sh "$BACKUP_NAME"

# Start Open WebUI again after the backup.
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml start open-webui

# Confirm that the archive exists and can be listed.
tar -tzf "backups/$BACKUP_NAME" | head

echo "Backup created: backups/$BACKUP_NAME"
~~~

The repository .gitignore already excludes the backups/ directory and archive files. Keep these backups somewhere safe; they contain private Open WebUI data, including account and provider configuration. Do not upload them to GitHub or share them.

If the backup command fails after stopping Open WebUI, start it again with:

~~~bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml start open-webui
~~~

### Pull and apply the Open WebUI container update

After the repository update and a successful backup, pull the image specified by docker/compose.yaml and recreate the service:

The current repository configuration pins Open WebUI to ghcr.io/open-webui/open-webui:v0.12.5. The commands below re-pull the configured tag; they do not automatically switch to a newer Open WebUI release. To upgrade to a different release, first choose a version you intend to run, then update both the webui.image value in core/config/jarvis.yaml and WEBUI_IMAGE in docker/.env to the same image tag. Existing docker/.env files are not overwritten by the configuration generator, so changing only the YAML file is not enough on an existing installation. Back up first, then run the pull and recreate commands below.


~~~bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml pull open-webui
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml up -d --remove-orphans
~~~

Unlike docker compose start, up -d applies image and Compose configuration changes and recreates the container when needed. The named volume is reused, so your existing Open WebUI data remains in place.

Verify the result:

~~~bash
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml ps
docker compose --project-directory "$PWD" --env-file docker/.env -f docker/compose.yaml logs --tail=100 open-webui
~~~

Then open http://127.0.0.1:3000 and confirm that your account, models, and provider connections are still present.

Never run docker compose down -v as a routine update command. The -v option removes named volumes and can delete your persistent Open WebUI data.

## 14. Security and data

- Keep API keys and credentials outside the Git repository.
- Keep `docker/.env` private and untracked.
- Open WebUI binds to `127.0.0.1` by default.
- Do not expose Docker, Ollama, or Open WebUI directly to the internet without a deliberate security design.
- Back up the Open WebUI volume before major changes.
- Review configuration changes before applying them.

JARVIS is designed to keep command execution approval explicit. Do not disable approval safeguards casually.
