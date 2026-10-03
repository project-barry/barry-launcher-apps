# Barry Launcher apps

Make your own apps for **Barry Launcher**, the home screen on the AYN Thor's
bottom screen in [PB-OS](https://github.com/project-barry/pb-os) (and in the
[portable Barry Launcher](https://github.com/project-barry/barry-launcher)).

A Barry Launcher app is a folder with a QML file and a small
`barry-app.json`. Zip the folder, install the zip from Barry Launcher's
Decky plugin, and the app gets its own tile on the home screen.

![Barry Launcher on an AYN Thor's bottom screen, with the Dice app installed](wiki/images/thor-home.png)

## What's here

| Folder | |
| --- | --- |
| [`apps/dice`](apps/dice) | **Dice**, the example app: up to six dice, d4 to d20, with a tumble-and-bounce roll. Shows sizing, touch, animation and saving settings. |
| [`template`](template) | A bare starting point: copy it, rename it, build on it. |
| [`tools`](tools) | `barry-app check`, `pack` and `run`: check an app, zip it, and try it on your computer. |
| [`wiki`](wiki) | The source of [the wiki](https://github.com/project-barry/barry-launcher-apps/wiki). |

## Try the example

Download `dice.zip` from the
[latest release](https://github.com/project-barry/barry-launcher-apps/releases/latest).
On the Thor, go to Quick Access (•••) → **Barry Launcher** → **Apps** →
**Install app…** and pick the zip.

## Make your own

```sh
cp -r template myapp                     # then set the id and name in myapp/barry-app.json
python3 tools/barry-app run myapp        # try it in a window (needs Qt 6)
python3 tools/barry-app pack myapp       # make the zip to install
```

The wiki explains it all, with pictures:

- [Your first app](https://github.com/project-barry/barry-launcher-apps/wiki/Your-First-App)
- [Installing apps](https://github.com/project-barry/barry-launcher-apps/wiki/Installing-Apps)
- [App package reference](https://github.com/project-barry/barry-launcher-apps/wiki/App-Package-Reference)
- [The `barry` object](https://github.com/project-barry/barry-launcher-apps/wiki/The-barry-Object)
- [Design guidelines](https://github.com/project-barry/barry-launcher-apps/wiki/Design-Guidelines)
- [Tools](https://github.com/project-barry/barry-launcher-apps/wiki/Tools)

## Status

App support is new, so the package format may still grow (its `"format": 1`
says which version an app is written for). Apps run as your user, without a
sandbox: install apps only from people you trust.

## License

MIT (see [LICENSE](LICENSE)): copy the example and the template into your
own apps freely. The files in `tools/` come from pb-os and keep its license
for its own scripts, the GNU GPL version 2 (see [tools/README.md](tools/README.md)).
