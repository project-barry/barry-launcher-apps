# The `barry` object

Barry Launcher hands your app's root item a `barry` object as the app
starts. Declare it to get it:

```qml
Rectangle {
    id: app
    required property var barry
    ...
}
```

`required` makes it arrive *before* your bindings and
`Component.onCompleted` run, so you can use it anywhere, even in a
`Settings` location. (A root without the property works too; it just gets
no `barry`.)

## Properties

| | | |
| --- | --- | --- |
| `barry.scale` | real | `1` on the Thor's bottom screen (1240 × 1080). Smaller or larger on other screens. Multiply your sizes by it. |
| `barry.dataDirUrl` | url | Your app's own folder for saving things, as a `file://` URL ending in `/`. Kept across updates, deleted when the app is removed. |
| `barry.dataDir` | string | The same folder, as a plain path. |
| `barry.appDirUrl` | url | Where your app's files are installed (read-only in spirit: an update replaces it). |
| `barry.appDir` | string | The same, as a plain path. |
| `barry.appId` | string | Your `id` from `barry-app.json`. |
| `barry.appName` | string | Your `name`. |

## Functions

| | |
| --- | --- |
| `barry.close()` | Quit the app. The bottom screen goes back to what it showed before (the home screen, usually). |

You don't need a close button: users can go home by swiping up from the
bottom edge or holding the AYN button, and close your app with the ✕ on its
tile. A close button is still friendly in an app people use briefly.

## Saving things

### Settings (simplest)

```qml
import QtCore

Settings {
    id: saved
    location: app.barry.dataDirUrl + "settings.ini"
    property int highScore: 0
    property string playerName: ""
}
```

Assign to a property (`saved.highScore = 120`) and it's saved; it's read
back on the next start. Good for numbers, text, true/false.

### Lists and records

QML can read files but not write them, so keep lists and records in a
`Settings` string, as JSON:

```qml
Settings { id: saved; location: app.barry.dataDirUrl + "notes.ini"; property string notes: "[]" }

function addNote(text) {
    const list = JSON.parse(saved.notes)
    list.unshift({ text: text, at: Date.now() })
    saved.notes = JSON.stringify(list)
}
```

Keep it to a few hundred kilobytes. For more, `QtQuick.LocalStorage` (a
SQLite database) is available, though it keeps its database in Qt's own
folder rather than yours.

## Screen and input

- **Size:** your root item fills the screen. On the Thor that's 1240 × 1080
  (landscape). Use `anchors` and `barry.scale` rather than fixed positions
  so other screens work.
- **Touch** is the input. Use `TapHandler`, `DragHandler`, `PinchHandler`
  or `MultiPointTouchArea`. The Thor's sticks and buttons stay with Steam
  and the game on the top screen.
- **The bottom edge** belongs to Barry Launcher: a swipe up from the bottom
  45 pixels goes home. Keep swipes away from it.
- **Typing:** Barry Launcher's on-screen keyboard follows text focus over
  the accessibility bus, as it does for Firefox and Signal. Qt Quick's text
  fields report their focus there, but check it with your own app on the
  device.
- **Going home doesn't close your app:** it keeps running behind the home
  screen until its tile's ✕, or `barry.close()`. Stop timers and animations
  that don't need to run, so a background app costs nothing.

## What you can import

Everything that Qt 6.8 on SteamOS has; the most useful:

| Module | For |
| --- | --- |
| `QtQuick` | items, text, images, animation, touch handlers |
| `QtQuick.Controls` | buttons, sliders, lists, text fields (styles: Basic, Fusion, Material, Universal) |
| `QtQuick.Layouts` | rows, columns and grids that share space |
| `QtQuick.Shapes` | lines and curves, SVG paths |
| `QtQuick.Particles`, `QtQuick.Effects` | particles, blur, shadow, colour effects |
| `QtCore` | `Settings`, standard paths |
| `QtMultimedia` | sound and video |
| `QtQuick3D` | 3D scenes |
| `QtWebSockets`, `XMLHttpRequest` | the network |
| `QtTextToSpeech`, `QtSensors`, `QtPositioning` | speech, sensors, location (if the device has them) |

These come with SteamOS (its KDE desktop needs them). Other distributions
running the portable Barry Launcher may have fewer: say in your README what
your app needs.

**Not supported:** native (C++) QML plugins, other programs, and other
languages. An app is QML and JavaScript, plus its images, sounds and fonts.
