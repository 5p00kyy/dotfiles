#!/usr/bin/env bash
set -euo pipefail

WINDOW="sidebar"

if ! eww ping >/dev/null 2>&1; then
  eww daemon >/dev/null 2>&1 || true
  for _ in {1..10}; do
    eww ping >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

if eww active-windows 2>/dev/null | grep -q "^[^:]*: ${WINDOW}$"; then
  eww close "$WINDOW"
else
  eww open "$WINDOW"
fi
