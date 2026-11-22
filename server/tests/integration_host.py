"""Local Android integration fixture. Own database and ports; never touches demo data."""

from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import os, subprocess, sys, json

root = Path(__file__).resolve().parents[1]
data = Path(os.environ.get("PAM_TEST_DATA", r"D:\PAM\Lab5\integration-data"))
data.mkdir(parents=True, exist_ok=True)
process = None
secret = "integration-secret-one"
log = open(data / "server.log", "a", encoding="utf-8")


def stop():
    global process
    if process is not None:
        if os.name == "nt":
            subprocess.run(
                ["taskkill", "/PID", str(process.pid), "/T", "/F"],
                check=True,
                stdout=subprocess.DEVNULL,
            )
        else:
            process.terminate()
        process.wait(timeout=10)
        process = None


def start():
    global process
    if process is None:
        env = {
            **os.environ,
            "PORT": "8081",
            "PAM_DATA_DIR": str(data),
            "JWT_SECRET": secret,
        }
        process = subprocess.Popen(
            [sys.executable, "-m", "app.main"],
            cwd=root,
            env=env,
            stdout=log,
            stderr=log,
        )


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        global secret
        if self.headers.get("X-Test-Key") != "lostfound-local-integration":
            self.send_error(403)
            return
        if self.path == "/stop":
            stop()
        elif self.path == "/start":
            start()
        elif self.path == "/rotate":
            stop()
            secret += "-next"
            start()
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"{}")


if __name__ == "__main__":
    start()
    try:
        HTTPServer(("0.0.0.0", 8082), Handler).serve_forever()
    finally:
        stop()
        log.close()
