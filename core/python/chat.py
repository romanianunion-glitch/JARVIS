#!/usr/bin/env python3

import json
import os
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from .config import load_config, get_config_value


def main():
    args = sys.argv[1:]
    use_local = bool(args and args[0] == "--local")

    if use_local:
        args = args[1:]

    if not args or any(arg.startswith("-") for arg in args):
        print('Usage: jarvis "your question"')
        print('       jarvis --local "your private question"')
        return 1

    question = " ".join(args).strip()

    if not question:
        print("Error: question cannot be empty.")
        return 1

    api_key = os.environ.get("JARVIS_API_KEY")
    if not api_key:
        print("Error: JARVIS_API_KEY environment variable is not set.")
        return 1

    try:
        config = load_config()

        host = get_config_value(config, "webui", "host_ip")
        port = get_config_value(config, "webui", "host_port")
        model_key = "private" if use_local else "cloud"
        model = get_config_value(config, "models", model_key)

        url = f"http://{host}:{port}/api/chat/completions"

    except (KeyError, FileNotFoundError, ValueError) as error:
        print(f"Configuration error: {error}")
        return 1

    label = "PRIVATE, local" if use_local else "CLOUD"
    print(f"[{label}] model: {model}")

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": question,
            }
        ],
        "stream": False,
    }

    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json; charset=utf-8",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=240) as response:
            result = json.loads(response.read().decode("utf-8"))

        answer = result["choices"][0]["message"]["content"]

        if isinstance(answer, list):
            answer = "\n".join(
                item.get("text", "")
                for item in answer
                if isinstance(item, dict)
            )

        answer = re.sub(
            r"<think>.*?</think>",
            "",
            answer,
            flags=re.DOTALL,
        ).strip()

        print()
        print(answer)
        return 0

    except HTTPError as error:
        print(f"Request failed: HTTP {error.code} - {error.reason}")

        if error.code == 429 and not use_local:
            print("Rate limit reached. Wait a moment or try --local.")

        return 1

    except (URLError, TimeoutError, OSError) as error:
        print(f"Connection failed: {error}")
        return 1

    except (KeyError, IndexError, TypeError, ValueError) as error:
        print(f"Could not read JARVIS response: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
