group "default" {
  targets = []
}

target "_makepkg" {
  dockerfile = "Dockerfile"
  target = "pkgs"
  output = [{ type = "local", dest = "./build" }]
}

target "repo" {
  dockerfile = "Dockerfile"
  platforms = ["linux/arm64"]
  target = "repo"
}

target "linux-nanopi-r4s" {
  inherits = ["_makepkg"]
  args = {
    PKGBUILD_DIR = "linux-nanopi-r4s"
    GPG_LOCATE_KEYS = "torvalds@kernel.org gregkh@kernel.org"
  }
  platforms = ["linux/arm64"]
}

target "ndppd-git" {
  inherits = ["_makepkg"]
  args = {
    PKGBUILD_DIR = "ndppd-git"
  }
  platforms = ["linux/arm64"]
}

target "wilc-firmware" {
  inherits = ["_makepkg"]
  args = {
    PKGBUILD_DIR = "wilc-firmware"
  }
}
