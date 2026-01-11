.PHONY: build clean install release

BUILD_DIR = build
APP_NAME = hop
RELEASE_DIR = $(BUILD_DIR)/Build/Products/Release
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

build:
	xcodebuild -scheme $(APP_NAME) -configuration Release -derivedDataPath $(BUILD_DIR) build

clean:
	rm -rf $(BUILD_DIR)

install: build
	cp -r $(RELEASE_DIR)/$(APP_NAME).app /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

release: build
	cd $(RELEASE_DIR) && zip -r $(APP_NAME)-$(VERSION)-macos.zip $(APP_NAME).app
	gh release create $(VERSION) $(RELEASE_DIR)/$(APP_NAME)-$(VERSION)-macos.zip \
		--title "$(VERSION)" \
		--generate-notes
	@echo "Released $(VERSION) to GitHub"
