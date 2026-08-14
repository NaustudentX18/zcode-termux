# ZCode for Termux

Run [ZCode](https://zcode.z.ai) (the GLM-5.3 AI coding IDE) on your Android phone via Termux + proot Debian.

## Quick Start

```bash
# 1. Install Termux from F-Droid (NOT Play Store — that version is deprecated)
#    https://f-droid.org/packages/com.termux/

# 2. Install git
pkg install git -y

# 3. Clone this repo
git clone https://github.com/NaustudentX18/zcode-termux.git
cd zcode-termux

# 4. Run the installer
bash install.sh

# 5. Launch ZCode
zcode
```

## What It Does

1. Installs `proot-distro` + Debian ARM64 inside Termux
2. Downloads the official ZCode Linux ARM64 `.deb` (v3.7.7)
3. Installs ZCode + all Electron runtime dependencies inside the proot
4. Creates a `zcode` launcher command and a Termux:Widget home shortcut
5. Starts Termux:X11 for display, then launches ZCode inside the proot

## Requirements

| Requirement | Details |
|---|---|
| **Architecture** | aarch64 (most modern Android phones) |
| **Termux** | From [F-Droid](https://f-droid.org/packages/com.termux/) only |
| **Storage** | ~2 GB free (Debian proot + ZCode .deb) |
| **RAM** | 4 GB+ recommended (Electron is heavy) |
| **Display** | Termux:X11 (installed automatically) |
| **GLM API key** | Get one at [z.ai/subscribe](https://z.ai/subscribe) |

## How It Works

ZCode is an Electron desktop app (Chromium + Node.js). Android can't run Electron natively, so this setup uses `proot-distro` to create a Debian ARM64 chroot inside Termux, installs the Linux ARM64 build there, and launches it with Termux:X11 providing the display server.

```
┌─────────────────────────────────────────┐
│  Android                                │
│  ┌───────────────────────────────────┐  │
│  │  Termux (your terminal)           │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  proot-distro → Debian       │  │  │
│  │  │  ┌───────────────────────┐   │  │  │
│  │  │  │  ZCode (Electron)      │   │  │  │
│  │  │  │  Chromium + Node.js   │   │  │  │
│  │  │  └───────────────────────┘   │  │  │
│  │  └─────────────────────────────┘  │  │
│  │  Termux:X11 ← display server      │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Launching

### From terminal
```bash
zcode
```

### From home screen
Add the **Termux:Widget** add-on, then add a widget to your home screen. The "ZCode" shortcut will appear.

## Troubleshooting

<details>
<summary><b>ZCode won't launch / blank screen</b></summary>

```bash
# Make sure Termux:X11 is running
termux-x11 :0 &

# Try launching manually to see errors
proot-distro login debian --shared-tmp -- bash -c "DISPLAY=:0 /usr/bin/zcode --no-sandbox"
```
</details>

<details>
<summary><b>dpkg dependency errors</b></summary>

```bash
proot-distro login debian -- bash -c "apt-get update && apt-get install -f -y"
```
</details>

<details>
<summary><b>Out of memory / crashes</b></summary>

Electron is memory-heavy. Close other apps. Devices with <4 GB RAM will struggle.
</details>

<details>
<summary><b>GLM API key not set</b></summary>

Get a key from [z.ai/subscribe](https://z.ai/subscribe), then set it inside ZCode's settings or:
```bash
proot-distro login debian -- bash -c "echo 'export ZAI_API_KEY=your-key-here' >> /root/.bashrc"
```
</details>

## Disclaimer

This is an unofficial community wrapper. ZCode is built by [z.ai](https://z.ai). This repo just automates installing the official Linux ARM64 build inside a Termux proot environment. Not affiliated with or endorsed by z.ai.

## License

MIT