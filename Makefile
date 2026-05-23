SWIFT_FORMAT := swift format
SWIFTLINT := swiftlint

.PHONY: format lint test check

format:
	$(SWIFT_FORMAT) format --in-place --recursive Package.swift Sources Tests

lint:
	$(SWIFT_FORMAT) lint --recursive --strict Package.swift Sources Tests
	$(SWIFTLINT) lint --strict --config .swiftlint.yml

test:
	swift test

check: lint test
