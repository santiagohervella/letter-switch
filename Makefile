DEVELOPER_DIR ?= /Applications/Xcode-26.3.0.app/Contents/Developer
export DEVELOPER_DIR

APP := build/LetterSwitch.app
VERSION ?= dev
IDENTITY := LetterSwitch Dev
BUNDLE_ID := com.santiagohervella.letter-switch
INSTALL_DIR := /Applications
GUI_DOMAIN := gui/$(shell id -u)

.PHONY: app install uninstall stop identity icon test release logs clean

app: identity
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp .build/release/LetterSwitch $(APP)/Contents/MacOS/
	cp AppIcon.icns $(APP)/Contents/Resources/
	cp Info.plist $(APP)/Contents/
	plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(APP)/Contents/Info.plist
	codesign --force --sign "$(IDENTITY)" --identifier $(BUNDLE_ID) $(APP)

icon:
	rm -rf build/AppIcon.iconset
	mkdir -p build/AppIcon.iconset
	swift scripts/make-icon.swift build/icon.png
	for size in 16 32 128 256 512; do \
		sips -z $$size $$size build/icon.png --out build/AppIcon.iconset/icon_$${size}x$${size}.png >/dev/null; \
		sips -z $$((size * 2)) $$((size * 2)) build/icon.png --out build/AppIcon.iconset/icon_$${size}x$${size}@2x.png >/dev/null; \
	done
	iconutil -c icns build/AppIcon.iconset -o AppIcon.icns

identity:
	@security find-certificate -c "$(IDENTITY)" >/dev/null 2>&1 || scripts/signing-identity.sh

stop:
	@launchctl bootout $(GUI_DOMAIN)/$(BUNDLE_ID) 2>/dev/null || true
	@pkill -x LetterSwitch || true
	@while pgrep -x LetterSwitch >/dev/null; do sleep 0.1; done

install: app stop
	rm -rf "$(INSTALL_DIR)/LetterSwitch.app"
	cp -R $(APP) "$(INSTALL_DIR)/"
	open "$(INSTALL_DIR)/LetterSwitch.app"

uninstall: stop
	rm -f $(HOME)/Library/LaunchAgents/$(BUNDLE_ID).plist
	rm -rf "$(INSTALL_DIR)/LetterSwitch.app"

test:
	swift test

release: test
	@test "$(VERSION)" != dev || { echo "usage: make release VERSION=x.y"; exit 1; }
	$(MAKE) app VERSION=$(VERSION)
	ditto -c -k --norsrc --keepParent $(APP) build/LetterSwitch.zip
	GH_TOKEN=$$(gh auth token --user santiagohervella) gh release create v$(VERSION) \
		--repo santiagohervella/letter-switch --title "v$(VERSION)" --generate-notes \
		build/LetterSwitch.zip
	scripts/update-cask.sh $(VERSION) build/LetterSwitch.zip

logs:
	log stream --level debug --predicate 'subsystem == "$(BUNDLE_ID)"'

clean:
	rm -rf build .build
