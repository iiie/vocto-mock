#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/vocto-mock"
SERVICE_DIR="/etc/systemd/system"

MODE="${1:-test}"

install() {
  USER_TO_RUN="${SUDO_USER:-$USER}"
  if [ "$USER_TO_RUN" != "videoteam" ]; then
    echo "install user: $USER_TO_RUN"
  fi

  echo "install: dir"
  sudo mkdir -p "$INSTALL_DIR"

  echo "install: files"
  sudo install -m 755 mock-core.py "$INSTALL_DIR/"
  sudo install -m 755 mock-cmds.py "$INSTALL_DIR/"

  echo "install: services"
  if [ "$USER_TO_RUN" != "videoteam" ]; then
    sed "s|=videoteam$|=$USER_TO_RUN|g" videoteam-voctocore.service \
      | sudo install -m 644 /dev/stdin "$SERVICE_DIR/videoteam-voctocore.service"

    sed "s|=videoteam$|=$USER_TO_RUN|g" videoteam-voctocore-cmds.service \
      | sudo install -m 644 /dev/stdin "$SERVICE_DIR/videoteam-voctocore-cmds.service"
  else
    sudo install -m 644 videoteam-voctocore.service "$SERVICE_DIR/"
    sudo install -m 644 videoteam-voctocore-cmds.service "$SERVICE_DIR/"
  fi

  echo "install: daemon-reload"
  sudo systemctl daemon-reload

  echo "install: enable"
  sudo systemctl enable videoteam-voctocore.service
  sudo systemctl enable videoteam-voctocore-cmds.service
}

run_test() {
  echo "test: restart"
  sudo systemctl restart videoteam-voctocore-cmds.service

  echo "test: active (initial)"
  sudo systemctl is-active --quiet videoteam-voctocore-cmds.service

  echo "test: sleep"
  sleep 10

  echo "test: active (after)"
  sudo systemctl is-active --quiet videoteam-voctocore-cmds.service
}

clean() {
  echo "clean: stop"
  sudo systemctl stop videoteam-voctocore-cmds.service || true
  sudo systemctl stop videoteam-voctocore.service || true

  echo "clean: disable"
  sudo systemctl disable videoteam-voctocore.service || true
  sudo systemctl disable videoteam-voctocore-cmds.service || true

  echo "clean: remove units"
  sudo rm -f "$SERVICE_DIR/videoteam-voctocore.service"
  sudo rm -f "$SERVICE_DIR/videoteam-voctocore-cmds.service"

  echo "clean: daemon-reload"
  sudo systemctl daemon-reload

  echo "clean: rm dir"
  sudo rm -rf "$INSTALL_DIR"
}

case "$MODE" in
  test)
    echo "Please start"
    echo "    sudo journalctl -f -u videoteam-voctocore.service -u videoteam-voctocore-cmds.service -o short-iso"
    echo " in another terminal"
    install
    run_test
    clean
    ;;
  install)
    install
    ;;
  clean)
    clean
    ;;
  *)
    exit 1
    ;;
esac
