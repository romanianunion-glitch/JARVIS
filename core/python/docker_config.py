from pathlib import Path
import sys

if __package__:
    from .config import load_config, get_config_value
else:
    from config import load_config, get_config_value


ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = ROOT / "docker" / ".env"


def generate_env(config):
    app_name = get_config_value(config, "app", "name")
    webui_image = get_config_value(config, "webui", "image")
    webui_container = get_config_value(config, "webui", "container")
    webui_host_ip = get_config_value(config, "webui", "host_ip")
    webui_port = get_config_value(config, "webui", "host_port")
    webui_volume = get_config_value(config, "webui", "volume")
    ollama_port = get_config_value(config, "ollama", "port")

    values = {
        "JARVIS_NAME": app_name,
        "WEBUI_IMAGE": webui_image,
        "WEBUI_CONTAINER": webui_container,
        "WEBUI_HOST_IP": webui_host_ip,
        "WEBUI_HOST_PORT": webui_port,
        "WEBUI_VOLUME": webui_volume,
        "OLLAMA_BASE_URL": f"http://host.docker.internal:{ollama_port}",
    }

    return "\n".join(
        f"{key}={value}" for key, value in values.items()
    ) + "\n"


def main():
    config = load_config()
    content = generate_env(config)

    if ENV_FILE.exists() and "--force" not in sys.argv:
        print("Environment file already exists.")
        print("Use --force to regenerate it.")
        return 1

    ENV_FILE.write_text(content, encoding="utf-8")
    print(f"Docker environment generated: {ENV_FILE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
