#!/bin/sh
# Builds "Barry Simulator.app": Barry Simulator (sim.py) with its own Qt
# 6.8 (PySide6, the Qt that PB-OS has), Barry Launcher's AppHost.qml and
# barry_apps.py, and Noto Sans (PB-OS's font), so it opens with a
# double-click in Finder.
#
#   tools/sim/build-mac-app.sh [FOLDER]     (default: /Applications)
#
# Needs Homebrew's Python 3.13 (brew install python@3.13): PySide6 6.8 has
# no build for newer Pythons. The app uses that Python from where Homebrew
# keeps it, so it runs on the Mac that built it. Build it again after
# changing the simulator or the tools it copies.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
TOOLS=$(dirname "$HERE")
DEST=${1:-/Applications}
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"
APP="$DEST/Barry Simulator.app"
PYSIDE=6.8.3

BREW=$(command -v brew || echo /opt/homebrew/bin/brew)
PREFIX=$("$BREW" --prefix python@3.13 2>/dev/null || true)
PY="$PREFIX/bin/python3.13"
FRAMEWORK="$PREFIX/Frameworks/Python.framework/Versions/3.13"
if [ ! -x "$PY" ] || [ ! -d "$FRAMEWORK" ]; then
    echo "build-mac-app: needs Homebrew's Python 3.13: brew install python@3.13" >&2
    exit 1
fi

BUILD=$(mktemp -d "${TMPDIR:-/tmp}/barry-sim.XXXXXX")
trap 'rm -rf "$BUILD"' EXIT
B="$BUILD/Barry Simulator.app/Contents"
mkdir -p "$B/MacOS" "$B/Resources/sim" "$B/Resources/fonts"

echo "Qt (PySide6 $PYSIDE)…"
"$PY" -m pip install --quiet --disable-pip-version-check --target "$B/Resources/site-packages" \
    "PySide6-Essentials==$PYSIDE" "PySide6-Addons==$PYSIDE"
# What apps can't use on PB-OS (its QtWebEngine doesn't work) and Qt's tools.
P="$B/Resources/site-packages/PySide6"
rm -rf "$P"/Qt/lib/QtWebEngine*.framework "$P"/Qt/qml/QtWebEngine "$P"/QtWebEngine*.abi3.so \
    "$P"/Qt/libexec/QtWebEngineProcess* "$P"/*.app "$P"/lupdate "$P"/lrelease "$P"/qmlls "$P"/qmlformat \
    "$P"/qmllint "$P"/rcc "$P"/uic "$P"/balsam* "$P"/qsb "$P"/svgtoqml "$P"/designer* "$P"/assistant* \
    "$P"/linguist* "$P"/Qt/translations "$B/Resources/site-packages/bin"

echo "The simulator…"
cp "$HERE/sim.py" "$HERE/apphost.py" "$HERE/Sim.qml" "$TOOLS/barry_apps.py" "$TOOLS/AppHost.qml" "$B/Resources/sim/"

echo "Noto Sans…"
for w in Regular Medium SemiBold Bold ExtraBold Black Italic; do
    curl -fsSL "https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-$w.ttf" \
        -o "$B/Resources/fonts/NotoSans-$w.ttf" || echo "  (NotoSans-$w.ttf: not downloaded)"
done

echo "The icon…"
PYTHONPATH="$B/Resources/site-packages" QT_QPA_PLATFORM=offscreen "$PY" - "$HERE/icon.svg" "$BUILD" <<'PYEOF'
import sys
from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer
app = QGuiApplication([])
svg, out = QSvgRenderer(sys.argv[1]), sys.argv[2]
for size in (16, 32, 64, 128, 256, 512, 1024):
    img = QImage(size, size, QImage.Format.Format_ARGB32)
    img.fill(Qt.GlobalColor.transparent)
    p = QPainter(img)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    svg.render(p)
    p.end()
    img.save(f"{out}/icon-{size}.png")
PYEOF
ICONSET="$BUILD/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
    cp "$BUILD/icon-$s.png" "$ICONSET/icon_${s}x${s}.png"
    cp "$BUILD/icon-$((s * 2)).png" "$ICONSET/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$ICONSET" -o "$B/Resources/AppIcon.icns"
cp "$BUILD/icon-256.png" "$B/Resources/sim/icon.png"

# Python's GUI executable, inside the app, so the Dock shows Barry Simulator
# (it loads Homebrew's Python framework from where it is).
cp "$FRAMEWORK/Resources/Python.app/Contents/MacOS/Python" "$B/MacOS/python"

cat > "$B/MacOS/Barry Simulator" <<'SHEOF'
#!/bin/sh
C=$(cd "$(dirname "$0")/.." && pwd)
export PYTHONPATH="$C/Resources/site-packages"
export PYTHONDONTWRITEBYTECODE=1
LOG="$HOME/Library/Logs/Barry Simulator.log"
exec "$C/MacOS/python" -u "$C/Resources/sim/sim.py" "$@" >>"$LOG" 2>&1
SHEOF
chmod +x "$B/MacOS/Barry Simulator"

cat > "$B/Info.plist" <<'PLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Barry Simulator</string>
    <key>CFBundleDisplayName</key><string>Barry Simulator</string>
    <key>CFBundleIdentifier</key><string>io.github.project-barry.simulator</string>
    <key>CFBundleVersion</key><string>1.0.0</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>Barry Simulator</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLEOF

# Signed for this Mac only (ad hoc), as Apple silicon needs.
codesign --force --sign - "$B/MacOS/python" >/dev/null 2>&1 || true
codesign --force --sign - "$BUILD/Barry Simulator.app" >/dev/null 2>&1 || true

rm -rf "$APP"
mv "$BUILD/Barry Simulator.app" "$APP"
echo "Built $APP ($(du -sh "$APP" | cut -f1))"
