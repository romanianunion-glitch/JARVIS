from pathlib import Path
import yaml


ROOT = Path(__file__).resolve().parents[2]
CONFIG_FILE = ROOT / "core" / "config" / "jarvis.yaml"


def load_config():
    if not CONFIG_FILE.is_file():
        raise FileNotFoundError(
            f"JARVIS configuration not found: {CONFIG_FILE}"
        )

    with CONFIG_FILE.open("r", encoding="utf-8") as file:
        config = yaml.safe_load(file)

    if not isinstance(config, dict):
        raise ValueError("JARVIS configuration must be a YAML mapping.")

    return config


def get_config_value(config, *keys):
    value = config

    for key in keys:
        if not isinstance(value, dict) or key not in value:
            raise KeyError(f"Missing configuration key: {'.'.join(keys)}")

        value = value[key]

    return value


if __name__ == "__main__":
    config = load_config()

    print(f"Application: {get_config_value(config, 'app', 'name')}")
    print(f"Version: {get_config_value(config, 'app', 'version')}")
    print(f"WebUI port: {get_config_value(config, 'webui', 'host_port')}")
    print(f"Ollama port: {get_config_value(config, 'ollama', 'port')}")
