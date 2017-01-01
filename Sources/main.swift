import Foundation
import Commander

// target, scheme
// platform: ios, osx, watchos, tvos

command(
    Argument<String>("project", description: "Project")
) { project in
    print("Processing \(project)...")
    let carthagePath = FileManager.default.currentDirectoryPath.appending("/Cartfile")
    let carthageURL = URL(fileURLWithPath: carthagePath)

    do {
        if try carthageURL.checkResourceIsReachable() {
            print("Found \(carthagePath)")
        }

    } catch let error {
        print("Error: \(error.localizedDescription)")
        return
    }

}.run()
