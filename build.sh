#!/usr/bin/env bash

set -e
set -o pipefail
set -u

run_makepkg() {
  pushd "$1"
  makepkg -s --noconfirm --noprogressbar
  popd
}

sudo pacman-key --init
sudo pacman-key --populate archlinuxarm

sudo sed -i 's/^#\?\(Color\)/\1/' /etc/pacman.conf
sudo sed -i 's/^#\?\(MAKEFLAGS=\).*$/\1"-j6"/' /etc/makepkg.conf
sudo pacman -Syyu --noconfirm --noprogressbar

run_makepkg "core/linux-aarch64"
