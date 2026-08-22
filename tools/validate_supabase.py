#!/usr/bin/env python3
import json
import os
import pathlib
import ssl
import sys
import urllib.error
import urllib.request


ROOT = pathlib.Path(__file__).resolve().parents[1]


def trusted_ssl_context():
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


def load_public_config():
    url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
    key = os.environ.get("SUPABASE_PUBLISHABLE_KEY", "").strip()
    config_path = ROOT / "config/supabase.json"
    if (not url or not key) and config_path.is_file():
        config = json.loads(config_path.read_text(encoding="utf-8"))
        url = str(config.get("url", "")).strip().rstrip("/")
        key = str(config.get("publishable_key", "")).strip()
    if not url.startswith("https://") or not key:
        raise RuntimeError("Configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY.")
    return url, key


def request_json(url, key, path, method="GET", body=None, token=""):
    headers = {"apikey": key, "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        url + path, data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(
            request, timeout=15, context=trusted_ssl_context()
        ) as response:
            text = response.read().decode("utf-8")
            return response.status, json.loads(text) if text else {}
    except urllib.error.HTTPError as error:
        message = error.read().decode("utf-8")
        raise RuntimeError(f"{path} respondeu HTTP {error.code}: {message}") from error


def main():
    url, key = load_public_config()
    status, settings = request_json(url, key, "/auth/v1/settings")
    if status != 200 or not settings.get("external", {}).get("email", False):
        raise RuntimeError("Autenticação por e-mail não está ativa.")
    if not settings.get("mailer_autoconfirm", False):
        raise RuntimeError("A confirmação obrigatória de e-mail ainda está ativa.")

    _, anonymous_saves = request_json(
        url,
        key,
        "/rest/v1/game_saves?select=slot&limit=1",
    )
    if not isinstance(anonymous_saves, list) or anonymous_saves:
        raise RuntimeError("game_saves expôs partidas para usuário anônimo.")
    try:
        request_json(
            url,
            key,
            "/rest/v1/rpc/save_game_slot",
            "POST",
            {
                "p_slot": 1,
                "p_expected_revision": 0,
                "p_save_version": 20,
                "p_payload": {},
                "p_client_saved_at": None,
            },
        )
    except RuntimeError as error:
        if "HTTP 401" not in str(error) and "HTTP 403" not in str(error):
            raise
    else:
        raise RuntimeError("save_game_slot aceitou gravação anônima.")

    email = os.environ.get("SUPABASE_TEST_EMAIL", "").strip()
    password = os.environ.get("SUPABASE_TEST_PASSWORD", "")
    if email and password:
        _, session = request_json(
            url,
            key,
            "/auth/v1/token?grant_type=password",
            "POST",
            {"email": email, "password": password},
        )
        token = str(session.get("access_token", ""))
        if not token:
            raise RuntimeError("A conta de teste não gerou uma sessão.")
        status, saves = request_json(
            url,
            key,
            "/rest/v1/game_saves?select=slot,revision&limit=1",
            token=token,
        )
        if status != 200 or not isinstance(saves, list):
            raise RuntimeError("A tabela game_saves ou suas políticas não responderam.")
        print("OK: Auth, sessão e leitura protegida de game_saves.")
    else:
        print("OK: Auth por e-mail ativo, confirmação desabilitada e escrita anônima bloqueada.")
        print("AVISO: informe SUPABASE_TEST_EMAIL e SUPABASE_TEST_PASSWORD para validar a sessão e game_saves.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        sys.exit(1)
