# App package reference

## The folder

```
myapp/
├── barry-app.json     required: the manifest
├── main.qml           required: the app ("main" in the manifest)
├── icon.svg           recommended: the tile's icon ("icon")
└── ...                anything else the app uses: more QML, images, sounds, fonts
```

Any layout below that is fine. QML files reach each other and their files
by relative paths (`"images/logo.png"`, `import "parts"`).

## barry-app.json

```json
{
  "format": 1,
  "id": "io.github.project-barry.dice",
  "name": "Dice",
  "version": "1.0.0",
  "main": "main.qml",
  "icon": "icon.svg",
  "description": "Roll up to six dice (d4 to d20) with a tap.",
  "author": "Project Barry",
  "homepage": "https://github.com/project-barry/barry-launcher-apps"
}
```

| Field | | |
| --- | --- | --- |
| `format` | optional, `1` | The package format the app is written for. Barry Launcher refuses a format it doesn't know, so a future format won't half-work. |
| `id` | **required** | Unique, forever. Reverse domain, lower case: letters, digits, `-` and `_`, at least one `.` between parts, up to 64 characters. `io.github.yourname.appname` is yours if you're `yourname` on GitHub. An install with the same id **updates** that app. |
| `name` | **required** | The tile's label, up to **20** characters. Long names shrink to fit the tile. |
| `version` | **required** | Any text; [semantic versions](https://semver.org) (`1.2.0`) are clearest. Shown in the install message. |
| `main` | **required** | The QML file to run, inside the folder. Its root item fills the screen ([the `barry` object](The-barry-Object)). |
| `icon` | optional | A `.svg` or `.png` inside the folder, square. Without one, the tile shows a plain app icon (*My First App* below). |
| `description`, `author`, `homepage` | optional | Text about the app. Barry Launcher keeps them for a future app list or store. |

![Home screen tiles: Barry Launcher's apps, Dice with its own icon, and My First App with the plain icon](https://raw.githubusercontent.com/project-barry/barry-launcher-apps/main/wiki/images/home-with-apps.png)

## The archive

- **Kinds:** `.zip`, `.tar.gz` / `.tgz`, `.tar.xz` / `.txz`, `.tar.bz2` /
  `.tbz2`, `.tar`.
- **Layout:** `barry-app.json` at the top of the archive, *or* inside its one
  top folder. Both of these install:

  ```
  dice-1.0.0.zip              dice-1.0.0.zip
  ├── barry-app.json          └── dice/
  ├── main.qml                    ├── barry-app.json
  └── ...                         └── ...
  ```

  `barry-app pack` makes the second kind. macOS's `__MACOSX` folder and
  `.DS_Store` files are ignored.

## Limits and rules

An archive that breaks any of these isn't installed, and the message says
why.

| | |
| --- | --- |
| Archive size | 100 MB |
| Unpacked size | 300 MB |
| Files | 5,000 |
| Links | none: no symbolic links, hard links or device files |
| Paths | all inside the app folder: no `..`, no absolute paths |
| `main`, `icon` | must exist in the folder |
| `id` | not one of Barry Launcher's own apps |

Files are installed as plain files: the archive's owners and permissions
are dropped.

## Where it goes

| | |
| --- | --- |
| The app | `~/.local/share/barry_launcher/apps/ID/`, replaced whole on update |
| Its data (`barry.dataDir`) | `~/.local/share/barry_launcher/app-data/ID/`, kept across updates, deleted on remove |
| Its log (everything it prints) | `~/.cache/barry_launcher/ID.log`, started afresh each run |

## How it runs

Barry Launcher runs every app the same way:

```
qml6 /usr/share/barry_launcher/shell/AppHost.qml -- APPDIR MAIN ID NAME DATADIR
```

`AppHost.qml` opens a full-screen window titled `Barry App ID` and loads
your `main` into it ([source](https://github.com/project-barry/barry-launcher-apps/blob/main/tools/AppHost.qml)).
The environment also has `BARRY_APP_ID`, `BARRY_APP_DIR` and
`BARRY_APP_DATA`, for anything outside QML that needs them.

`XDG_CONFIG_HOME` and `XDG_DATA_HOME` point inside the app's data folder
(`.config` and `.local/share` there), so whatever Qt or a library saves for
the app by default lands with the app's own data and is removed with it.
Qt's compiled-QML disk cache is off for apps (`QML_DISABLE_DISK_CACHE=1`);
the shared font and GPU caches stay where they are.

One app, one window. Tapping its tile again brings it forward instead of
starting a second copy.
