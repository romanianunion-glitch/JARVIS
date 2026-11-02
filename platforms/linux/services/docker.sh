#!/usr/bin/env bash

docker_ready() {
    docker info >/dev/null 2>&1
}

ensure_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: Docker is not installed."
        return 1
    fi

    if ! docker_ready; then
        echo "Docker: starting system service..."

        if ! systemctl is-active --quiet docker; then
            sudo systemctl start docker
        fi

        local attempt
        for attempt in {1..60}; do
            if docker_ready; then
                break
            fi
            sleep 1
        done
    fi

    if ! docker_ready; then
        echo "Error: Docker did not become ready."
        return 1
    fi

    echo "Docker: ready"
}

compose() {
    docker compose \
        --project-directory "$ROOT_DIR" \
        --env-file "$ENV_FILE" \
        -f "$COMPOSE_FILE" \
        "$@"
}

check_compose_files() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo "Error: Docker Compose configuration not found."
        return 1
    fi

    if [[ ! -f "$ENV_FILE" ]]; then
        echo "Error: Docker environment file not found."
        echo "Generate it with: python -m core.python.docker_config"
        return 1
    fi
}
