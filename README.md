# LetterSwitch

A keyboard-only macOS app switcher. Hold right option and press a letter to switch to the most recently used running app whose name starts with that letter. Press the letter again to cycle through the rest.

```sh
make install     # build, sign, copy into ~/Applications and start at login
make run         # build, sign and launch from build/, replacing the installed copy until the next install
make stop        # stop whichever copy is running
make uninstall   # remove the app and its launch agent
make logs        # stream the app's logs
```

The build uses Xcode 26.3's toolchain and signs with a local "LetterSwitch Dev" certificate. `scripts/signing-identity.sh` creates it in the login keychain on the first build. The signature has to stay the same across builds so that the Accessibility permission survives rebuilds.

`make install` loads a launch agent at `~/Library/LaunchAgents/com.santiagohervella.letter-switch.plist`. launchd starts the app at login and restarts it if it crashes.

## Config

`~/.config/letter-switch/config.yaml` is reloaded whenever it changes.

`modifier` is the key held while pressing a letter: `right_option` (the default), `left_option`, `right_command`, `left_command`, `right_control` or `left_control`. Only that exact modifier counts, so holding any other modifier alongside it leaves the keystroke alone.

`show_no_apps_message: true` flashes a message in the middle of the screen with your focused window when nothing answers to a key. It's off by default.

`hide_other_apps: true` hides every other app whenever you switch to or launch one, so only one app is visible at a time. It's off by default.

Every running app answers to the first letter of its name. An entry under `apps`, keyed by bundle ID, changes that per app:

```yaml
modifier: right_option
show_no_apps_message: true

apps:
  com.mitchellh.ghostty:
    keys: [g, i]

  md.obsidian:
    launch: true
```

- `keys` is the full list of keys the app answers to, replacing its first letter. List the first letter too to keep it.
- `launch: true` launches the app from any of its keys when nothing on that key is running. Two apps launching from the same key cancel each other out, and the log says so.
- Unknown settings and invalid keys make the whole file invalid, and the previous config stays in place.

Find an app's bundle ID with `osascript -e 'id of app "Ghostty"'`.
