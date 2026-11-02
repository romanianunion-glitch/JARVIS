# JARVIS

A cross-platform personal AI assistant built around Open WebUI, a shared Python core, Docker Compose, and platform-specific launchers.

JARVIS is designed to run on Windows 11 and Arch-based Linux distributions such as CachyOS. You choose which supported AI provider and models to connect through your own Open WebUI instance.

## Installation

- **Windows 11:** [Windows installation guide](docs/WINDOWS-INSTALLATION.md)
- **Arch Linux / CachyOS:** [CachyOS installation guide](docs/arch/cachyos-installation.md)

Each guide covers prerequisites, Docker setup, Python environment, first-time Open WebUI startup, provider configuration, and the JARVIS command-line client.

## What is included

- Shared Python configuration and chat client.
- Docker Compose setup for Open WebUI.
- Windows and Linux launchers.
- Optional Ollama integration for local models.
- Separate platform identities and deployment configuration.
- Explicit approval for actions that can affect the host system.

## Choose your AI provider

JARVIS does not require one specific cloud vendor. Configure a supported provider in **Open WebUI → Settings → Admin Settings → Connections**, then make the model available to JARVIS using the configured model IDs.

The installation guides include example base URLs for OpenAI-compatible services such as OpenAI, Gemini, Groq, OpenRouter, and Ollama. Provider compatibility, model availability, billing, and data handling depend on the provider you choose.

There are two separate credentials:
- The **provider API key** belongs in that provider's Open WebUI connection.
- The **JARVIS API key** is an Open WebUI account token used by the JARVIS CLI.

Neither belongs in source code or Git.

## Security

- Never commit API keys, access tokens, passwords, private environment files, databases, or backups.
- Keep `docker/.env` private and untracked.
- Open WebUI is configured to bind to localhost by default.
- Do not expose Docker, Ollama, or Open WebUI directly to the internet without a deliberate security design.
- Review configuration changes before applying them.
- Keep command-execution approval enabled unless you have a clear reason to change it.

Open WebUI provider connections and credentials are stored in its persistent data volume. A new installation must configure its own connections; cloning this repository does not copy provider credentials.

## Repository layout

| Path | Purpose |
|---|---|
| `core/` | Shared configuration and Python code |
| `platforms/windows/` | Windows launcher and scripts |
| `platforms/linux/` | Linux launcher and scripts |
| `docker/` | Docker Compose and environment template |
| `pwa/` | Progressive Web App assets |
| `docs/` | Installation and setup guides |

## License

This repository currently has no license file. Public visibility alone does not grant permission to reuse, modify, or redistribute the code. A license should be chosen and added before explicitly inviting outside contributions or reuse.
