# CarthageInputFiles

This command lets you free from setting framework paths every time when using `Carthage`.

## Usage

Add `Run Script` for `Carthage` in Xcode.

`/usr/local/bin/carthage copy-frameworks`

```swift
carthage update
carthage-input-files YourXcodeProject.xcodeproj
```

## Installation

- Clone this repository

`git clone https://github.com/ken0nek/CarthageInputFiles.git`

or

`git clone git@github.com:ken0nek/CarthageInputFiles.git`

- Make

`make install`

`carthage-input-files` command will be moved to `/usr/local/bin` by default
