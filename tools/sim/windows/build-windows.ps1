# Builds the Windows Barry Simulator: a folder with everything in it
# (Python 3.13's embeddable build, Qt 6.8 as PySide6, the simulator,
# Barry Launcher's AppHost.qml and barry_apps.py, Noto Sans) and
# Barry Simulator.exe to start it. Nothing is installed: unzip and run.
#
#   tools\sim\windows\build-windows.ps1 [-Out dist]
#
# Needs Python 3.13 on the PATH (for pip) and the Visual Studio C++ tools
# (cl and rc, as in a "Developer PowerShell"). CI runs it
# (.github/workflows/simulator-windows.yml).
param([string]$Out = "dist")
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Here = $PSScriptRoot
$Sim = Split-Path $Here
$Tools = Split-Path $Sim
$PythonVersion = "3.13.16"
$PySide = "6.8.3"

New-Item -ItemType Directory -Force $Out | Out-Null
$Root = Join-Path (Resolve-Path $Out) "Barry Simulator"
if (Test-Path $Root) { Remove-Item -Recurse -Force $Root }
New-Item -ItemType Directory -Force "$Root\python", "$Root\sim", "$Root\fonts" | Out-Null
$Work = Join-Path ([IO.Path]::GetTempPath()) ("barry-sim-" + [guid]::NewGuid())
New-Item -ItemType Directory $Work | Out-Null

Write-Host "Python $PythonVersion (embeddable)..."
Invoke-WebRequest "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-embed-amd64.zip" -OutFile "$Work\python.zip"
Expand-Archive "$Work\python.zip" "$Root\python"
# Where it looks for modules: its own, then the folder with Qt in it.
$pth = Get-ChildItem "$Root\python\python*._pth" | Select-Object -First 1
Set-Content $pth.FullName "python313.zip`r`n.`r`n..\site-packages`r`nimport site"

Write-Host "Qt (PySide6 $PySide)..."
python -m pip install --quiet --disable-pip-version-check --only-binary=:all: --python-version 3.13 `
    --platform win_amd64 --target "$Root\site-packages" "PySide6-Essentials==$PySide" "PySide6-Addons==$PySide"
# What apps can't use on PB-OS (its QtWebEngine doesn't work) and Qt's tools.
$P = "$Root\site-packages\PySide6"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue `
    "$P\Qt6WebEngine*.dll", "$P\QtWebEngine*.pyd", "$P\QtWebEngineProcess.exe", "$P\qml\QtWebEngine", `
    "$P\resources\qtwebengine*", "$P\translations", "$P\examples", "$P\include", "$P\doc"
Get-ChildItem "$P\*.exe" | Remove-Item -Force
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$Root\site-packages\bin"

Write-Host "The simulator..."
Copy-Item "$Sim\sim.py", "$Sim\apphost.py", "$Sim\Sim.qml", "$Sim\selftest.py", `
    "$Tools\barry_apps.py", "$Tools\AppHost.qml" "$Root\sim"

Write-Host "Noto Sans..."
foreach ($w in "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Black", "Italic") {
    Invoke-WebRequest "https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-$w.ttf" `
        -OutFile "$Root\fonts\NotoSans-$w.ttf"
}

Write-Host "The icon..."
$env:PYTHONPATH = "$Root\site-packages"
$env:QT_QPA_PLATFORM = "offscreen"
@'
import struct, sys
from PySide6.QtCore import QBuffer, QByteArray, QIODevice, Qt
from PySide6.QtGui import QGuiApplication, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer
app = QGuiApplication([])
svg, work = QSvgRenderer(sys.argv[1]), sys.argv[2]
images = []
for size in (16, 24, 32, 48, 64, 128, 256):
    img = QImage(size, size, QImage.Format.Format_ARGB32)
    img.fill(Qt.GlobalColor.transparent)
    p = QPainter(img)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    svg.render(p)
    p.end()
    data = QByteArray()
    buf = QBuffer(data)
    buf.open(QIODevice.OpenModeFlag.WriteOnly)
    img.save(buf, "PNG")
    images.append((size, bytes(data)))
    if size == 256:
        img.save(sys.argv[3])
# An .ico of PNGs, one for each size.
head = struct.pack("<HHH", 0, 1, len(images))
offset = 6 + 16 * len(images)
entries, blobs = b"", b""
for size, png in images:
    entries += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(png), offset + len(blobs))
    blobs += png
open(work + "\\app.ico", "wb").write(head + entries + blobs)
'@ | Set-Content "$Work\icon.py"
& "$Root\python\python.exe" "$Work\icon.py" "$Sim\icon.svg" $Work "$Root\sim\icon.png"
if ($LASTEXITCODE) { throw "icon failed" }
Remove-Item Env:PYTHONPATH, Env:QT_QPA_PLATFORM

Write-Host "Barry Simulator.exe..."
Copy-Item "$Here\launcher.c", "$Here\launcher.rc" $Work
Push-Location $Work
rc /nologo launcher.rc
if ($LASTEXITCODE) { throw "rc failed" }
cl /nologo /O2 /W3 /DUNICODE /D_UNICODE launcher.c launcher.res user32.lib shell32.lib `
    /link /SUBSYSTEM:WINDOWS "/OUT:Barry Simulator.exe"
if ($LASTEXITCODE) { throw "cl failed" }
Pop-Location
Copy-Item "$Work\Barry Simulator.exe" $Root

Set-Content "$Root\README.txt" @"
Barry Simulator for Windows
===========================

Try Barry Launcher apps on Windows, each in a window shaped like the
AYN Thor's bottom screen.

Double-click "Barry Simulator.exe". Keep it in this folder: it uses the
Python and Qt next to it. Nothing needs installing.

How to use it:
https://github.com/project-barry/barry-launcher-apps/wiki/Barry-Simulator

Its settings, installed apps and app data: %APPDATA%\Barry Simulator
Its own log: %LOCALAPPDATA%\Barry Simulator\Barry Simulator.log

Barry Simulator is built with a coding agent (Claude Code, running
Anthropic's Claude Opus 5.5). Python is under the PSF license, Qt for
Python (PySide6) under the LGPL v3, and Noto Sans under the SIL Open
Font License.
"@

Remove-Item -Recurse -Force $Work
$size = (Get-ChildItem -Recurse $Root | Measure-Object -Sum Length).Sum / 1MB
Write-Host ("Built {0} ({1:N0} MB)" -f $Root, $size)
