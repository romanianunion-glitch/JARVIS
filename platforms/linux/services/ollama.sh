#!/usr/bin/env bash

ollama_ready() {
    python -c \
        'import urllib.request; urllib.request.urlopen("http://127.0.0.1:11434/api/version", timeout=2)' \
        >/dev/null 2>&1
}

start_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo "Ollama: not installed; skipping."
        return 0
    fi

    if ollama_ready; then
        echo "Ollama: already running"
        return 0
    fi

    if ! systemctl cat ollama.service >/dev/null 2>&1; then
        echo "Error: Ollama is installed, but ollama.service was not found."
        echo "Configure its systemd service before starting JARVIS."
        return 1
    fi

    echo "Ollama: starting system service..."

    if ! systemctl is-active --quiet ollama; then
        sudo systemctl start ollama
    fi

    local attempt
    for attempt in {1..60}; do
        if ollama_ready; then
            echo "Ollama: ready"
            return 0
        fi
        sleep 1
    done

    echo "Error: Ollama API did not become ready."
    return 1
}
