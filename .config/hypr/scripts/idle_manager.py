#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
STATE_PATH = HOME / ".config/hypr/idle_state.json"
HYPRIDLE_PATH = HOME / ".config/hypr/hypridle.conf"
WOFI = subprocess.run(["bash", "-lc", "command -v wofi || true"], capture_output=True, text=True).stdout.strip() or "wofi"

DEFAULT = {
    "lock_enabled": True,
    "lock_timeout": 570,
    "screen_off_enabled": True,
    "screen_off_timeout": 600,
    "sleep_enabled": False,
    "sleep_timeout": 2700,
}

PRESETS = {
    "Balanced": {"lock_enabled": True, "lock_timeout": 570, "screen_off_enabled": True, "screen_off_timeout": 600, "sleep_enabled": False, "sleep_timeout": 2700},
    "Long session": {"lock_enabled": True, "lock_timeout": 1200, "screen_off_enabled": True, "screen_off_timeout": 1260, "sleep_enabled": False, "sleep_timeout": 5400},
    "Auto sleep 45m": {"lock_enabled": True, "lock_timeout": 570, "screen_off_enabled": True, "screen_off_timeout": 600, "sleep_enabled": True, "sleep_timeout": 2700},
    "Presentation": {"lock_enabled": False, "lock_timeout": 570, "screen_off_enabled": False, "screen_off_timeout": 600, "sleep_enabled": False, "sleep_timeout": 2700},
}


def fmt_minutes(seconds: int | None) -> str:
    if not seconds:
        return "off"
    m, s = divmod(int(seconds), 60)
    if s:
        return f"{m}m{s:02d}s"
    return f"{m}m"


def load_state() -> dict:
    if not STATE_PATH.exists():
        return DEFAULT.copy()
    try:
        state = json.loads(STATE_PATH.read_text())
    except Exception:
        state = {}
    merged = DEFAULT.copy()
    merged.update(state)
    return merged


def save_state(state: dict) -> None:
    STATE_PATH.write_text(json.dumps(state, indent=2) + "\n")


def normalize_state(state: dict) -> dict:
    if state.get("lock_timeout", 0) <= 0:
        state["lock_timeout"] = DEFAULT["lock_timeout"]
    if state.get("screen_off_timeout", 0) <= 0:
        state["screen_off_timeout"] = max(state["lock_timeout"] + 30, DEFAULT["screen_off_timeout"])
    if state.get("sleep_timeout", 0) <= 0:
        state["sleep_timeout"] = DEFAULT["sleep_timeout"]
    if state.get("lock_enabled") and state.get("screen_off_enabled") and state["screen_off_timeout"] <= state["lock_timeout"]:
        state["screen_off_timeout"] = state["lock_timeout"] + 30
    if state.get("sleep_enabled"):
        floor = state["screen_off_timeout"] if state.get("screen_off_enabled") else state["lock_timeout"]
        if state["sleep_timeout"] <= floor:
            state["sleep_timeout"] = floor + 60
    return state


def render_config(state: dict) -> str:
    state = normalize_state(state)
    before_sleep = "loginctl lock-session" if state["lock_enabled"] else "true"
    lines = [
        "general {",
        "    lock_cmd = pidof hyprlock || hyprlock",
        f"    before_sleep_cmd = {before_sleep}",
        "    after_sleep_cmd = hyprctl dispatch dpms on",
        "    ignore_dbus_inhibit = false",
        "    ignore_systemd_inhibit = false",
        "}",
        "",
    ]
    if state["lock_enabled"]:
        lines += [
            "listener {",
            f"    timeout = {int(state['lock_timeout'])}",
            "    on-timeout = loginctl lock-session",
            "}",
            "",
        ]
    if state["screen_off_enabled"]:
        lines += [
            "listener {",
            f"    timeout = {int(state['screen_off_timeout'])}",
            "    on-timeout = hyprctl dispatch dpms off",
            "    on-resume = hyprctl dispatch dpms on",
            "}",
            "",
        ]
    if state["sleep_enabled"]:
        lines += [
            "listener {",
            f"    timeout = {int(state['sleep_timeout'])}",
            "    on-timeout = systemctl suspend",
            "}",
            "",
        ]
    return "\n".join(lines).rstrip() + "\n"


def restart_hypridle() -> None:
    subprocess.run(["pkill", "-x", "hypridle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.Popen(["hypridle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def notify(msg: str) -> None:
    subprocess.run(["notify-send", "Idle controls", msg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def apply(state: dict, message: str | None = None) -> None:
    state = normalize_state(state)
    save_state(state)
    HYPRIDLE_PATH.write_text(render_config(state))
    restart_hypridle()
    if message:
        notify(message)


def waybar() -> None:
    state = normalize_state(load_state())
    lock = fmt_minutes(state["lock_timeout"]) if state["lock_enabled"] else "off"
    display_off = fmt_minutes(state["screen_off_timeout"]) if state["screen_off_enabled"] else "off"
    sleep = fmt_minutes(state["sleep_timeout"]) if state["sleep_enabled"] else "off"
    text = f"[ IDLE L:{lock} D:{display_off} S:{sleep} ]"
    classes = []
    if not state["lock_enabled"]:
        classes.append("lock-off")
    if not state["screen_off_enabled"]:
        classes.append("display-off")
    if not state["sleep_enabled"]:
        classes.append("sleep-off")
    if not classes:
        classes.append("active")
    tooltip = "\n".join([
        f"Auto lock: {'on' if state['lock_enabled'] else 'off'} ({lock})",
        f"Display off: {'on' if state['screen_off_enabled'] else 'off'} ({display_off})",
        f"Auto sleep: {'on' if state['sleep_enabled'] else 'off'} ({sleep})",
        "Left click: open control panel",
        "Right click: toggle auto sleep",
        "Middle click: toggle auto lock",
    ])
    print(json.dumps({"text": text, "tooltip": tooltip, "class": classes}))


def menu_choice(options: list[str], prompt: str) -> str | None:
    proc = subprocess.run([WOFI, "--dmenu", "--prompt", prompt], input="\n".join(options), text=True, capture_output=True)
    if proc.returncode != 0:
        return None
    return proc.stdout.strip()


def set_lock_time(seconds: int) -> None:
    state = load_state()
    state["lock_enabled"] = True
    state["lock_timeout"] = seconds
    if state.get("screen_off_enabled") and state.get("screen_off_timeout", 0) <= seconds:
        state["screen_off_timeout"] = seconds + 30
    apply(state, f"Auto lock set to {fmt_minutes(seconds)}")


def set_display_off(seconds: int | None) -> None:
    state = load_state()
    state["screen_off_enabled"] = seconds is not None
    if seconds is not None:
        state["screen_off_timeout"] = seconds
        if state.get("lock_enabled") and state["screen_off_timeout"] <= state["lock_timeout"]:
            state["screen_off_timeout"] = state["lock_timeout"] + 30
        apply(state, f"Display off set to {fmt_minutes(state['screen_off_timeout'])}")
    else:
        apply(state, "Display auto-off disabled")


def set_sleep(seconds: int | None) -> None:
    state = load_state()
    state["sleep_enabled"] = seconds is not None
    if seconds is not None:
        state["sleep_timeout"] = seconds
        apply(state, f"Auto sleep set to {fmt_minutes(state['sleep_timeout'])}")
    else:
        apply(state, "Auto sleep disabled")


def open_menu() -> None:
    state = normalize_state(load_state())
    choice = menu_choice([
        "Balanced",
        "Long session",
        "Auto sleep 45m",
        "Presentation",
        f"Toggle auto lock ({'on' if state['lock_enabled'] else 'off'})",
        f"Toggle display off ({'on' if state['screen_off_enabled'] else 'off'})",
        f"Toggle auto sleep ({'on' if state['sleep_enabled'] else 'off'})",
        "Set auto lock time",
        "Set display-off time",
        "Set auto sleep time",
    ], "Idle")
    if not choice:
        return
    if choice in PRESETS:
        state.update(PRESETS[choice])
        apply(state, f"Applied {choice} idle preset")
        return
    if choice.startswith("Toggle auto lock"):
        toggle_lock(); return
    if choice.startswith("Toggle display off"):
        toggle_display_off(); return
    if choice.startswith("Toggle auto sleep"):
        toggle_sleep(); return
    if choice == "Set auto lock time":
        sub = menu_choice(["5m", "10m", "15m", "20m", "30m"], "Lock time")
        mapping = {"5m": 300, "10m": 600, "15m": 900, "20m": 1200, "30m": 1800}
        if sub in mapping:
            set_lock_time(mapping[sub])
        return
    if choice == "Set display-off time":
        sub = menu_choice(["off", "1m", "2m", "5m", "10m", "15m", "20m", "30m"], "Display off")
        mapping = {"1m": 60, "2m": 120, "5m": 300, "10m": 600, "15m": 900, "20m": 1200, "30m": 1800}
        if sub == "off":
            set_display_off(None)
        elif sub in mapping:
            set_display_off(mapping[sub])
        return
    if choice == "Set auto sleep time":
        sub = menu_choice(["off", "30m", "45m", "60m", "90m"], "Sleep time")
        mapping = {"30m": 1800, "45m": 2700, "60m": 3600, "90m": 5400}
        if sub == "off":
            set_sleep(None)
        elif sub in mapping:
            set_sleep(mapping[sub])
        return


def toggle_lock() -> None:
    state = load_state()
    state["lock_enabled"] = not state["lock_enabled"]
    apply(state, f"Auto lock {'enabled' if state['lock_enabled'] else 'disabled'}")


def toggle_display_off() -> None:
    state = load_state()
    state["screen_off_enabled"] = not state["screen_off_enabled"]
    apply(state, f"Display auto-off {'enabled' if state['screen_off_enabled'] else 'disabled'}")


def toggle_sleep() -> None:
    state = load_state()
    state["sleep_enabled"] = not state["sleep_enabled"]
    apply(state, f"Auto sleep {'enabled' if state['sleep_enabled'] else 'disabled'}")


def status() -> None:
    print(json.dumps(normalize_state(load_state()), indent=2))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "waybar"
    if cmd == "waybar":
        waybar()
    elif cmd == "menu":
        open_menu()
    elif cmd == "toggle-lock":
        toggle_lock()
    elif cmd == "toggle-display-off":
        toggle_display_off()
    elif cmd == "toggle-sleep":
        toggle_sleep()
    elif cmd == "status":
        status()
    else:
        raise SystemExit(f"unknown command: {cmd}")
