#!/bin/sh
# Builds the Linux Barry Simulator as an AppImage: one file with
# everything in it (a portable Python 3.13, Qt 6.8 as PySide6, the
# simulator, Barry Launcher's AppHost.qml and barry_apps.py, Noto Sans, and
# the few X11 helper libraries Qt needs that not every system has).
#
#   tools/sim/linux/build-linux.sh [OUT]      (default: dist)
#
# Builds for this machine's architecture (x86_64 or aarch64). Needs curl,
# and Qt's usual libraries to draw the icon (CI installs them:
# .github/workflows/simulator-linux.yml).
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
SIM=$(dirname "$HERE")
TOOLS=$(dirname "$SIM")
OUT=$(mkdir -p "${1:-dist}" && cd "${1:-dist}" && pwd)
ARCH=$(uname -m)
PY=3.13.16
PBS=20261003   # python-build-standalone release
PYSIDE=6.8.3

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
APP="$WORK/AppDir"
mkdir -p "$APP/sim" "$APP/fonts" "$APP/lib"

echo "Python $PY (portable)..."
curl -fsSL "https://github.com/astral-sh/python-build-standalone/releases/download/$PBS/cpython-$PY+$PBS-$ARCH-unknown-linux-gnu-install_only_stripped.tar.gz" \
    | tar -xz -C "$APP"
PYBIN="$APP/python/bin/python3"

echo "Qt (PySide6 $PYSIDE)..."
"$PYBIN" -m pip install --quiet --disable-pip-version-check --no-warn-script-location \
    "PySide6-Essentials==$PYSIDE" "PySide6-Addons==$PYSIDE"
SP=$("$PYBIN" -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
P="$SP/PySide6"
# What apps can't use on PB-OS (its QtWebEngine doesn't work) and Qt's tools.
rm -rf "$P"/Qt/lib/libQt6WebEngine* "$P"/Qt/libexec/QtWebEngineProcess "$P"/Qt/resources/qtwebengine* \
    "$P"/Qt/qml/QtWebEngine "$P"/Qt/translations "$P"/QtWebEngine*.abi3.so "$P"/examples "$P"/include \
    "$P"/doc "$SP"/pip "$SP"/pip-* "$APP"/python/bin/pip*
find "$P" -maxdepth 1 -type f -perm -u+x ! -name "*.so*" -delete

echo "The simulator..."
cp "$SIM/sim.py" "$SIM/apphost.py" "$SIM/Sim.qml" "$SIM/selftest.py" "$TOOLS/barry_apps.py" "$TOOLS/AppHost.qml" "$APP/sim/"

echo "Noto Sans..."
for w in Regular Medium SemiBold Bold ExtraBold Black Italic; do
    curl -fsSL "https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-$w.ttf" \
        -o "$APP/fonts/NotoSans-$w.ttf"
done

echo "X11 helper libraries..."
# Qt's X11 support needs these; many systems have them, some don't (on
# Wayland, Qt doesn't use them). Small, and stable for years.
for lib in libxcb-cursor.so.0 libxcb-icccm.so.4 libxcb-image.so.0 libxcb-keysyms.so.1 \
           libxcb-render-util.so.0 libxcb-util.so.1 libxkbcommon-x11.so.0; do
    path=$(ldconfig -p | awk -v l="$lib" '$1 == l { print $NF; exit }')
    if [ -n "$path" ]; then cp -L "$path" "$APP/lib/"; else echo "  ($lib: not on this system, not bundled)"; fi
done

echo "The icon..."
QT_QPA_PLATFORM=offscreen "$PYBIN" - "$SIM/icon.svg" "$APP" <<'PYEOF'
import sys
from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer
app = QGuiApplication([])
img = QImage(256, 256, QImage.Format.Format_ARGB32)
img.fill(Qt.GlobalColor.transparent)
p = QPainter(img)
p.setRenderHint(QPainter.RenderHint.Antialiasing)
QSvgRenderer(sys.argv[1]).render(p)
p.end()
img.save(sys.argv[2] + "/barry-simulator.png")
img.save(sys.argv[2] + "/sim/icon.png")
PYEOF
ln -s barry-simulator.png "$APP/.DirIcon"

cat > "$APP/barry-simulator.desktop" <<'DEOF'
[Desktop Entry]
Type=Application
Name=Barry Simulator
Comment=Try Barry Launcher apps in windows shaped like the AYN Thor's bottom screen
Exec=AppRun
Icon=barry-simulator
Categories=Development;
Terminal=false
DEOF

cat > "$APP/AppRun" <<'REOF'
#!/bin/sh
# Barry Simulator: its own Python and Qt, from this AppImage.
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONNOUSERSITE=1 PYTHONDONTWRITEBYTECODE=1
# Started from a file manager: output to a log; from a terminal: to it.
if [ ! -t 1 ]; then
    LOG="${XDG_STATE_HOME:-$HOME/.local/state}/barry-simulator"
    mkdir -p "$LOG"
    exec >>"$LOG/barry-simulator.log" 2>&1
fi
exec "$HERE/python/bin/python3" -u "$HERE/sim/sim.py" "$@"
REOF
chmod +x "$APP/AppRun"

echo "The AppImage..."
curl -fsSL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage" -o "$WORK/appimagetool"
chmod +x "$WORK/appimagetool"
# Kept for testing before it is packed (CI runs selftest.py from it).
rm -rf "$OUT/AppDir-$ARCH"
cp -a "$APP" "$OUT/AppDir-$ARCH"
ARCH=$ARCH "$WORK/appimagetool" --appimage-extract-and-run --no-appstream "$APP" "$OUT/Barry-Simulator-$ARCH.AppImage" >/dev/null
echo "Built $OUT/Barry-Simulator-$ARCH.AppImage ($(du -h "$OUT/Barry-Simulator-$ARCH.AppImage" | cut -f1))"
