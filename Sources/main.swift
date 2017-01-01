import Foundation
import Commander

// target:
// prefix: $(SRCROOT)/Carthage/Build/iOS/
// TODO: - find carthage run script

private let cartfile = "Cartfile"
private let pbxproj  = "project.pbxproj"
private let platforms = ["ios": "iOS",
                         "mac": "Mac",
                         "watchos" : "watchOS",
                         "tvos": "tvOS"]

private extension String {

    func appendingPath(_ aString: String) -> String {

        if hasSuffix("/") {
            return self.appending(aString)
        } else {
            return self.appending("/\(aString)")
        }
    }

}

command(
    Argument<String>("project", description: "Xcode project to process (*.xcodeproj)"),
    Option("platform", "ios", description: "platform (ios, mac, watchos, tvos)"),
    Option("prefix", "$(SRCROOT)/Carthage/Build/")
) { project, platform, prefix in

    guard (project.hasSuffix("/") && project.hasSuffix("xcodeproj/")) || project.hasSuffix("xcodeproj") else  {
        print("Please input valid xcode project (*.xcodeproj)")
        return
    }

    guard let p = platforms[platform] else {
        print("Please input valid platform name (ios, mac, watchos, tvos)")
        return
    }

    print("Processing \(project)...\n")

    let dir = FileManager.default.currentDirectoryPath
    let cartfilePath = dir.appendingPath(cartfile)
    let cartfileURL = URL(fileURLWithPath: cartfilePath)

    let pbxprojPath = dir.appendingPath(project).appendingPath(pbxproj)
    let pbxprojURL = URL(fileURLWithPath: pbxprojPath)

    do {
        if try cartfileURL.checkResourceIsReachable() {
            print("Found \(cartfilePath)\n")
        }

        let prefixWithPlatform = prefix.appendingPath(p)
        let buildPathWithPlatform = "Carthage/Build".appendingPath(p)
        guard let enumerator = FileManager.default.enumerator(atPath: buildPathWithPlatform) else { return }

        var frameworks: [String] = []
        for f in enumerator {
            guard let file = f as? String else { return }
            guard file.hasSuffix(".framework") && file.components(separatedBy: "/").count == 1 else { continue }
            frameworks.append(file)
        }
        print("These frameworks will be added to input files for Carthage Run Scripts\n")

        let frameworksWithPrefix = frameworks.map { prefixWithPlatform.appendingPath($0) }
        frameworksWithPrefix.forEach { print($0) }

        print("\nis it OK? [[y]/n]")
        guard let yesno = readLine() else { return }
        guard yesno == "y" || yesno.isEmpty else { return }

        if try pbxprojURL.checkResourceIsReachable() {
            print("Found \(pbxprojPath)\n")
        }

        let data = try Data(contentsOf: pbxprojURL)

        guard let dic = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else { return }
        var dicToWrite = dic

        guard let objects = dic["objects"] as? [String: Any] else { return }
        var objectsToWrite = objects

        var found = false
        var key = ""

        for (k, v) in objects {
            guard let dd = v as? [String: Any] else { continue }

            guard let isa = dd["isa"] as? String else { continue }
            guard isa == "PBXShellScriptBuildPhase" else { continue }

            guard let shellScript = dd["shellScript"] as? String else { continue }
            guard shellScript.hasSuffix("copy-frameworks") else { continue }
            guard let inputPaths = dd["inputPaths"] as? [String] else { continue }
            found = true
            key = k
        }

        if !found {
            print("This project has no run scripts for Carthage")
            return
            //                print("Would you like to add? [[y]/n]")
            //                guard let yesno = readLine() else { return }
            //                guard yesno == "y" || yesno.isEmpty else { return }
            //                print("Not implemented") // cannot set key
        }

        var target = objects[key] as! [String: Any]
        target["inputPaths"] = frameworksWithPrefix
        objectsToWrite[key] = target
        dicToWrite["objects"] = objectsToWrite

        guard let dataToWrite = try? PropertyListSerialization.data(fromPropertyList: dicToWrite, format: .xml, options: .allZeros) else { return }
        try dataToWrite.write(to: pbxprojURL, options: .atomic)

        print("Finished!")

    } catch let error {
        print("Error: \(error.localizedDescription)")
        return
    }

    }.run()
