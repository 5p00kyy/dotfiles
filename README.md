# dotfiles

Arch Linux + Hyprland dotfiles with an **electric purple cyberpunk minimal** theme.

## Preview

| Component | Theme |
|-----------|-------|
| Accent Color | `#7f12ff` (Electric Purple) |
| Background | `#0a0a0a` (Deep Black) |
| Text | `#a0a0a0` (Gray) |
| Style | Sharp corners, minimal, dark |

## Features

- **Hyprland** - Snappy animations, purple borders, no blur
- **Waybar** - Bracket notation `[ ]`, GPU/network/now-playing modules
- **EWW** - System stats sidebar (CPU, RAM, GPU, Network)
- **Kitty** - Purple-accented terminal
- **Wofi** - Matching application launcher
- **Swaync** - Matching notification daemon

## Structure

```
.
├── .config
│   ├── eww
│   │   ├── eww.scss
│   │   ├── eww.yuck
│   │   └── scripts
│   │       └── network.sh
│   ├── hypr
│   │   ├── hyprland.conf
│   │   ├── hyprpaper.conf
│   │   └── scripts
│   │       └── wallpaper.sh
│   ├── kitty
│   │   └── kitty.conf
│   ├── pipewire
│   │   └── pipewire.conf
│   ├── swaync
│   │   ├── config.json
│   │   └── style.css
│   ├── waybar
│   │   ├── config
│   │   ├── style.css
│   │   └── scripts
│   │       ├── gpu.sh
│   │       ├── network.sh
│   │       ├── nowplaying.sh
│   │       └── power-menu.sh
│   └── wofi
│       ├── config
│       └── style.css
└── etc
    ├── environment
    └── fstab
```

## Keybinds

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal (Kitty) |
| `Super+R` | App Launcher (Wofi) |
| `Super+Shift+E` | Toggle EWW Sidebar |
| `Super+C` | Close Window |
| `Super+1-9` | Switch Workspace |

## Dependencies

```bash
# Core
yay -S hyprland waybar kitty wofi swaync hyprpaper

# EWW sidebar
yay -S eww jq playerctl

# Fonts
yay -S ttf-jetbrains-mono-nerd
```

## Installation

```bash
# Clone
git clone https://github.com/5p00kyy/dotfiles.git ~/dotfiles

# Copy configs (backup existing first)
cp -r ~/dotfiles/.config/* ~/.config/
```

## System

- **OS:** Arch Linux
- **WM:** Hyprland
- **Bar:** Waybar
- **Terminal:** Kitty
- **Launcher:** Wofi
- **Notifications:** Swaync
- **Widgets:** EWW
