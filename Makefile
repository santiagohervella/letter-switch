DEVELOPER_DIR ?= /Applications/Xcode-26.3.0.app/Contents/Developer
export DEVELOPER_DIR

APP := build/LetterSwitch.app
VERSION ?= dev
IDENTITY := LetterSwitch Dev
BUNDLE_ID := com.santiagohervella.letter-switch
INSTALL_DIR := $(HOME)/Applications
AGENT := $(HOME)/Library/LaunchAgents/$(BUNDLE_ID).plist
GUI_DOMAIN := gui/$(shell id -u)

.PHONY: app run install uninstall stop identity logs clean

app: identity
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/LetterSwitch $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(APP)/Contents/Info.plist
	codesign --force --sign "$(IDENTITY)" --identifier $(BUNDLE_ID) $(APP)

identity:
	@security find-certificate -c "$(IDENTITY)" >/dev/null 2>&1 || scripts/signing-identity.sh

stop:
	@launchctl bootout $(GUI_DOMAIN) $(AGENT) 2>/dev/null || true
	@pkill -x LetterSwitch || true
	@while pgrep -x LetterSwitch >/dev/null; do sleep 0.1; done

run: app stop
	open $(APP)

install: app stop
	mkdir -p "$(INSTALL_DIR)" "$(dir $(AGENT))"
	rm -rf "$(INSTALL_DIR)/LetterSwitch.app"
	cp -R $(APP) "$(INSTALL_DIR)/"
	sed 's|__INSTALL_DIR__|$(INSTALL_DIR)|' LaunchAgent.plist > $(AGENT)
	launchctl bootstrap $(GUI_DOMAIN) $(AGENT)

uninstall: stop
	rm -f $(AGENT)
	rm -rf "$(INSTALL_DIR)/LetterSwitch.app"

logs:
	log stream --level debug --predicate 'subsystem == "$(BUNDLE_ID)"'

clean:
	rm -rf build .build
