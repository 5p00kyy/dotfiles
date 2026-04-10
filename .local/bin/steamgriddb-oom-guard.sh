#!/bin/bash
set -euo pipefail
PATTERN="/home/pacey/homebrew/plugins/decky-steamgriddb/main.py"
MAX_RSS_KB="${MAX_RSS_KB:-1500000}"
INTERVAL="${INTERVAL:-5}"

while true; do
  pid="$(pgrep -f "$PATTERN" | head -n1 || true)"
  if [[ -n "$pid" ]]; then
    rss_kb="$(ps -o rss= -p "$pid" | tr -d " " || echo 0)"
    if [[ "$rss_kb" =~ ^[0-9]+$ ]] && (( rss_kb > MAX_RSS_KB )); then
      logger -t steamgriddb-oom-guard "killing pid=$pid rss_kb=$rss_kb threshold=$MAX_RSS_KB"
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
    fi
  fi
  sleep "$INTERVAL"
done
