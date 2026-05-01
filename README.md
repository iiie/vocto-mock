# vocto-mock (systemd service test project)

This project is a small mock setup designed to test and experiment with `systemd` service behavior, particularly around service dependencies, notification (`Type=notify`), socket communication, and service orchestration.

It installs two services:

* **mock-core**: a long-running UNIX socket server that integrates with `systemd` readiness notifications
* **mock-cmds**: a one-shot service that sends test messages to the core service over a local socket

The included `install.sh` script automates installation, execution, and cleanup.

---

## Components

### mock-core.py

This is the main service under test. It:

* Starts a UNIX socket server at `/tmp/mock-core.sock`
* Spawns a thread per incoming connection
* Echoes back messages with a timestamp
* Waits before signaling readiness to systemd using `sd_notify("READY=1")`
* Runs indefinitely after initialization

This service is configured as:

* `Type=notify`
* `Restart=always`

So it exercises systemd’s readiness tracking and restart behavior.

---

### mock-cmds.py

A simple client used to test interaction with the core service:

* Connects to the UNIX socket
* Sends a few test messages (`first`, `second`, `third`)
* Prints responses from the server
* Sleeps briefly between requests

It is configured as a `Type=oneshot` systemd service that runs after `mock-core`.

---

## Systemd Units

### videoteam-voctocore.service

The main service unit:

* Runs `mock-core.py`
* Uses `Type=notify` with `NotifyAccess=all`
* Restarts automatically on failure
* Runs as user `videoteam` (or the installing user, if overridden)

It simulates a real-world daemon that must explicitly notify systemd when ready.

---

### videoteam-voctocore-cmds.service

A dependent one-shot service:

* Runs after the core service is active
* Sends test messages over the UNIX socket
* Remains active after execution (`RemainAfterExit=yes`)
* Bound to the lifecycle of the core service via `PartOf=` and `Requires=`

This helps test ordering and dependency correctness.

---

## Installation

To install the services and mock binaries:

```bash
sudo ./install.sh install
```

This will:

* Install binaries into `/opt/vocto-mock`
* Install systemd unit files into `/etc/systemd/system`
* Replace the user if not running as `videoteam`
* Reload systemd daemon
* Enable both services

---

## Test Run (full cycle)

To run the full test sequence:

```bash
sudo ./install.sh test
```

This will:

1. Install everything
2. Restart the command service
3. Wait while it interacts with the core service
4. Observe systemd behavior
5. Clean up everything afterward

While running, it is recommended to monitor logs:

```bash
sudo journalctl -f \
  -u videoteam-voctocore.service \
  -u videoteam-voctocore-cmds.service \
  -o short-iso
```

---

## Cleanup

To manually remove everything:

```bash
sudo ./install.sh clean
```

This will:

* Stop services
* Disable them
* Remove unit files
* Remove `/opt/vocto-mock`
* Reload systemd daemon

---

## What this project is testing

This setup is intentionally simple but touches several systemd behaviors:

* `Type=notify` readiness signaling
* `Restart=always` stability loops
* service ordering (`After=`, `Requires=`, `PartOf=`)
* oneshot services tied to long-running daemons
* UNIX socket communication between services
* runtime ownership and user substitution in unit files

It’s essentially a controlled sandbox for observing how systemd reacts to service lifecycle events.

---

## Notes

* The socket is created at `/tmp/mock-core.sock`
* No external dependencies are required beyond Python 3 and systemd
* Designed for experimentation, not production use
* Safe to run on a local machine, but it will modify system services under `/etc/systemd/system`
