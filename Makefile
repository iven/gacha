SWIFT_FORMAT := swift format
SWIFTLINT := swiftlint
SWIFT_SOURCES := Package.swift Sources Tests

.PHONY: format fix lint test check app dmg dev

format:
	$(SWIFT_FORMAT) format --in-place --recursive $(SWIFT_SOURCES)

fix: format
	$(SWIFTLINT) lint --fix --config .swiftlint.yml

lint:
	$(SWIFTLINT) lint --config .swiftlint.yml

test:
	swift test

check: fix lint test

app:
	scripts/build-app.sh

dmg:
	scripts/build-dmg.sh

dev:
	swift run Gacha
