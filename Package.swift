import PackageDescription

let package = Package(
    name: "CarthageInputFiles",
    dependencies: [
        .Package(url: "git@github.com:kylef/Commander.git", majorVersion: 0, minor: 6),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2),
    ]
)
