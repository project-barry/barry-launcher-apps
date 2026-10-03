# Installing apps

A Barry Launcher app comes as an archive: a `.zip` (most common), or a
`.tar.gz`, `.tar.xz` or `.tar.bz2`. You need:

- **PB-OS on an AYN Thor**, with Barry Launcher's app support (October 2026
  or later), or the [portable Barry Launcher](https://github.com/project-barry/barry-launcher).
- **The bottom screen on**, because Barry Launcher installs the app.

## 1. Get the zip onto the Thor

Any of these work. Put it somewhere you can find it; **Downloads** is where
the installer looks first.

- **Firefox on the bottom screen:** open the app's download page (a GitHub
  release, say) and download the zip. It lands in Downloads.
- **Desktop Mode:** download it with a browser, or copy it from a USB stick
  or microSD card into Downloads.
- **From another computer, over SSH** (PB-OS has SSH on, as the `steamos`
  user): `scp myapp.zip steamos@THOR-ADDRESS:~/Downloads/`

## 2. Install it

In Game Mode:

1. Open **Quick Access** (the ••• button).
2. Choose **Barry Launcher**, then the **Apps** tab (LB/RB switch tabs).
3. Choose **Install app…** at the bottom of the list.
4. Pick the zip in the file browser.

Barry Launcher checks the app and installs it. "Installed Dice 1.0.0."
appears under the button, the app joins the list, and its tile is on the
home screen.

If something is wrong with the archive, the message says what, for
example *"barry-app.json: "name" is 25 characters; the tile has room for 20"*.
Nothing is installed then.

### From a terminal

In Desktop Mode's Konsole, or over SSH:

```sh
barry-app install ~/Downloads/dice-1.0.0.zip
barry-app list
```

## Updating an app

Install the newer zip the same way. An app with the same id replaces the
old version, and **keeps what it saved** (its settings, scores and so on).
If the old version was open, it closes; open it again from its tile.

## Removing an app

- **Quick Access → Barry Launcher → Apps:** the **✕** next to the app, then
  **Remove**. Apps you installed have a ✕, and so does Dino.
- **Terminal:** `barry-app remove io.github.project-barry.dice` (the app's id;
  `barry-app list` shows it). Add `--keep-data` to keep what it saved.

Removing an app leaves nothing behind: an open app is closed first, then
its files, everything it saved, its log and its place on the home screen
are deleted.

**Dino** comes with Barry Launcher, but it's an app like the others: remove
it and it stays gone, even after updates. To get it back, install `dino.zip`
from the [releases](https://github.com/project-barry/barry-launcher-apps/releases/latest).

## Hiding and ordering

Your apps sort like Barry Launcher's own: in the **Apps** tab, the switch
shows or hides a tile and ▲ ▼ move it. Barry Launcher's home screen fits
nine tiles; with more, it scrolls.

## Where things are

| | |
| --- | --- |
| Installed apps | `~/.local/share/barry_launcher/apps/ID/` |
| What each app saves | `~/.local/share/barry_launcher/app-data/ID/` |
| Each app's log | `~/.cache/barry_launcher/ID.log` |

## Safety

Apps aren't sandboxed. An app runs as you, and can read your files and use
the network like any program you install. Install apps only from people you
trust, and prefer apps whose source you can read (a QML app's source is the
app itself: open the zip and look).
