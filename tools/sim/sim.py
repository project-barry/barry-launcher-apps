#!/usr/bin/env python3
"""Barry Simulator: try Barry Launcher apps on a Mac (or a Linux PC), with
their windows, as on the AYN Thor's bottom screen.

It finds app folders (barry-app.json) under the folders it searches, and
installs .zip apps with Barry Launcher's own installer (barry_apps.py). Each
app runs in a window of its own with Barry Launcher's AppHost.qml, its
service and its data folder, as barry_launcher_shelld runs it. Stand-in
games next to an app (a tools/fake_*.py in its repository) can run beside
it. Logs, restarting, and restarting when a file changes are in the
simulator's window (Sim.qml).

Everything the simulator keeps is in ~/Library/Application Support/Barry
Simulator (on Windows, %APPDATA%\\Barry Simulator; on Linux,
~/.local/share/barry-simulator): its settings, the installed apps and every
app's data.

  python3 sim.py        (needs PySide6 6.8; build-mac-app.sh makes the .app)
"""
import glob
import json
import os
import shutil
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = next(d for d in (HERE, os.path.dirname(HERE)) if os.path.isfile(os.path.join(d, "barry_apps.py")))
WINDOWS = sys.platform == "win32"
SUPPORT = os.environ.get("BARRY_SIM_HOME") or (  # BARRY_SIM_HOME: for tests (selftest.py)
          os.path.expanduser("~/Library/Application Support/Barry Simulator") if sys.platform == "darwin"
          else os.path.join(os.environ.get("APPDATA") or os.path.expanduser("~"), "Barry Simulator") if WINDOWS
          else os.path.expanduser("~/.local/share/barry-simulator"))
# Installs and app data go to the simulator's folder, not a real Barry
# Launcher's: barry_apps reads these when it is imported.
os.environ["XDG_DATA_HOME"] = os.path.join(SUPPORT, "data")
os.environ["XDG_CONFIG_HOME"] = os.path.join(SUPPORT, "config")
os.environ["XDG_CACHE_HOME"] = os.path.join(SUPPORT, "cache")
sys.path.insert(0, TOOLS)
import barry_apps  # noqa: E402

from PySide6.QtCore import (Property, QObject, QProcess, QProcessEnvironment, QStandardPaths, QTimer,  # noqa: E402
                            QUrl, Signal, Slot)
from PySide6.QtGui import QDesktopServices, QFontDatabase, QGuiApplication, QIcon  # noqa: E402
from PySide6.QtQml import QQmlApplicationEngine  # noqa: E402

SETTINGS = os.path.join(SUPPORT, "settings.json")
LOG_LIMIT = 400_000  # characters of log kept per app
SKIP = {".git", "node_modules", "__pycache__", ".github"}


def short(path: str) -> str:
    home = os.path.expanduser("~")
    return "~" + path[len(home):] if path.startswith(home + os.sep) else path


def repo_root(folder: str) -> str | None:
    """The git repository an app folder is in (up to four levels up)."""
    d = folder
    for _ in range(5):
        if os.path.exists(os.path.join(d, ".git")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    return None


def stamp(folder: str) -> float:
    """The newest change in an app folder, to restart a running app on save."""
    newest = 0.0
    for d, dirs, files in os.walk(folder):
        dirs[:] = [x for x in dirs if x not in SKIP and not x.startswith(".")]
        for f in files:
            try:
                newest = max(newest, os.stat(os.path.join(d, f)).st_mtime)
            except OSError:
                pass
    return newest


def firefox() -> str | None:
    return (os.environ.get("BARRY_FIREFOX") or shutil.which("firefox")
            or next((f for f in ("/Applications/Firefox.app/Contents/MacOS/firefox",
                                 r"C:\Program Files\Mozilla Firefox\firefox.exe",
                                 r"C:\Program Files (x86)\Mozilla Firefox\firefox.exe")
                     if os.path.isfile(f)), None))


def python() -> str:
    """The Python for app windows, services and stand-ins: on Windows,
    pythonw.exe, which opens no console window."""
    if WINDOWS:
        w = os.path.join(os.path.dirname(sys.executable), "pythonw.exe")
        if os.path.isfile(w):
            return w
    return sys.executable


class Sim(QObject):
    appsChanged = Signal()
    logChanged = Signal()
    selectedChanged = Signal()
    settingsChanged = Signal()
    messageChanged = Signal()

    def __init__(self):
        super().__init__()
        s = barry_apps._read_json(SETTINGS, {})
        docs = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.DocumentsLocation)
        github = os.path.join(docs or os.path.expanduser("~/Documents"), "Github")
        self._roots = s.get("roots") or ([github] if os.path.isdir(github) else [])
        self._folders = s.get("folders", [])
        self._scale = float(s.get("scale", 0.75))
        self._reload = bool(s.get("autoReload", True))
        self._apps = []
        self._selected = ""
        self._message = ""
        self._procs = {}      # app key -> QProcess
        self._helpers = {}    # stand-in script -> QProcess
        self._helper_owner = {}  # stand-in script -> app key whose log gets its output
        self._logs = {}       # app key -> text
        self._stamps = {}     # app key -> stamp() when started
        self._restart = set()  # app keys to start again once they have stopped
        self._clear = set()    # app keys whose data goes once they have stopped
        self.rescan()
        self._watch = QTimer(self)
        self._watch.timeout.connect(self._check_changes)
        self._watch.start(1000)

    # --- Settings -------------------------------------------------------------

    def _save(self):
        barry_apps._write_json(SETTINGS, {"roots": self._roots, "folders": self._folders,
                                          "scale": self._scale, "autoReload": self._reload})

    def _get_scale(self):
        return self._scale

    def _set_scale(self, v):
        if abs(v - self._scale) > 1e-6:
            self._scale = v
            self._save()
            self.settingsChanged.emit()

    scale = Property(float, _get_scale, _set_scale, notify=settingsChanged)

    def _get_reload(self):
        return self._reload

    def _set_reload(self, v):
        if v != self._reload:
            self._reload = v
            self._save()
            self.settingsChanged.emit()

    autoReload = Property(bool, _get_reload, _set_reload, notify=settingsChanged)

    @Property(list, notify=settingsChanged)
    def searched(self):
        return [short(r) for r in self._roots] + [short(f) for f in self._folders]

    @Property(str, constant=True)
    def supportFolder(self):
        return short(SUPPORT)

    @Property(str, notify=messageChanged)
    def message(self):
        return self._message

    def _say(self, text):
        self._message = text
        self.messageChanged.emit()

    # --- Apps -----------------------------------------------------------------

    @Property(list, notify=appsChanged)
    def apps(self):
        return self._apps

    def _entry(self, folder: str, source: str) -> dict:
        e = {"key": folder, "dir": folder, "path": short(folder), "source": source, "error": "", "id": "",
             "name": os.path.basename(folder), "version": "", "description": "", "icon": "", "type": "qml",
             "service": False, "helpers": []}
        try:
            m = barry_apps.read_manifest(folder)
            e.update(id=m["id"], name=m["name"], version=m["version"], type=m["type"],
                     description=m.get("description") or "", service=bool(m["service"]),
                     icon=QUrl.fromLocalFile(os.path.join(folder, m["icon"])).toString() if m["icon"] else "")
        except barry_apps.AppError as err:
            e["error"] = str(err)
        root = repo_root(folder)
        if root:
            e["helpers"] = sorted(glob.glob(os.path.join(root, "tools", "fake_*.py")))
        return e

    @Slot()
    def rescan(self):
        found = {}
        for root in self._roots:
            for depth in ("*", "*/*", "*/*/*"):
                for manifest in glob.glob(os.path.join(root, depth, "barry-app.json")):
                    folder = os.path.dirname(os.path.realpath(manifest))
                    if not any(part in SKIP for part in folder.split(os.sep)):
                        # Shown as the repository (the first folder under root).
                        found.setdefault(folder, os.path.relpath(manifest, root).split(os.sep)[0])
            if os.path.isfile(os.path.join(root, "barry-app.json")):
                found.setdefault(os.path.realpath(root), "")
        for f in self._folders:
            if os.path.isfile(os.path.join(f, "barry-app.json")):
                found.setdefault(os.path.realpath(f), "")
        installed = os.path.realpath(barry_apps.APPS_DIR)
        if os.path.isdir(installed):
            for name in sorted(os.listdir(installed)):
                d = os.path.join(installed, name)
                if not name.startswith(".") and os.path.isfile(os.path.join(d, "barry-app.json")):
                    found[d] = "installed"
        apps = [self._entry(folder, src) for folder, src in found.items()]
        apps.sort(key=lambda e: (e["source"] != "installed", e["name"].lower(), e["path"]))
        self._apps = apps
        self._refresh_running()
        if self._selected not in found:
            self._selected = apps[0]["key"] if apps else ""
            self.selectedChanged.emit()
            self.logChanged.emit()
        self._say(f"{len(apps)} apps found")

    def _refresh_running(self):
        for e in self._apps:
            p = self._procs.get(e["key"])
            e["running"] = p is not None and p.state() != QProcess.ProcessState.NotRunning
            e["helpersRunning"] = [h in self._helpers for h in e["helpers"]]
        self._apps = list(self._apps)
        self.appsChanged.emit()

    def _app(self, key):
        return next((e for e in self._apps if e["key"] == key), None)

    @Slot(str)
    def addFolder(self, url: str):
        """An app folder, or a folder to search for apps."""
        path = QUrl(url).toLocalFile() or url
        if not os.path.isdir(path):
            return
        if os.path.isfile(os.path.join(path, "barry-app.json")):
            if path not in self._folders:
                self._folders.append(path)
        elif path not in self._roots:
            self._roots.append(path)
        self._save()
        self.settingsChanged.emit()
        self.rescan()

    @Slot(str)
    def forgetFolder(self, shown: str):
        full = os.path.expanduser(shown) if shown.startswith("~") else shown
        self._roots = [r for r in self._roots if r != full]
        self._folders = [f for f in self._folders if f != full]
        self._save()
        self.settingsChanged.emit()
        self.rescan()

    @Slot(str)
    def install(self, url: str):
        """A .zip app, with Barry Launcher's installer (and its checks)."""
        path = QUrl(url).toLocalFile() or url
        try:
            m = barry_apps.install(path, reserved={"browser", "discord", "signal", "trackpad", "keyboard"})
        except (barry_apps.AppError, OSError) as err:
            self._say(f"Could not install {os.path.basename(path)}: {err}")
            return
        key = os.path.realpath(os.path.join(barry_apps.APPS_DIR, m["id"]))
        if key in self._procs:
            self._restart.add(key)
            self.stop(key)
        self.rescan()
        self.select(key)
        self._say(f"{'Updated' if m['updated'] else 'Installed'} {m['name']} {m['version']}")

    @Slot(str)
    def uninstall(self, key: str):
        e = self._app(key)
        if not e or e["source"] != "installed":
            return
        self.stop(key)
        barry_apps.remove(e["id"])
        self.rescan()
        self._say(f"Removed {e['name']} and its data")

    # --- The selected app and its log -----------------------------------------

    @Property(str, notify=selectedChanged)
    def selected(self):
        return self._selected

    @Slot(str)
    def select(self, key: str):
        if key != self._selected:
            self._selected = key
            self.selectedChanged.emit()
            self.logChanged.emit()

    @Property(str, notify=logChanged)
    def log(self):
        return self._logs.get(self._selected, "")

    def _append(self, key: str, text: str):
        t = self._logs.get(key, "") + text
        if len(t) > LOG_LIMIT:
            t = t[-LOG_LIMIT:]
        self._logs[key] = t
        if key == self._selected:
            self.logChanged.emit()

    @Slot()
    def clearLog(self):
        self._logs[self._selected] = ""
        self.logChanged.emit()

    @Slot(str)
    def copyLog(self, _key=""):
        QGuiApplication.clipboard().setText(self._logs.get(self._selected, ""))
        self._say("Log copied")

    # --- Running apps -----------------------------------------------------------

    def _data(self, e) -> str:
        d = os.path.join(barry_apps.APP_DATA_DIR, e["id"] or os.path.basename(e["dir"]))
        os.makedirs(d, exist_ok=True)
        return d

    @Slot(str)
    def launch(self, key: str):
        e = self._app(key)
        if not e:
            return
        self.select(key)
        if e["error"]:
            self._append(key, f"[simulator] {e['name']} can't run: {e['error']}\n")
            return
        if key in self._procs:
            self._say(f"{e['name']} is already open (its window may be behind this one)")
            return
        data = self._data(e)
        env = QProcessEnvironment.systemEnvironment()
        for k, v in {"BARRY_APP_ID": e["id"], "BARRY_APP_DIR": e["dir"], "BARRY_APP_DATA": data,
                     "XDG_CONFIG_HOME": os.path.join(data, ".config"),
                     "XDG_DATA_HOME": os.path.join(data, ".local", "share"),
                     "XDG_CACHE_HOME": os.path.join(SUPPORT, "cache"),
                     "QML_DISABLE_DISK_CACHE": "1", "QT_FORCE_STDERR_LOGGING": "1",
                     # Qt's font fallback notes aren't the app's business.
                     "QT_LOGGING_RULES": "qt.qpa.fonts.warning=false",
                     "PYTHONUNBUFFERED": "1"}.items():
            env.insert(k, v)
        p = QProcess(self)
        p.setProcessEnvironment(env)
        p.setWorkingDirectory(e["dir"])
        p.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        p.readyReadStandardOutput.connect(
            lambda: self._append(key, bytes(p.readAllStandardOutput()).decode(errors="replace")))
        p.finished.connect(lambda code, _status: self._ended(key, e["name"], code))
        p.errorOccurred.connect(lambda err: self._append(key, f"[simulator] could not start: {err}\n"))
        if e["type"] == "web":
            fx = firefox()
            if not fx:
                self._append(key, "[simulator] a web app runs in Firefox: install Firefox first\n")
                return
            m = barry_apps.read_manifest(e["dir"])
            profile = os.path.join(data, "firefox")
            os.makedirs(profile, exist_ok=True)
            with open(os.path.join(profile, "user.js"), "w", encoding="utf-8") as fh:
                fh.write(f'user_pref("layout.css.devPixelsPerPx", "{m["web"]["zoom"] * self._scale}");\n'
                         'user_pref("browser.shell.checkDefaultBrowser", false);\n'
                         'user_pref("browser.aboutwelcome.enabled", false);\n')
            p.setProgram(fx)
            p.setArguments(["--no-remote", "--profile", profile, "--width", str(round(1240 * self._scale)),
                            "--height", str(round(1080 * self._scale)), m["web"]["url"]])
        else:
            p.setProgram(python())
            p.setArguments(["-u", os.path.join(HERE, "apphost.py"), e["dir"], data, str(self._scale)])
        self._procs[key] = p
        self._stamps[key] = stamp(e["dir"])
        self._append(key, f"\n[simulator] {time.strftime('%H:%M:%S')} opening {e['name']} {e['version']}"
                          f" (data: {short(data)})\n")
        p.start()
        self._refresh_running()

    def _ended(self, key, name, code):
        self._procs.pop(key, None)
        self._append(key, f"[simulator] {time.strftime('%H:%M:%S')} {name} closed"
                          + (f" (exit code {code})" if code else "") + "\n")
        if key in self._clear:
            self._clear.discard(key)
            self._clear_data(key)
        self._refresh_running()
        if key in self._restart:
            self._restart.discard(key)
            QTimer.singleShot(150, lambda: self.launch(key))

    @Slot(str)
    def stop(self, key: str):
        p = self._procs.get(key)
        if p and p.state() != QProcess.ProcessState.NotRunning:
            p.terminate()
            QTimer.singleShot(4000, lambda: p.state() != QProcess.ProcessState.NotRunning and p.kill())

    @Slot(str)
    def restart(self, key: str):
        if key in self._procs:
            self._restart.add(key)
            self.stop(key)
        else:
            self.launch(key)

    def _check_changes(self):
        if not self._reload:
            return
        for key in list(self._procs):
            e = self._app(key)
            if not e or key in self._restart:
                continue
            s = stamp(e["dir"])
            if s > self._stamps.get(key, 0):
                self._stamps[key] = s
                self._append(key, "[simulator] a file changed: restarting\n")
                self.restart(key)

    # --- Stand-in games ---------------------------------------------------------

    @Slot(str, str)
    def toggleHelper(self, key: str, script: str):
        p = self._helpers.get(script)
        name = os.path.basename(script)
        if p:
            p.kill() if WINDOWS else p.terminate()
            return
        p = QProcess(self)
        p.setWorkingDirectory(os.path.dirname(os.path.dirname(script)))
        p.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        env = QProcessEnvironment.systemEnvironment()
        env.insert("PYTHONUNBUFFERED", "1")
        p.setProcessEnvironment(env)
        self._helper_owner[script] = key

        def out():
            for line in bytes(p.readAllStandardOutput()).decode(errors="replace").splitlines():
                self._append(self._helper_owner[script], f"[{name}] {line}\n")

        def ended(code, _status):
            self._helpers.pop(script, None)
            self._append(self._helper_owner[script], f"[simulator] stand-in {name} stopped\n")
            self._refresh_running()
        p.readyReadStandardOutput.connect(out)
        p.finished.connect(ended)
        p.start(python(), ["-u", script])
        self._helpers[script] = p
        self._append(key, f"[simulator] stand-in {name} started\n")
        self._refresh_running()

    # --- Folders ----------------------------------------------------------------

    @Slot(str)
    def showFolder(self, key: str):
        e = self._app(key)
        if e:
            QDesktopServices.openUrl(QUrl.fromLocalFile(e["dir"]))

    @Slot(str)
    def showData(self, key: str):
        e = self._app(key)
        if e:
            QDesktopServices.openUrl(QUrl.fromLocalFile(self._data(e)))

    @Slot(str)
    def clearData(self, key: str):
        """The app's data folder, emptied; an open app is closed first (it may
        save as it closes) and opened again."""
        if key in self._procs:
            self._clear.add(key)
            self._restart.add(key)
            self.stop(key)
        else:
            self._clear_data(key)

    def _clear_data(self, key):
        e = self._app(key)
        if e:
            shutil.rmtree(self._data(e), ignore_errors=True)
            self._append(key, "[simulator] the app's data was cleared\n")
            self._say(f"Cleared {e['name']}'s data")

    def shutdown(self):
        procs = list(self._procs.values()) + list(self._helpers.values())
        self._restart.clear()
        self._clear.clear()
        for p in procs:
            p.blockSignals(True)  # quitting: no more log lines or restarts
        for p in self._procs.values():
            p.terminate()
        for p in self._helpers.values():
            p.kill() if WINDOWS else p.terminate()
        for p in procs:
            if not p.waitForFinished(4000):
                p.kill()


def main() -> int:
    os.makedirs(SUPPORT, exist_ok=True)
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Barry Simulator")
    app.setOrganizationName("Project Barry")
    icon = os.path.join(HERE, "icon.png")
    if os.path.isfile(icon):
        app.setWindowIcon(QIcon(icon))
    fonts = os.path.join(os.path.dirname(TOOLS), "fonts")
    if os.path.isdir(fonts):
        for f in sorted(os.listdir(fonts)):
            if f.endswith((".ttf", ".otf")):
                QFontDatabase.addApplicationFont(os.path.join(fonts, f))
    sim = Sim()
    app.aboutToQuit.connect(sim.shutdown)
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("sim", sim)
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "Sim.qml")))
    if not engine.rootObjects():
        return 1
    code = app.exec()
    del engine  # before sim, which its bindings use
    return code


if __name__ == "__main__":
    sys.exit(main())
