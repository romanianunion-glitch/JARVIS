# JARVIS Docker Deployment

This directory contains the shared Docker Compose configuration
used by Windows and Linux.

## Services

- Open WebUI: JARVIS web interface
- Ollama: External inference service, not managed by Compose

## Configuration

Create the environment file before starting JARVIS.

### Windows PowerShell

```powershell
Copy-Item docker/.env.example docker/.env
```

### Linux

```bash
cp docker/.env.example docker/.env
```

Adjust OLLAMA_BASE_URL in docker/.env if necessary.

Never commit .env files or credentials.

## Start

```bash
docker compose -f docker/compose.yaml up -d
```

## Stop

```bash
docker compose -f docker/compose.yaml down
```

## Logs

```bash
docker compose -f docker/compose.yaml logs -f
```

## Persistent data

Open WebUI stores its data in the named open-webui volume.

Stopping the Compose project does not remove this volume.
