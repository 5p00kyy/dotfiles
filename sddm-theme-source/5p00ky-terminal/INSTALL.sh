#!/usr/bin/env bash
set -euo pipefail
sudo rm -rf /usr/share/sddm/themes/5p00ky-terminal
sudo cp -a "$HOME/dotfiles/sddm-theme-source/5p00ky-terminal" /usr/share/sddm/themes/5p00ky-terminal
sudo install -d /etc/sddm.conf.d
printf '[Theme]\nCurrent=5p00ky-terminal\n' | sudo tee /etc/sddm.conf.d/zz-5p00ky-terminal.conf >/dev/null
sudo systemctl restart sddm
