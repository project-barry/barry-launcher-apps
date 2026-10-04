# Claude

[claude.ai](https://claude.ai) on Barry Launcher's bottom screen, in a
Firefox window of its own: a **web app** like WhatsApp (see
[Web apps](https://github.com/project-barry/barry-launcher-apps/wiki/Web-Apps)
in the wiki).

**Not made by Anthropic.** This app only opens claude.ai; it has no code
of its own, and nothing passes through anyone but Anthropic. It uses your
own Claude account and plan, with everything claude.ai has: your chats,
projects, files and voice input.

## Using it

1. Install `claude.zip` from the
   [latest release](https://github.com/project-barry/barry-launcher-apps/releases/latest)
   (Quick Access → Barry Launcher → Apps → Install app…).
2. Open it from the home screen and log in. "Continue with email" sends a
   code you can type with the Barry keyboard; Google login works too.

It stays logged in between runs. Voice input can use the microphone
without asking (`"allow": ["microphone"]`); notifications are off. The
page is drawn at zoom 1.5 (827 CSS pixels across on the Thor), so chat
text is readable on the small screen.

**Removing the app** deletes its Firefox profile: you're logged out and
nothing of your chats stays on the device (they stay in your account).

## License

The manifest is MIT, like the rest of this repository. The icon is
Tabler Icons' `sparkles` (MIT), not Anthropic's logo. Claude is a
trademark of Anthropic PBC.
