# Barry Simulator

Try Barry Launcher apps on a Mac, in windows shaped like the AYN Thor's bottom screen, with
nothing to type: **Barry Simulator.app** opens with a double-click in Finder.

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

## Building the app

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
| `icon.svg` | its icon |
