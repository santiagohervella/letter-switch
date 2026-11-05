# LetterSwitch

A keyboard-only macOS app switcher. Hold right option and press a letter to switch to the most recently used running app whose name starts with that letter. Press the letter again to cycle through the rest.

```sh
make run       # build, sign and launch from build/
make install   # build, sign and copy into ~/Applications
make logs      # stream the app's logs
```

The build uses Xcode 26.3's toolchain and signs with a local "LetterSwitch Dev" certificate. `scripts/signing-identity.sh` creates it in the login keychain on the first build. The signature has to stay the same across builds so that the Accessibility permission survives rebuilds.
