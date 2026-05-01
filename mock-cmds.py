#!/usr/bin/env python3
import socket
import time

SOCKET_PATH = "/tmp/mock-core.sock"


def send_once(msg):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(SOCKET_PATH)
    s.sendall(msg.encode())
    data = s.recv(1024)
    s.close()
    return data.decode()


def main():
    print("mock-cmds: starting")

    for msg in ["first", "second", "third"]:
        resp = send_once(msg)
        print("response:", resp, flush=True)
        time.sleep(1)

    print("mock-cmds: done")


if __name__ == "__main__":
    main()
