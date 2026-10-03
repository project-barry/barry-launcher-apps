# Barry Launcher apps

Barry Launcher is the home screen on the AYN Thor's bottom screen in
[PB-OS](https://github.com/project-barry/pb-os). Besides its own apps
(Firefox, Discord, Signal, Trackpad, Keyboard), it runs apps that anyone
can make and share (Dino, which comes with it, is one): a folder with a QML file and a small
`barry-app.json`, zipped.

![Barry Launcher on an AYN Thor's bottom screen, with the Dice app installed](https://raw.githubusercontent.com/project-barry/barry-launcher-apps/main/wiki/images/thor-home.png)

*A screenshot from an AYN Thor: Dice is a user app, the rest are Barry Launcher's own.*

## For everyone

- **[Installing apps](Installing-Apps)**: get an app's zip onto the Thor,
  install it, update it, remove it.
- **Apps to try:** [Dice](Example-Dice), [WhatsApp](Web-Apps), and
  [Dino](https://github.com/project-barry/barry-launcher-apps/tree/main/apps/dino)
  if you removed the one that comes with Barry Launcher. Both are on the
  [releases page](https://github.com/project-barry/barry-launcher-apps/releases/latest).

## For app makers

1. **[Your first app](Your-First-App)**: from the template to an app on
   your home screen, step by step.
2. **[The Dice example](Example-Dice)**: a complete small app, explained.
   **[Web apps](Web-Apps)**: a website as an app, with WhatsApp as the
   example, and no code at all.
3. **[App package reference](App-Package-Reference)**: `barry-app.json`,
   the archive, and the limits.
4. **[The `barry` object](The-barry-Object)**: what Barry Launcher gives your
   app: the screen's scale, a folder to save in, closing.
5. **[Design guidelines](Design-Guidelines)**: sizes, colours and touch, so
   your app feels at home.
6. **[Tools](Tools)**: editors, previewing, icons, and what we suggest.
7. **[Testing and debugging](Testing-and-Debugging)**: logs and common
   mistakes.
8. **[Sharing your app](Sharing-Your-App)**: versions, zips and GitHub
   releases.

## What an app is

- **QML**, run by Qt 6's QML engine (the same one Barry Launcher itself
  uses), with nothing to compile; or a **website**, opened in a Firefox
  window of its own ([Web apps](Web-Apps)).
- **Full screen** on the bottom screen (1240 × 1080 on the Thor), driven by
  touch.
- **Its own tile** on the home screen, with your icon. It can be reordered
  and hidden like the others, and closed with the tile's ✕.
- **Not sandboxed**: an app runs as you, like any program you install.
  Install apps only from people you trust.
