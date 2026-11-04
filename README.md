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

## Supported setup and alternatives

The installation guides describe the **reference setup that this project is developed and tested with**. Following those guides is the recommended way to get a working JARVIS installation.

You're welcome to experiment with alternatives, replace components, or build your own fork. For example, you could use a different frontend instead of Open WebUI, another container runtime instead of Docker, or a different networking solution instead of Tailscale if you use it for remote access.

Keep in mind that these components are connected to the scripts, configuration, networking, and setup instructions around them. Replacing one may require you to adapt those parts too. Alternative combinations are not automatically tested or supported by this project, so the person maintaining that modified setup is responsible for making sure it works and remains secure.

In short: **the documented setup is the supported starting point; modifications are welcome, but may need additional work.**

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

## Copyright and attribution

Copyright (c) 2026 romanianunion-glitch. All rights reserved.

JARVIS is the original work of `romanianunion-glitch`. If you fork, modify, or redistribute this project, retain the original copyright and license notice in the [`LICENSE`](LICENSE) file as required by the MIT License. You may add your own copyright notice for your modifications, but that does not replace or remove the original attribution.

## License

JARVIS is licensed under the [MIT License](LICENSE). The license permits use, modification, and redistribution, including commercially, provided the required copyright and permission notice is included.
