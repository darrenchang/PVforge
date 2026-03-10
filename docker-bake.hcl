group "default" {
  targets = [
    "pvebuilder",
  ]
}

variable "DEBIAN_APT" {
  default = "http://mirrors.ustc.edu.cn"
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
    DEBIAN_APT = "${DEBIAN_APT}"
  }
}
