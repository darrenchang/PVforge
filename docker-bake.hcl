group "default" {
  targets = [
    "builder-base",
    "pve-builder",
  ]
}

target "builder-base" {
  context    = "docker"
  dockerfile = "dockerfile.builder-base.arm64"
  tags       = [
    "builder-base",
  ]
  platforms  = ["linux/arm64"]
  args = {
    BASE_IMAGE = "debian:trixie"
    DEBIAN_VERSION = "trixie"
    RUST_VERSION = "1.94.0"
    LLVM_VERSION = "22.1.2"
  }
}

target "pve-builder" {
  context    = "."
  contexts = {
    builder-base = "target:builder-base"
  }
  dockerfile = "docker/dockerfile.pve-builder.arm64"
  args = {
    BASE_IMAGE = "builder-base:latest"
  }
  tags       = [
    "pve-builder",
  ]
  platforms  = ["linux/arm64"]
}
