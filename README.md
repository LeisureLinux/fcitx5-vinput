<div align="center">

# fcitx5-vinput

**Voice input for Fcitx5 — local and cloud ASR, LLM rewriting, cross-distro packages**

[![License](https://img.shields.io/github/license/xifan2333/fcitx5-vinput)](LICENSE)
[![CI](https://github.com/xifan2333/fcitx5-vinput/actions/workflows/release.yml/badge.svg)](https://github.com/xifan2333/fcitx5-vinput/actions/workflows/release.yml)
[![Release](https://img.shields.io/github/v/release/xifan2333/fcitx5-vinput)](https://github.com/xifan2333/fcitx5-vinput/releases)
[![AUR](https://img.shields.io/aur/version/fcitx5-vinput-bin)](https://aur.archlinux.org/packages/fcitx5-vinput-bin)
[![Downloads](https://img.shields.io/github/downloads/xifan2333/fcitx5-vinput/total)](https://github.com/xifan2333/fcitx5-vinput/releases)

[English](README.md) | [中文](README_zh.md) | [Documentation](https://xifan2333.github.io/fcitx5-vinput/)

https://github.com/user-attachments/assets/5a548a68-153c-4842-bab6-926f30bb720e

</div>

## Features

- **Two trigger modes** — tap to toggle recording, or hold to push-to-talk
- **Local & cloud ASR** — offline [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) models or cloud providers (Doubao, Aliyun Bailian, ElevenLabs, OpenAI-compatible), switchable at runtime from the command palette (`Shift_R` → `/asr`)
- **LLM post-processing** — error correction, formatting, translation via scenes
- **Command mode** — select text, speak an instruction, release to apply
- **GUI & CLI** — `vinput-gui` for quick setup, `vinput` CLI for full control
- **Cross-distro** — Arch, Fedora, Ubuntu/Debian, Nix, Flatpak

## Installation

### Arch Linux ([archlinuxcn](https://www.archlinuxcn.org/archlinux-cn-repo-and-mirror/) / AUR)

If you use the [archlinuxcn](https://www.archlinuxcn.org/archlinux-cn-repo-and-mirror/) repository, install the repo-built package:

```bash
sudo pacman -S fcitx5-vinput
```

The AUR binary package is also available:

```bash
# Full version (with local sherpa-onnx runtime)
yay -S fcitx5-vinput-bin

# Lite version (cloud-only, zero local ONNX runtime)
yay -S fcitx5-vinput-lite-bin
```

### Fedora (COPR)

```bash
sudo dnf copr enable xifan/fcitx5-vinput-bin

# Full version (with local sherpa-onnx runtime)
sudo dnf install fcitx5-vinput

# Lite version (cloud-only, zero local ONNX runtime)
sudo dnf install fcitx5-vinput-lite
```

### Ubuntu 24.04 (PPA)

```bash
sudo add-apt-repository ppa:xifan233/ppa
sudo apt update

# Full version (with local sherpa-onnx runtime)
sudo apt install fcitx5-vinput

# Lite version (cloud-only, zero local ONNX runtime)
sudo apt install fcitx5-vinput-lite
```

### Ubuntu / Debian (manual)

```bash
# Download latest .deb from GitHub Releases
# Full version (with local sherpa-onnx runtime):
sudo dpkg -i fcitx5-vinput_*.deb
sudo apt-get install -f

# Lite version (cloud-only, zero local ONNX runtime):
sudo dpkg -i fcitx5-vinput-lite_*.deb
sudo apt-get install -f
```

### Nix (flake)

Supports `x86_64-linux` and `aarch64-linux`. Both full and lite packages are cached on Cachix.

```nix
inputs.fcitx5-vinput.url = "github:xifan2333/fcitx5-vinput";

# Full version (default):
#   inputs.fcitx5-vinput.packages.${system}.default
# Lite version (cloud-only, zero local ONNX runtime):
#   inputs.fcitx5-vinput.packages.${system}.fcitx5-vinput-lite
```

Binary cache via [Cachix](https://fcitx5-vinput.cachix.org):

```nix
nixConfig = {
  extra-substituters = [ "https://fcitx5-vinput.cachix.org" ];
  extra-trusted-public-keys = [ "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU=" ];
};
```

Full Home Manager example in the [install docs](https://xifan2333.github.io/fcitx5-vinput/install/).

### Flatpak

```bash
flatpak remote-add --if-not-exists xifan https://xifan2333.github.io/flatpak-auto/xifan.flatpakrepo

# Full version (with local sherpa-onnx runtime)
flatpak install https://xifan2333.github.io/flatpak-auto/refs/org.fcitx.Fcitx5.Addon.Vinput.flatpakref

# Lite version (cloud-only, zero local ONNX runtime)
flatpak install https://xifan2333.github.io/flatpak-auto/refs/org.fcitx.Fcitx5.Addon.Vinput.Lite.flatpakref
```

After installation, grant the extra permissions and restart Fcitx5:

```bash
flatpak override --user --filesystem=xdg-run/pipewire-0 org.fcitx.Fcitx5
flatpak override --user --filesystem=xdg-config/systemd:create org.fcitx.Fcitx5
flatpak override --user --filesystem=xdg-cache org.fcitx.Fcitx5
flatpak kill org.fcitx.Fcitx5
```

### GitHub Releases

Download the package for your system from [GitHub Releases](https://github.com/xifan2333/fcitx5-vinput/releases/latest) (both full and lite variants are provided):

- **Debian / Linux Mint / Ubuntu (other)**: `.deb` (`fcitx5-vinput_*.deb` / `fcitx5-vinput-lite_*.deb`)
- **openSUSE / Fedora (other)**: `.rpm` (`fcitx5-vinput-*.rpm` / `fcitx5-vinput-lite-*.rpm`)
- **Arch-based**: `.pkg.tar.zst` (`fcitx5-vinput-*.pkg.tar.zst` / `fcitx5-vinput-lite-*.pkg.tar.zst`)
- **Flatpak**: `.flatpak` (`fcitx5-vinput.flatpak` / `fcitx5-vinput-lite.flatpak`)
- **Generic Linux**: `tar.gz` (`*_bundled.tar.gz` / `fcitx5-vinput-lite-*.tar.gz`)

### Build from source

**Dependencies:** cmake, fcitx5, pipewire, libcurl, nlohmann-json, CLI11, Qt6

```bash
# Full version (with local sherpa-onnx ASR runtime)
sudo bash scripts/build-sherpa-onnx.sh
cmake --preset release-clang-mold
cmake --build --preset release-clang-mold
sudo cmake --install build

# Lite version (pure cloud ASR + LLM, zero sherpa-onnx dependency)
cmake --preset release-clang-mold -DVINPUT_ENABLE_LOCAL_ASR=OFF
cmake --build --preset release-clang-mold
sudo cmake --install build
```

### Building a `.deb` on a Debian / Ubuntu host

This path packages directly on the host with its own CMake/Ninja toolchain. It uses no
container runtime at any point — no Docker, no Podman, no chroot — and produces the same
`cpack`-generated `.deb` that the release workflow publishes.

Install the build dependencies first (all of them are in the Debian/Ubuntu archives):

```bash
sudo apt install -y \
  clang cmake mold ninja-build pkg-config gettext dpkg-dev file \
  curl jq bzip2 \
  libcurl4-openssl-dev libssl-dev libarchive-dev libpipewire-0.3-dev libsystemd-dev \
  libfcitx5core-dev libfcitx5config-dev libfcitx5utils-dev fcitx5-modules-dev \
  libcli11-dev nlohmann-json3-dev \
  qt6-base-dev qt6-tools-dev qt6-tools-dev-tools
```

If your host already runs a newer `libcurl` from backports, `apt` will refuse to install the
matching `libcurl4-openssl-dev` from the stable suite. Install the development package from
the same suite instead, e.g. `libcurl4-openssl-dev/trixie-backports`.

Stage the sherpa-onnx runtime into a local prefix. This is needed for the full build only;
skip it for the Lite build. Nothing is installed into `/usr`, and no `sudo` is required:

```bash
prefix="$HOME/.cache/fcitx5-vinput/sherpa-onnx"
bash scripts/build-sherpa-onnx.sh "" "${prefix}"
export VINPUT_CMAKE_PREFIX_PATH="${prefix}"
```

If GitHub is not reachable from your host, pre-download
`sherpa-onnx-v<version>-linux-x64-shared-no-tts.tar.bz2` with any mirror-capable client and
pass the archive path as the third argument, e.g.
`bash scripts/build-sherpa-onnx.sh "" "${prefix}" /path/to/sherpa.tar.bz2`. The script still
verifies the archive against the upstream digest.

Configure, build, and package. The package version comes from `VERSION`:

```bash
version="$(tr -d '\n' < VERSION)"
cmake --preset release-clang-mold \
  -DVINPUT_ENABLE_LOCAL_ASR=ON \
  -DVINPUT_PROJECT_VERSION="${version}" \
  -DVINPUT_PACKAGE_RELEASE=1 \
  -DVINPUT_PACKAGE_CONTACT="$(git config user.name) <$(git config user.email)>" \
  -DVINPUT_PACKAGE_HOMEPAGE_URL=https://github.com/xifan2333/fcitx5-vinput
cmake --build --preset release-clang-mold
cpack --config build/CPackConfig.cmake -G DEB -B dist
```

The result is `dist/fcitx5-vinput_<version>-1_amd64.deb` (the host architecture, `amd64` on
x86_64). For the Lite build, pass `-DVINPUT_ENABLE_LOCAL_ASR=OFF`, drop the sherpa-onnx step,
and expect `dist/fcitx5-vinput-lite_<version>-1_amd64.deb`.

The package ships `/usr/share/doc/fcitx5-vinput/{copyright,changelog.Debian.gz,changelog.gz}`,
gzipped man pages and stripped binaries. Policies that the DEB generator does not apply on its
own (documentation metadata, man page compression, stripping of the bundled sherpa-onnx
libraries, and 0755/0644 permissions) are handled by
`packaging/cpack/CPackDebianDocs.cmake`, a `CPACK_PRE_BUILD_SCRIPTS` hook that only runs for
the DEB generator. The long description comes from `packaging/cpack/description.txt` and the
DEP-5 copyright from `packaging/cpack/copyright`.

## Quick start

```bash
systemctl --user enable --now vinput-daemon.service
fcitx5 -r
```

Open **Vinput GUI** → **Resources → Models** → download and activate a model. Then:

- **Tap** `Alt_R` — start/stop recording
- **Hold** `Alt_R` — push-to-talk

## Key bindings

| Key | Default | Function |
|-----|---------|----------|
| Trigger Key | `Alt_R` | Tap to toggle recording; hold to push-to-talk |
| Command Key | `Control_R` | Hold after selecting text to modify with voice |
| Command Palette Key | `Shift_R` | Open unified command palette (/model, /asr, /scene, /proc) |

All keys can be customized in Fcitx5 configuration.

## Documentation

For ASR configuration, scenes & LLM setup, CLI reference, and registry contribution guide, see the [documentation site](https://xifan2333.github.io/fcitx5-vinput/).

## License

[GPL-3.0](LICENSE)

## Contributors

<a href="https://github.com/xifan2333/fcitx5-vinput/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=xifan2333/fcitx5-vinput" />
</a>

## Sponsor

If this project has been helpful to you, feel free to support it.

<img src="https://raw.githubusercontent.com/xifan2333/xifan2333/main/assets/donate.png" alt="Donate" width="300" />
