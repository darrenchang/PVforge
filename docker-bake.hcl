group "default" {
  targets = [
    "pvebuilder",
  ]
}

target "pvebuilder" {
  context    = "docker"
  dockerfile = "dockerfile.arm64"
  tags       = [
    "pvebuilder",
  ]
  platforms  = ["linux/arm64"]
  args = {
    BASE_IMAGE = "debian:trixie"
    DEBIAN_VERSION = "trixie"
    RUST_VERSION = "1.94.0"
  }
}
