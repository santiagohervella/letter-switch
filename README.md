# LetterSwitch

A keyboard-only macOS app switcher. Hold right option and press a letter to switch to the most recently used running app whose name starts with that letter. Press the letter again to cycle through the rest.

```sh
brew install santiagohervella/tap/letter-switch
```

The app sets itself up to start at login the first time it opens. Grant it Accessibility when macOS asks.

## How it starts

Opening LetterSwitch.app writes a launch agent to `~/Library/LaunchAgents/com.santiagohervella.letter-switch.plist`, loads it and quits. launchd then runs the app in the background, starts it at every login and restarts it if it crashes. Opening the app again rewrites the agent and restarts it, which is how updates take effect.

## Development

```sh
make install     # build, sign, copy into /Applications and start it
make stop        # stop the running copy
make uninstall   # remove the app and its launch agent
make logs        # stream the app's logs
make test        # run the unit tests
make release VERSION=x.y  # test, build, sign, publish a GitHub release and update the Homebrew cask
make icon        # redraw AppIcon.icns from scripts/make-icon.swift
```

The build uses Xcode 26.3's toolchain and signs with a local "LetterSwitch Dev" certificate. `scripts/signing-identity.sh` creates it in the login keychain on the first build. Local builds and releases share that signature, so the Accessibility permission survives rebuilds and updates. Back up the certificate by exporting "LetterSwitch Dev" from Keychain Access as a `.p12`. A new certificate means granting Accessibility again on every Mac.

The app is self-signed rather than notarized, so the Homebrew cask clears the quarantine flag after installing. A copy downloaded through a browser needs `xattr -dr com.apple.quarantine LetterSwitch.app` before it opens.

## Config

`~/.config/letter-switch/config.yaml` is reloaded whenever it changes.

`modifier` is the key held while pressing a letter: `right_option` (the default), `left_option`, `right_command`, `left_command`, `right_control` or `left_control`. Only that exact modifier counts, so holding any other modifier alongside it leaves the keystroke alone.

`show_no_apps_message: true` flashes a message in the middle of the screen with your focused window when nothing answers to a key. It's off by default.

`hide_other_apps: true` hides every other app whenever you switch to or launch one, so only one app is visible at a time. It's off by default.

Every running app answers to the first letter of its name. An entry under `apps`, keyed by app name, changes that per app:

```yaml
modifier: right_option
show_no_apps_message: true

apps:
  Ghostty:
    keys: [g, i]

  Obsidian:
    launch: true
```

- `keys` is the full list of keys the app answers to, replacing its first letter. List the first letter too to keep it.
- `launch: true` launches the app from any of its keys when nothing on that key is running. Two apps launching from the same key cancel each other out, and the log says so.
- Unknown settings and invalid keys make the whole file invalid, and the previous config stays in place.

An app's name is its `.app` file name in `/Applications`, `/System/Applications`, `~/Applications` or a folder inside one of those, so Zoom is `zoom.us`. A bundle ID works too, for when two apps share a name. Find one with `osascript -e 'id of app "Ghostty"'`.
