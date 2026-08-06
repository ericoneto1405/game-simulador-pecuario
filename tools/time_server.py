#!/usr/bin/env python3
"""Serve a exportação Web e fornece o horário oficial da fazenda."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit
from zoneinfo import ZoneInfo


FARM_TIMEZONE_NAME = "America/Bahia"
FARM_TIMEZONE = ZoneInfo(FARM_TIMEZONE_NAME)


def build_time_payload(now_utc: datetime | None = None) -> dict[str, object]:
    current_utc = now_utc or datetime.now(timezone.utc)
    if current_utc.tzinfo is None:
        current_utc = current_utc.replace(tzinfo=timezone.utc)
    current_utc = current_utc.astimezone(timezone.utc)
    current_local = current_utc.astimezone(FARM_TIMEZONE)
    offset = current_local.utcoffset()
    return {
        "unix_utc": int(current_utc.timestamp()),
        "utc_iso": current_utc.isoformat().replace("+00:00", "Z"),
        "timezone": FARM_TIMEZONE_NAME,
        "offset_seconds": int(offset.total_seconds()) if offset else 0,
        "local": {
            "year": current_local.year,
            "month": current_local.month,
            "day": current_local.day,
            "hour": current_local.hour,
            "minute": current_local.minute,
            "second": current_local.second,
        },
    }


class GameRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self) -> None:
        if urlsplit(self.path).path == "/api/time":
            body = json.dumps(build_time_payload(), ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store, max-age=0")
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--directory", default="builds/web")
    args = parser.parse_args()
    handler = partial(GameRequestHandler, directory=args.directory)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), handler)
    print(f"Servidor iniciado em http://localhost:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
