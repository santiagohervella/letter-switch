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

`~/.config/letter-switch/config.toml` is reloaded whenever it changes.

`modifier` is the key held while pressing a letter: `right_option` (the default), `left_option`, `right_command`, `left_command`, `right_control` or `left_control`. Only that exact modifier counts, so holding any other modifier alongside it leaves the keystroke alone.

Pins give an app a key other than its first letter, and launch it when nothing on that key is running:

```toml
modifier = "right_option"

[pins]
i = "com.mitchellh.ghostty"
o = "md.obsidian"
```

Find an app's bundle ID with `osascript -e 'id of app "Ghostty"'`.
