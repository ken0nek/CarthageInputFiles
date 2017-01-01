import PackageDescription

let package = Package(
    name: "CarthageInputFiles",
    dependencies: [
        .Package(url: "git@github.com:kylef/Commander.git", majorVersion: 0, minor: 6),
    ]
)
