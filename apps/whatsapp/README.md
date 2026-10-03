# WhatsApp

[WhatsApp Web](https://web.whatsapp.com) on Barry Launcher's bottom
screen, in a Firefox window of its own: the example of a **web app** (see
[Web apps](https://github.com/project-barry/barry-launcher-apps/wiki/Web-Apps)
in the wiki).

WhatsApp has no Linux app of its own, for ARM or anything else; WhatsApp
Web is its official way in from a desktop browser.

**Not made by WhatsApp or Meta.** This app only opens WhatsApp Web; it has
no code of its own, and nothing passes through anyone but WhatsApp.

## Using it

1. Install `whatsapp.zip` from the
   [latest release](https://github.com/project-barry/barry-launcher-apps/releases/latest)
   (Quick Access → Barry Launcher → Apps → Install app…).
2. Open it from the home screen. A QR code shows.
3. On your phone: WhatsApp → **Settings → Linked devices → Link a device**,
   and scan the code.

It stays linked until you unlink it on your phone or remove the app.
Voice messages can use the microphone without asking (`"allow":
["microphone"]`); notifications are off.

**Removing the app** deletes its Firefox profile: you're logged out and
nothing of your chats stays on the device. Unlink it on your phone too.

## License

The manifest is MIT, like the rest of this repository. The icon is
Tabler Icons' `brand-whatsapp` (MIT). WhatsApp is a trademark of WhatsApp
LLC.
