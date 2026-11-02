# JARVIS on CachyOS

Installation and setup instructions for running JARVIS natively on CachyOS.

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

## 13. Updates and maintenance

Pull repository changes only when your working tree is clean, or after safely handling your local changes:

```bash
git status
git pull --ff-only
```

Back up important Open WebUI data before upgrades. Its named Docker volume contains persistent application data.

Do not use `docker compose down -v` unless you intentionally want to delete the persistent volume and its data.

## 14. Security and data

- Keep API keys and credentials outside the Git repository.
- Keep `docker/.env` private and untracked.
- Open WebUI binds to `127.0.0.1` by default.
- Do not expose Docker, Ollama, or Open WebUI directly to the internet without a deliberate security design.
- Back up the Open WebUI volume before major changes.
- Review configuration changes before applying them.

JARVIS is designed to keep command execution approval explicit. Do not disable approval safeguards casually.
