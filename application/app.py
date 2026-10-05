#!/usr/bin/env python3
"""Small HTTP service used by the on-premises HA lab."""

import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

try:
    import psycopg2
except ImportError:
    psycopg2 = None


APP_HOST = os.environ.get("APP_HOST", "127.0.0.1")
APP_PORT = int(os.environ.get("APP_PORT", "8080"))
APP_VERSION = os.environ.get("APP_VERSION", "development")
DB_ENABLED = os.environ.get("DB_ENABLED", "0") == "1"
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ.get("DB_NAME", "onprem_app")
DB_USER = os.environ.get("DB_USER", "onprem_app")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")


class ApplicationHandler(BaseHTTPRequestHandler):
    """Serve the application and health-check endpoints."""

    server_version = "OnPremHALab/1.0"

    def send_json(self, status_code, payload):
        body = json.dumps(payload, sort_keys=True).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        hostname = socket.gethostname()

        if path == "/":
            self.send_json(
                200,
                {
                    "message": "Hello from the on-prem HA lab",
                    "hostname": hostname,
                    "version": APP_VERSION,
                },
            )
            return

        if path == "/health":
            self.send_json(200, {"status": "ok", "hostname": hostname})
            return

        if path == "/db-health":
            if not DB_ENABLED or psycopg2 is None:
                self.send_json(
                    503,
                    {"status": "error", "database": DB_NAME, "reason": "disabled"},
                )
                return

            try:
                with psycopg2.connect(
                    host=DB_HOST,
                    port=DB_PORT,
                    dbname=DB_NAME,
                    user=DB_USER,
                    password=DB_PASSWORD,
                    connect_timeout=3,
                ) as connection:
                    with connection.cursor() as cursor:
                        cursor.execute("SELECT 1, pg_is_in_recovery()")
                        result, in_recovery = cursor.fetchone()
                self.send_json(
                    200,
                    {
                        "status": "ok",
                        "database": DB_NAME,
                        "database_host": DB_HOST,
                        "query_result": result,
                        "primary": not in_recovery,
                        "hostname": hostname,
                    },
                )
            except Exception as error:
                self.send_json(
                    503,
                    {
                        "status": "error",
                        "database": DB_NAME,
                        "reason": type(error).__name__,
                        "hostname": hostname,
                    },
                )
            return

        self.send_json(404, {"error": "not found", "path": path})


def main():
    server = ThreadingHTTPServer((APP_HOST, APP_PORT), ApplicationHandler)
    print(f"Listening on {APP_HOST}:{APP_PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
