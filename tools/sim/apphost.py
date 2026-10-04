#!/usr/bin/env python3
"""One app's window for Barry Simulator, as Barry Launcher runs it: Barry
Launcher's own AppHost.qml (a copy next to barry_apps.py), with the app's
service started first and stopped when the window closes. In place of Qt's
qml tool, PySide6 (the same Qt, 6.8, as PB-OS) runs it.

  apphost.py APP_FOLDER DATA_FOLDER SCALE

SCALE sizes the window: 1 is the AYN Thor's bottom screen, 1240 x 1080.
The app's environment (BARRY_APP_*, XDG_*) comes from sim.py.
"""
import os
import signal
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = next(d for d in (HERE, os.path.dirname(HERE)) if os.path.isfile(os.path.join(d, "barry_apps.py")))
sys.path.insert(0, TOOLS)
import barry_apps  # noqa: E402

from PySide6.QtCore import QTimer, QUrl  # noqa: E402
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402
from PySide6.QtQuick import QQuickWindow  # noqa: E402
import shiboken6  # noqa: E402

THOR_W, THOR_H = 1240, 1080


def main() -> int:
    folder, data, scale = sys.argv[1], sys.argv[2], float(sys.argv[3])
    m = barry_apps.read_manifest(folder)
    env = dict(os.environ)
    service, url, token = None, "", ""
    if m["service"]:
        service, url, token = barry_apps.start_service(folder, m["service"], env, None)
        print(f"[simulator] {m['name']}'s service runs at {url} (pid {service.pid})", flush=True)

    # AppHost.qml reads what follows "--", as from barry_launcher_shelld.
    argv = [sys.argv[0], "--", folder, m["main"], m["id"], m["name"], data, "windowed"]
    if service:
        argv += [url, token]
    app = QGuiApplication(argv)
    app.setApplicationName(m["name"])
    if m.get("icon"):
        app.setWindowIcon(QIcon(os.path.join(folder, m["icon"])))
    fonts = os.path.join(os.path.dirname(TOOLS), "fonts")  # Noto Sans, as on PB-OS (in the .app)
    if os.path.isdir(fonts):
        for f in sorted(os.listdir(fonts)):
            if f.endswith((".ttf", ".otf")):
                QFontDatabase.addApplicationFont(os.path.join(fonts, f))

    # Stop cleanly (and stop the service) when the simulator says so.
    signal.signal(signal.SIGTERM, lambda *_: app.quit())
    tick = QTimer()
    tick.start(200)
    tick.timeout.connect(lambda: None)  # lets Python see the signal

    engine = QQmlApplicationEngine()
    engine.load(QUrl.fromLocalFile(os.path.join(TOOLS, "AppHost.qml")))
    try:
        if not engine.rootObjects():
            print("[simulator] AppHost.qml did not load", flush=True)
            return 1
        win = shiboken6.wrapInstance(shiboken6.getCppPointer(engine.rootObjects()[0])[0], QQuickWindow)
        win.setTitle(f"{m['name']} — Barry Simulator")
        win.setWidth(round(THOR_W * scale))
        win.setHeight(round(THOR_H * scale))
        win.requestActivate()
        shot = os.environ.get("BARRY_SIM_SHOT")  # for tests: PNG of the window after BARRY_SIM_SHOT_MS
        if shot:
            QTimer.singleShot(int(os.environ.get("BARRY_SIM_SHOT_MS", "4000")),
                              lambda: win.grabWindow().save(shot))
        return app.exec()
    finally:
        barry_apps.stop_service(service)


if __name__ == "__main__":
    sys.exit(main())
