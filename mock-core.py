#!/usr/bin/env python3
import os
import socket
import time
import datetime
import threading

SOCKET_PATH = "/tmp/mock-core.sock"


def sd_notify(msg: str):
    notify_socket = os.getenv("NOTIFY_SOCKET")
    if not notify_socket:
        return

    addr = notify_socket
    if addr[0] == "@":  # abstract namespace
        addr = "\0" + addr[1:]

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        sock.connect(addr)
        sock.sendall(msg.encode())
    finally:
        sock.close()


def handle_client(conn):
    print("THREAD STARTED", flush=True)
    with conn:
        data = conn.recv(1024)
        if not data:
            return
        now = datetime.datetime.now().isoformat()
        response = f"[{now}] echo: {data.decode()}"
        print(f"Responding: {response}")
        conn.sendall(response.encode())


def run_server():
    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen()

    print("mock-core: socket ready", flush=True)

    while True:
        conn, _ = server.accept()
        threading.Thread(target=handle_client, args=(conn,), daemon=True).start()


def main():
    print("mock-core: starting...", flush=True)

    time.sleep(5)
    print("mock-core: creating socket", flush=True)

    threading.Thread(target=run_server, daemon=True).start()

    time.sleep(10)
    print("mock-core: notifying systemd READY=1", flush=True)

    sd_notify("READY=1")

    # stay alive forever
    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()
