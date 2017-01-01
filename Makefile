PREFIX=/usr/local
BUILD_TOOL=xcodebuild

EXECUTABLE_NAME=carthage-input-files
PROJECT_NAME=CarthageInputFiles
XCODEFLAGS=-project $(PROJECT_NAME).xcodeproj

CARTHAGEINPUTFILES_EXECUTABLE=./.build/release/$(PROJECT_NAME)

SWIFT_COMMAND=/usr/bin/swift
SWIFT_BUILD_COMMAND=$(SWIFT_COMMAND) build
SWIFT_TEST_COMMAND=$(SWIFT_COMMAND) test

debug:
	$(SWIFT_BUILD_COMMAND)

release:
	$(SWIFT_BUILD_COMMAND) --configuration release

update:
	$(SWIFT_COMMAND) package update

generate:
	$(SWIFT_COMMAND) package generate-xcodeproj

test:
	$(SWIFT_TEST_COMMAND)

install:
	$(SWIFT_BUILD_COMMAND) --configuration release
	mkdir -p $(PREFIX)/bin
	cp -f $(CARTHAGEINPUTFILES_EXECUTABLE) $(PREFIX)/bin/$(EXECUTABLE_NAME)

uninstall:
	rm -f $(PREFIX)/bin/$(EXECUTABLE_NAME)
