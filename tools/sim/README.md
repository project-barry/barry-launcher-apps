# Barry Simulator

Try Barry Launcher apps on a Mac, a Windows PC or Linux, in windows shaped like the AYN Thor's
bottom screen, with nothing to type: **Barry Simulator.app** (Mac), **Barry Simulator.exe**
(Windows) or the **AppImage** (Linux) opens with a double-click. How to use it, with screenshots:
[the wiki](https://github.com/project-barry/barry-launcher-apps/wiki/Barry-Simulator).

- **Your apps, found for you.** It looks in `~/Documents/Github` for app folders (anything
  with a `barry-app.json`, up to three folders down). **Add folder…** adds another folder to
  search, or one app folder. **Install .zip…** installs a packed app with Barry Launcher's own
  installer and its checks.
- **Apps run as Barry Launcher runs them.** Each app gets its own window and Barry Launcher's
  `AppHost.qml`. Its service runs too (it starts first and stops when the window closes), and it
  keeps its own data folder. Qt is **6.8**, the version on PB-OS, and the font is **Noto Sans**,
  as on PB-OS.
- **Window size**: 100% is the Thor's 1240 × 1080 pixels. On a laptop, 75% fits better.
  `barry.scale` follows the size, as it does for any screen.
- **Stand-in games.** If the app's repository has `tools/fake_*.py`, such as
  `fake_stardew.py` or `fake_fallout4.py`, a **Start** button runs it beside the app.
- **Log**: everything the app, its service and the stand-in print, including QML errors.
- **Restart an open app when its files change**: save a `.qml` file and the app opens again
  with the change.
- **Show data / Clear data**: the app's data folder, as on the device (`barry.dataDir`).

Double-click an app, or select it and click **Open**. Clicks are taps. A trackpad pinch is a
pinch. The keyboard types into text fields (on the Thor, the Barry keyboard does).

Web apps (`"type": "web"`) open in Firefox, if it is installed.

## Windows

Download **Barry-Simulator-Windows.zip** from the
[releases](https://github.com/project-barry/barry-launcher-apps/releases) (tags `simulator-v…`).
Extract it, then double-click **Barry Simulator.exe**. The folder has everything in it: Python
3.13 (Python's embeddable build), Qt 6.8 and Noto Sans. Nothing needs installing.

CI builds it on Windows with `windows/build-windows.ps1`
([the workflow](../../.github/workflows/simulator-windows.yml)). The workflow also opens Stardew
Dual Screen and the Pip-Boy, with their stand-ins, in the built simulator (`selftest.py`, offscreen)
before zipping it. A `simulator-v*` tag releases it. `windows/launcher.c` is `Barry Simulator.exe`:
it starts `python\pythonw.exe sim\sim.py` with no console window, and logs to
`%LOCALAPPDATA%\Barry Simulator\Barry Simulator.log`.

## Linux

Download **Barry-Simulator-x86_64.AppImage** (or `-aarch64`) from the
[releases](https://github.com/project-barry/barry-launcher-apps/releases) (tags `simulator-v…`),
allow it to run as a program, and double-click it. It has a portable Python 3.13
([python-build-standalone](https://github.com/astral-sh/python-build-standalone)), Qt 6.8, Noto Sans,
and the small X11 libraries Qt needs that not every system has.

CI builds it with `linux/build-linux.sh`, on Ubuntu 22.04 for x86_64 (glibc 2.28 and later, as
PySide6 needs) and Ubuntu 24.04 for aarch64 (glibc 2.39)
([the workflow](../../.github/workflows/simulator-linux.yml)). It opens Stardew Dual Screen and the
Pip-Boy with their stand-ins on an X11 display (Xvfb), and starts the AppImage itself, before
releasing. Without the AppImage: `pip install PySide6==6.8.3`, then `python3 tools/sim/sim.py`.

## Building the Mac app

```sh
brew install python@3.13           # PySide6 6.8 has no build for newer Pythons
tools/sim/build-mac-app.sh         # → /Applications/Barry Simulator.app (about 520 MB)
```

The build downloads Qt (PySide6 6.8.3) and Noto Sans. It uses Homebrew's Python where Homebrew
keeps it, so the app runs on the Mac that built it. Build it again after changing the simulator,
or the `barry_apps.py` and `AppHost.qml` that it copies from `tools/`.

Without the .app (on Linux too): `pip install PySide6==6.8.3`, then `python3 tools/sim/sim.py`.

## Where things are

| | |
| --- | --- |
| The simulator's settings, installed apps and app data | `~/Library/Application Support/Barry Simulator` |
| Its own log (for when it won't start) | `~/Library/Logs/Barry Simulator.log` |
| On Windows | `%APPDATA%\Barry Simulator`, and the log in `%LOCALAPPDATA%\Barry Simulator` |
| On Linux | `~/.local/share/barry-simulator`, and the log in `~/.local/state/barry-simulator` |

## How it differs from the Thor

- Each app is a window on the desktop, not the full-screen bottom screen, and there's no top
  screen or game.
- The mouse makes single touches only, apart from a trackpad pinch.
- Apple's GPU, not the Thor's; check speed on the device.
- Barry Launcher's home screen, game links and Decky plugin aren't simulated.

| File | |
| --- | --- |
| `sim.py` | the simulator: finds, installs and runs apps and stand-ins |
| `Sim.qml` | its window |
| `apphost.py` | one app's window: `AppHost.qml` and the app's service, in PySide6 |
| `build-mac-app.sh` | makes `Barry Simulator.app` |
| `linux/build-linux.sh` | the Linux AppImage build |
| `release-notes.md` | the notes on each `simulator-v…` release |
| `windows/` | the Windows build: `build-windows.ps1`, and `launcher.c`/`launcher.rc` for `Barry Simulator.exe` |
| `selftest.py` | opens an app and its stand-in offscreen, and checks the log and the screenshots (CI) |
| `icon.svg` | its icon |
