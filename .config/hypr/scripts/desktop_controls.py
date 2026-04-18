#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk

HOME = Path.home()
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", str(HOME / ".local/state"))) / "hypr"
SCRIPTS_DIR = HOME / ".config/hypr/scripts"
IDLE_MANAGER_PATH = SCRIPTS_DIR / "idle_manager.py"
DISPLAY_SCRIPT = SCRIPTS_DIR / "display-mode.sh"
ACCENT_SCRIPT = SCRIPTS_DIR / "accent-theme.sh"
DISPLAY_STATE = STATE_DIR / "display-mode"
ACCENT_STATE = STATE_DIR / "accent-theme"

LOCK_OPTIONS = [("5m", 300), ("10m", 600), ("15m", 900), ("20m", 1200), ("30m", 1800)]
DISPLAY_OFF_OPTIONS = [("1m", 60), ("2m", 120), ("5m", 300), ("10m", 600), ("15m", 900), ("20m", 1200), ("30m", 1800)]
SLEEP_OPTIONS = [("30m", 1800), ("45m", 2700), ("60m", 3600), ("90m", 5400)]
DISPLAY_MODES = [
    ("desk", "Desk 1440p 90Hz"),
    ("desk-165", "Desk 1440p 165Hz"),
    ("dual", "Dual monitor"),
    ("tv-extend", "TV extend"),
    ("tv-mirror", "TV mirror"),
]


def load_idle_module():
    spec = importlib.util.spec_from_file_location("idle_manager", IDLE_MANAGER_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


IDLE = load_idle_module()


def read_state(path: Path, default: str) -> str:
    try:
        return path.read_text().strip() or default
    except Exception:
        return default


def run(cmd: list[str]) -> None:
    subprocess.run([str(c) for c in cmd], check=True)


def get_outputs() -> str:
    try:
        raw = subprocess.check_output(["hyprctl", "-j", "monitors"], text=True)
        data = json.loads(raw)
    except Exception:
        return "Unable to read active outputs"
    parts = []
    for item in data:
        name = item.get("name", "?")
        width = item.get("width", "?")
        height = item.get("height", "?")
        refresh = item.get("refreshRate", 0)
        focused = " focused" if item.get("focused") else ""
        parts.append(f"{name} {width}x{height}@{refresh:.0f}{focused}")
    return "\n".join(parts) if parts else "No outputs reported"


class ControlsWindow(Gtk.Window):
    def __init__(self, initial_tab: str = "idle") -> None:
        super().__init__(title="Desktop controls")
        self.set_default_size(620, 420)
        self.set_border_width(12)
        self.connect("destroy", Gtk.main_quit)

        provider = Gtk.CssProvider()
        provider.load_from_data(b"""
            window { background: #0d1117; color: #e6edf3; }
            notebook > header { margin-bottom: 8px; }
            .section { padding: 10px; }
            .muted { color: #8b949e; }
            .title { font-weight: 700; font-size: 15px; }
            button.suggested-action { font-weight: 700; }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(root)

        title = Gtk.Label(label="Quick desktop controls")
        title.get_style_context().add_class("title")
        title.set_xalign(0)
        root.pack_start(title, False, False, 0)

        subtitle = Gtk.Label(label="Persistent controls for idle, display profiles, and accent theme.")
        subtitle.get_style_context().add_class("muted")
        subtitle.set_xalign(0)
        root.pack_start(subtitle, False, False, 0)

        self.notebook = Gtk.Notebook()
        root.pack_start(self.notebook, True, True, 0)

        self.idle_tab = self.build_idle_tab()
        self.display_tab = self.build_display_tab()
        self.accent_tab = self.build_accent_tab()

        self.notebook.append_page(self.idle_tab, Gtk.Label(label="Idle"))
        self.notebook.append_page(self.display_tab, Gtk.Label(label="Display"))
        self.notebook.append_page(self.accent_tab, Gtk.Label(label="Accent"))

        tab_map = {"idle": 0, "display": 1, "accent": 2}
        self.notebook.set_current_page(tab_map.get(initial_tab, 0))

        self.refresh_all()

    def labeled_row(self, grid, row, label_text, widget):
        label = Gtk.Label(label=label_text)
        label.set_xalign(0)
        grid.attach(label, 0, row, 1, 1)
        grid.attach(widget, 1, row, 1, 1)

    def build_idle_tab(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.get_style_context().add_class("section")

        self.idle_summary = Gtk.Label()
        self.idle_summary.set_xalign(0)
        self.idle_summary.set_line_wrap(True)
        box.pack_start(self.idle_summary, False, False, 0)

        presets_row = Gtk.Box(spacing=8)
        self.idle_preset = Gtk.ComboBoxText()
        for name in IDLE.PRESETS:
            self.idle_preset.append_text(name)
        self.idle_preset.set_active(0)
        preset_btn = Gtk.Button(label="Apply preset")
        preset_btn.connect("clicked", self.on_apply_preset)
        presets_row.pack_start(self.idle_preset, False, False, 0)
        presets_row.pack_start(preset_btn, False, False, 0)
        box.pack_start(presets_row, False, False, 0)

        grid = Gtk.Grid(column_spacing=12, row_spacing=10)
        box.pack_start(grid, False, False, 0)

        self.lock_check = Gtk.CheckButton(label="Enable auto lock")
        self.lock_combo = Gtk.ComboBoxText()
        for label, _ in LOCK_OPTIONS:
            self.lock_combo.append_text(label)
        self.lock_combo.set_active(1)
        self.labeled_row(grid, 0, "Auto lock", self.lock_check)
        self.labeled_row(grid, 1, "Lock time", self.lock_combo)

        self.display_check = Gtk.CheckButton(label="Enable display auto-off")
        self.display_combo = Gtk.ComboBoxText()
        for label, _ in DISPLAY_OFF_OPTIONS:
            self.display_combo.append_text(label)
        self.display_combo.set_active(3)
        self.labeled_row(grid, 2, "Display off", self.display_check)
        self.labeled_row(grid, 3, "Display-off time", self.display_combo)

        self.sleep_check = Gtk.CheckButton(label="Enable auto sleep")
        self.sleep_combo = Gtk.ComboBoxText()
        for label, _ in SLEEP_OPTIONS:
            self.sleep_combo.append_text(label)
        self.sleep_combo.set_active(1)
        self.labeled_row(grid, 4, "Auto sleep", self.sleep_check)
        self.labeled_row(grid, 5, "Sleep time", self.sleep_combo)

        self.lock_check.connect("toggled", lambda *_: self.sync_idle_controls())
        self.display_check.connect("toggled", lambda *_: self.sync_idle_controls())
        self.sleep_check.connect("toggled", lambda *_: self.sync_idle_controls())

        buttons = Gtk.Box(spacing=8)
        apply_btn = Gtk.Button(label="Apply idle settings")
        apply_btn.get_style_context().add_class("suggested-action")
        apply_btn.connect("clicked", self.on_apply_idle)
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", lambda *_: self.refresh_idle())
        buttons.pack_start(apply_btn, False, False, 0)
        buttons.pack_start(refresh_btn, False, False, 0)
        box.pack_end(buttons, False, False, 0)
        return box

    def build_display_tab(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.get_style_context().add_class("section")
        self.display_summary = Gtk.Label()
        self.display_summary.set_xalign(0)
        self.display_summary.set_line_wrap(True)
        box.pack_start(self.display_summary, False, False, 0)

        self.display_outputs = Gtk.Label()
        self.display_outputs.set_xalign(0)
        self.display_outputs.set_line_wrap(True)
        self.display_outputs.get_style_context().add_class("muted")
        box.pack_start(self.display_outputs, False, False, 0)

        row = Gtk.Box(spacing=8)
        self.display_combo_box = Gtk.ComboBoxText()
        for key, label in DISPLAY_MODES:
            self.display_combo_box.append(key, f"{label} ({key})")
        row.pack_start(self.display_combo_box, True, True, 0)
        apply_btn = Gtk.Button(label="Apply display profile")
        apply_btn.get_style_context().add_class("suggested-action")
        apply_btn.connect("clicked", self.on_apply_display)
        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", lambda *_: self.refresh_display())
        row.pack_start(apply_btn, False, False, 0)
        row.pack_start(refresh_btn, False, False, 0)
        box.pack_start(row, False, False, 0)
        return box

    def build_accent_tab(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.get_style_context().add_class("section")
        self.accent_summary = Gtk.Label()
        self.accent_summary.set_xalign(0)
        box.pack_start(self.accent_summary, False, False, 0)

        accent_names = subprocess.check_output([str(ACCENT_SCRIPT), "list"], text=True).split()
        grid = Gtk.Grid(column_spacing=8, row_spacing=8)
        box.pack_start(grid, False, False, 0)
        for idx, name in enumerate(accent_names):
            btn = Gtk.Button(label=name.capitalize())
            btn.connect("clicked", self.on_apply_accent, name)
            grid.attach(btn, idx % 3, idx // 3, 1, 1)

        refresh_btn = Gtk.Button(label="Refresh")
        refresh_btn.connect("clicked", lambda *_: self.refresh_accent())
        box.pack_end(refresh_btn, False, False, 0)
        return box

    def select_combo_value(self, combo, options, target):
        for idx, (_, value) in enumerate(options):
            if value == target:
                combo.set_active(idx)
                return
        combo.set_active(0)

    def active_combo_value(self, combo, options):
        idx = combo.get_active()
        if idx < 0:
            return options[0][1]
        return options[idx][1]

    def sync_idle_controls(self):
        self.lock_combo.set_sensitive(self.lock_check.get_active())
        self.display_combo.set_sensitive(self.display_check.get_active())
        self.sleep_combo.set_sensitive(self.sleep_check.get_active())

    def refresh_idle(self):
        state = IDLE.normalize_state(IDLE.load_state())
        self.lock_check.set_active(bool(state["lock_enabled"]))
        self.display_check.set_active(bool(state["screen_off_enabled"]))
        self.sleep_check.set_active(bool(state["sleep_enabled"]))
        self.select_combo_value(self.lock_combo, LOCK_OPTIONS, state["lock_timeout"])
        self.select_combo_value(self.display_combo, DISPLAY_OFF_OPTIONS, state["screen_off_timeout"])
        self.select_combo_value(self.sleep_combo, SLEEP_OPTIONS, state["sleep_timeout"])
        self.sync_idle_controls()
        self.idle_summary.set_text(
            f"Current: lock {'on' if state['lock_enabled'] else 'off'} ({IDLE.fmt_minutes(state['lock_timeout'])}), "
            f"display off {'on' if state['screen_off_enabled'] else 'off'} ({IDLE.fmt_minutes(state['screen_off_timeout'])}), "
            f"sleep {'on' if state['sleep_enabled'] else 'off'} ({IDLE.fmt_minutes(state['sleep_timeout'])})."
        )

    def refresh_display(self):
        current = read_state(DISPLAY_STATE, "desk")
        self.display_combo_box.set_active_id(current)
        self.display_summary.set_text(f"Current profile: {current}")
        self.display_outputs.set_text("Active outputs:\n" + get_outputs())

    def refresh_accent(self):
        current = read_state(ACCENT_STATE, "green")
        self.accent_summary.set_text(f"Current accent: {current}")

    def refresh_all(self):
        self.refresh_idle()
        self.refresh_display()
        self.refresh_accent()

    def on_apply_preset(self, _button):
        name = self.idle_preset.get_active_text()
        if not name:
            return
        state = dict(IDLE.PRESETS[name])
        IDLE.apply(state, f"Applied {name} idle preset")
        self.refresh_idle()

    def on_apply_idle(self, _button):
        state = IDLE.normalize_state(IDLE.load_state())
        state["lock_enabled"] = self.lock_check.get_active()
        state["screen_off_enabled"] = self.display_check.get_active()
        state["sleep_enabled"] = self.sleep_check.get_active()
        state["lock_timeout"] = self.active_combo_value(self.lock_combo, LOCK_OPTIONS)
        state["screen_off_timeout"] = self.active_combo_value(self.display_combo, DISPLAY_OFF_OPTIONS)
        state["sleep_timeout"] = self.active_combo_value(self.sleep_combo, SLEEP_OPTIONS)
        IDLE.apply(state, "Idle settings updated")
        self.refresh_idle()

    def on_apply_display(self, _button):
        mode = self.display_combo_box.get_active_id()
        if not mode:
            return
        run([DISPLAY_SCRIPT, "apply", mode])
        self.refresh_display()

    def on_apply_accent(self, _button, name):
        run([ACCENT_SCRIPT, "apply", name])
        self.refresh_accent()


def main():
    initial_tab = sys.argv[1] if len(sys.argv) > 1 else "idle"
    win = ControlsWindow(initial_tab)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
