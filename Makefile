DEVELOPER_DIR ?= /Applications/Xcode-26.3.0.app/Contents/Developer
export DEVELOPER_DIR

APP := build/LetterSwitch.app
VERSION ?= dev
IDENTITY := LetterSwitch Dev
BUNDLE_ID := com.santiagohervella.letter-switch
INSTALL_DIR := $(HOME)/Applications

.PHONY: app run install identity logs clean

app: identity
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/LetterSwitch $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	plutil -replace CFBundleShortVersionString -string "$(VERSION)" $(APP)/Contents/Info.plist
	codesign --force --sign "$(IDENTITY)" --identifier $(BUNDLE_ID) $(APP)

identity:
	@security find-certificate -c "$(IDENTITY)" >/dev/null 2>&1 || scripts/signing-identity.sh

run: app
	-pkill -x LetterSwitch
	@while pgrep -x LetterSwitch >/dev/null; do sleep 0.1; done
	open $(APP)

install: app
	@running=$$(pgrep -x LetterSwitch >/dev/null && echo yes); \
	pkill -x LetterSwitch; \
	while pgrep -x LetterSwitch >/dev/null; do sleep 0.1; done; \
	mkdir -p "$(INSTALL_DIR)"; \
	rm -rf "$(INSTALL_DIR)/LetterSwitch.app"; \
	cp -R $(APP) "$(INSTALL_DIR)/"; \
	if [ "$$running" = yes ]; then open "$(INSTALL_DIR)/LetterSwitch.app"; fi

logs:
	log stream --level debug --predicate 'subsystem == "$(BUNDLE_ID)"'

clean:
	rm -rf build .build
