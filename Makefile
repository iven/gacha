SWIFT_FORMAT := swift format
SWIFTLINT := swiftlint
SWIFT_SOURCES := Package.swift Sources Tests

.PHONY: format fix lint test check cli dmg reset-settings dev

format:
	$(SWIFT_FORMAT) format --in-place --recursive $(SWIFT_SOURCES)

fix: format
	$(SWIFTLINT) lint --fix --config .swiftlint.yml

lint:
	$(SWIFTLINT) lint --config .swiftlint.yml

test:
	swift test

check: fix lint test

cli:
	scripts/build-cli.sh

dmg:
	scripts/build-app.sh
	scripts/build-cli.sh
	scripts/build-dmg.sh

reset-settings:
	pkill -x Gacha || true
	defaults delete Gacha 2>/dev/null || true
	rm -rf "$$HOME/Library/Saved Application State/Gacha.savedState"
	killall cfprefsd 2>/dev/null || true

dev:
	pkill -x Gacha || true
	swift run Gacha
