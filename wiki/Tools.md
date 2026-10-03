# Tools

You can make a Barry Launcher app with any text editor, but a few tools
make it much easier. All of these are free.

## Our suggestions

| If you… | Use |
| --- | --- |
| are new to QML | **Qt Creator** |
| already live in VS Code | **VS Code** with the **Qt Qml** extension |
| like designing visually | **Qt Design Studio**, then finish in code |

## Editors

### Qt Creator (recommended)

[Qt Creator](https://www.qt.io/product/development-tools) is Qt's own
editor: QML completion, error highlighting as you type, a QML debugger and
a profiler. It comes with the Qt Online Installer on Windows and macOS, and
as a package on Linux (`qtcreator`).

Open your app's `main.qml` with **File → Open File or Project**, and run
`barry-app run` in its terminal pane to try it.

### VS Code

Install the **Qt Qml** extension (by The Qt Company) from the marketplace.
It brings syntax highlighting and the `qmlls` language server (completion,
go-to-definition, warnings), using the Qt installed on your computer.

### Qt Design Studio

[Qt Design Studio](https://www.qt.io/product/ui-design-tools) lays out
screens visually and writes QML. Good for a first look. Its projects
include extra modules, so copy the parts you want into a plain `main.qml`
rather than shipping the project.

## Qt's command-line tools

They come with Qt 6:

| | |
| --- | --- |
| `qml file.qml` | runs a QML file (`barry-app run` uses it, with Barry's host around your app) |
| `qmllint file.qml` | finds mistakes before you run: missing properties, typos, unsafe lookups |
| `qmlformat -i file.qml` | tidies the layout of a QML file |
| `qmlls` | the language server editors use |

Run `qmllint` on every file before you share an app. A clean result is a
good sign; the Dice example is clean.

## Previewing

`python3 tools/barry-app run myapp` opens your app in a 1240 × 1080 window,
hosted exactly as on the Thor, with a fresh data folder (or
`--data somefolder` to keep one). It's the quickest loop: edit, save,
close the window, run again.

## Icons and images

| | |
| --- | --- |
| [Inkscape](https://inkscape.org) | draws SVG icons; set the page to 24 × 24 to match Barry's grid |
| [Tabler Icons](https://tabler.io/icons) | 5,000+ line icons, MIT licensed, in Barry's style |
| [Penpot](https://penpot.app) or [Figma](https://figma.com) | design screens and export icons |
| [GIMP](https://www.gimp.org), [Krita](https://krita.org) | pictures and textures |
| [oxipng](https://github.com/shssoichiro/oxipng) | makes PNGs smaller without losing anything |

## Sounds

[Audacity](https://www.audacityteam.org) for editing; keep sound effects as
short WAV files for `SoundEffect`, music as OGG or MP3 for `MediaPlayer`.

## Sharing

- **Git** and **GitHub**: keep your app in a repository, and let GitHub
  build the zip. This repository's
  [workflow](https://github.com/project-barry/barry-launcher-apps/blob/main/.github/workflows/apps.yml)
  checks and packs every app on each push, and attaches the zips to a
  release when you push a tag. Copy it. See [Sharing your app](Sharing-Your-App).

## On the Thor

- **Desktop Mode** has a terminal (Konsole) with `barry-app`, and Qt, so
  `barry-app run` works there too.
- **SSH** from your computer: copy zips over, install with
  `barry-app install`, and read logs (`~/.cache/barry_launcher/ID.log`).

## Learning QML

- [First steps with QML](https://doc.qt.io/qt-6/qmlfirststeps.html), from
  Qt's documentation
- [The QML Book](https://www.qt.io/product/qt6/qml-book), free and
  thorough
- The [Dice example](Example-Dice), and
  [Dino](https://github.com/project-barry/barry-launcher-apps/blob/main/apps/dino/main.qml):
  a whole game in one file
