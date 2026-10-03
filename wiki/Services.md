# Services: a Python helper for your app

Some things QML can't do, such as opening a raw TCP connection to a game,
reading a device, or running a library. An app can bring a **service** for
them: a Python 3 script that runs while the app's window is open. The app
talks to it over HTTP on the device itself.

[Pip-Boy](https://github.com/project-barry/PyPipboyApp/tree/master/barry), the
Fallout 4 Pip-Boy, is a complete example. Its service talks to the game, and
its QML draws the Pip-Boy.

> **Only when you must.** An app with a service runs a program on the user's
> device with all of their access, so users have to trust it more than a QML
> app. The Barry Launcher plugin asks them first. If QML (with
> `XMLHttpRequest` or `QtWebSockets`) can do the job, leave the service out.

## Adding one

Name the script in `barry-app.json`:

```json
{
  "format": 1,
  "id": "io.github.you.counter",
  "name": "Counter",
  "version": "1.0.0",
  "main": "main.qml",
  "service": "service.py"
}
```

Barry Launcher then does the following:

1. Before the window opens, it starts `python3 -s service.py` in the app's
   folder. The environment has these variables:

   | | |
   | --- | --- |
   | `BARRY_SERVICE_PORT` | The port to serve on, at `127.0.0.1` |
   | `BARRY_SERVICE_TOKEN` | A random token. Answer only requests that carry it. |
   | `BARRY_APP_ID`, `BARRY_APP_DIR`, `BARRY_APP_DATA` | Your app's id, its folder, and its data folder |
   | `XDG_CONFIG_HOME`, `XDG_DATA_HOME` | Inside the data folder, as for the window |

2. It hands the window [`barry.serviceUrl`, `barry.serviceToken` and
   `barry.request()`](The-barry-Object#your-service).
3. When the window closes, or the app is closed, updated or removed, it stops
   the service: SIGTERM first, then SIGKILL after 3 seconds.

The service's output goes to the app's log, together with the window's.

## The rules

- **Python 3 and its standard library only.** It is the system's Python
  (3.12 on SteamOS), without the user's `site-packages`. You can bring pure
  Python modules in your app folder (your script's folder is on the path).
  Pip packages with compiled parts won't work.
- **Serve on `127.0.0.1` only**, on `BARRY_SERVICE_PORT`.
- **Check the token** on every request: an `X-Barry-Token` header (what
  `barry.request` sends), or a `token` query parameter for an `Image`'s
  `source`. This stops web pages open on the device from using your
  service. It doesn't stop other programs on the device, because the token
  is in the window's command line, so don't make a service that is dangerous
  in anyone's hands.
- **Start fast and quit on SIGTERM.** The window may already be asking for
  the service while it starts, so `barry.request` reports status `0` until it
  answers. Retry.
- **Save what matters as it changes.** A service that doesn't stop within
  3 seconds is killed.

## A small example

`service.py` counts and answers with the count:

```python
import json, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ["BARRY_SERVICE_PORT"])
TOKEN = os.environ["BARRY_SERVICE_TOKEN"]
count = 0

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        global count
        if self.headers.get("X-Barry-Token") != TOKEN:
            self.send_response(403)
            self.end_headers()
            return
        count += 1
        body = json.dumps({"count": count}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
```

`main.qml` asks it:

```qml
import QtQuick

Rectangle {
    id: app
    required property var barry
    color: "black"

    Text {
        id: label
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 60 * app.barry.scale
        text: "Tap"
    }
    TapHandler {
        onTapped: app.barry.request("POST", "count", {}, function(status, reply) {
            label.text = status === 200 ? "Count: " + reply.count : "No answer (" + status + ")"
        })
    }
}
```

`barry-app run` starts the service too, so you can try this on a PC. The
service's output shows in the same terminal.

## Debugging

- Run the service on its own:
  `BARRY_SERVICE_PORT=47900 BARRY_SERVICE_TOKEN=dev python3 service.py`,
  then
  `curl -H "X-Barry-Token: dev" -X POST http://127.0.0.1:47900/count`.
- On the device, everything the service prints is in
  `~/.cache/barry_launcher/ID.log`. Use `python3 -u` style output (Barry
  Launcher already turns buffering off) or `flush=True`.
- A service that crashes stays stopped until the app is opened again. Show
  the user that it isn't answering (status `0`) rather than a blank screen.
