# tools

Copies of Barry Launcher's own app tools, so you can check, pack and try
apps on any computer with Python 3.10+ (and Qt 6 for `run`):

| File | What it is |
| --- | --- |
| `barry-app` | The same `barry-app` command as on the device: `check`, `pack`, `run` (and `install`, `remove`, `list`, which only make sense on the device) |
| `barry_apps.py` | The package checks and installer that Barry Launcher itself uses |
| `AppHost.qml` | The window Barry Launcher runs every app in; `barry-app run` uses this copy |

```sh
python3 tools/barry-app check apps/dice      # would it install?
python3 tools/barry-app pack apps/dice       # writes dice-1.0.0.zip
python3 tools/barry-app run apps/dice        # try it in a 1240 x 1080 window
```

On Windows, use `py tools\barry-app ...`.

On a Mac or a Windows PC, [**Barry Simulator**](sim/README.md) runs apps with a double-click: it finds your
app folders, runs each one as Barry Launcher would (with its service, data folder and stand-in
games), and shows its log.

These come unchanged from
[pb-os](https://github.com/project-barry/pb-os) (`sm8550-overlay/usr/lib/barry_launcher/`
and `sm8550-overlay/usr/share/barry_launcher/shell/AppHost.qml`). Change them
there; `PB_OS_COMMIT` says which commit these are from.

License: like pb-os's own scripts, the
[GNU GPL version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html).
Apps you make are your own: using these tools does not put them under the GPL.
