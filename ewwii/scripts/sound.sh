#!/bin/sh

set_vol() {
  if command -v pamixer &>/dev/null; then
    pamixer --set-volume $1
  fi
}

get_vol() {
  if command -v pamixer &>/dev/null; then
    if [ "$(pamixer --get-mute)" = "true" ]; then
      echo 0
    else
      pamixer --get-volume
    fi
  fi
}

if [ -n "$1" ]; then
  set_vol $1
else
  get_vol
fi
