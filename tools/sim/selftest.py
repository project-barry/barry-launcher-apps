#!/usr/bin/env python3
"""Barry Simulator's self-test, for CI: the simulator runs offscreen with a
folder of apps, starts one app's stand-in game, opens the app, and passes
when the log shows every expected text and both screenshots (the simulator
and the app's window) are saved.

  python selftest.py SIM_FOLDER APPS_FOLDER OUT_FOLDER "App name" EXPECTED...

SIM_FOLDER has sim.py (the repository's tools/sim, or a built simulator's
sim folder). It keeps its settings and data in OUT_FOLDER/home.
"""
import json
import os
import sys
import time

sim_dir, apps, out = (os.path.abspath(a) for a in sys.argv[1:4])
name = sys.argv[4]
expected = sys.argv[5:]
home = os.path.join(out, "home")
os.makedirs(home, exist_ok=True)
with open(os.path.join(home, "settings.json"), "w", encoding="utf-8") as fh:
    json.dump({"roots": [apps], "folders": [], "scale": 0.75, "autoReload": False}, fh)
tag = name.lower().replace(" ", "-")
if sys.platform == "win32":  # offscreen Qt doesn't look for Windows' own fonts
    os.environ.setdefault("QT_QPA_FONTDIR", os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts"))
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")  # CI on Linux: xcb, under Xvfb
os.environ.update(BARRY_SIM_HOME=home,
                  BARRY_SIM_SHOT=os.path.join(out, tag + "-app.png"), BARRY_SIM_SHOT_MS="8000")
sys.argv = [sys.argv[0]]
sys.path.insert(0, sim_dir)
import sim  # noqa: E402

import shiboken6  # noqa: E402
from PySide6.QtCore import QTimer, QUrl  # noqa: E402
from PySide6.QtGui import QFontDatabase, QGuiApplication  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402
from PySide6.QtQuick import QQuickWindow  # noqa: E402

app = QGuiApplication(sys.argv)
fonts = os.path.join(os.path.dirname(sim.TOOLS), "fonts")
if os.path.isdir(fonts):
    for f in os.listdir(fonts):
        QFontDatabase.addApplicationFont(os.path.join(fonts, f))
s = sim.Sim()
app.aboutToQuit.connect(s.shutdown)
engine = QQmlApplicationEngine()
engine.rootContext().setContextProperty("sim", s)
engine.load(QUrl.fromLocalFile(os.path.join(sim_dir, "Sim.qml")))
if not engine.rootObjects():
    sys.exit("FAILED: Sim.qml did not load")
win = shiboken6.wrapInstance(shiboken6.getCppPointer(engine.rootObjects()[0])[0], QQuickWindow)
print("apps found:", ", ".join(a["name"] for a in s.apps), flush=True)
entry = next((a for a in s.apps if a["name"] == name), None)
if not entry:
    sys.exit(f"FAILED: no app named {name}")
key = entry["key"]
s.select(key)
result = {"ok": False}
start = time.time()
step = {"n": 0}


def tick():
    step["n"] += 1
    n = step["n"]
    if n == 2:
        win.grabWindow().save(os.path.join(out, "simulator-home.png"))
        for h in entry["helpers"]:
            s.toggleHelper(key, h)
    if n == 6:
        s.launch(key)
    if n > 6:
        done = all(e in s.log for e in expected) and os.path.isfile(os.environ["BARRY_SIM_SHOT"])
        if done or time.time() - start > 90:
            win.grabWindow().save(os.path.join(out, tag + "-simulator.png"))
            result["ok"] = done
            app.quit()


timer = QTimer()
timer.timeout.connect(tick)
timer.start(500)
app.exec()
log = s.log
del win
del engine
with open(os.path.join(out, tag + ".log"), "w", encoding="utf-8") as fh:
    fh.write(log)
print(log)
missing = [e for e in expected if e not in log]
if not result["ok"]:
    sys.exit(f"FAILED: {name}: missing {missing or 'the app screenshot'}")
print(f"OK: {name}")
