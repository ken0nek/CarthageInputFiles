import Foundation
import Commander
import Rainbow

// target:

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
        print("Please input valid xcode project (*.xcodeproj)".red)
        return
    }

    guard let p = platforms[platform] else {
        print("Please input valid platform name (ios, mac, watchos, tvos)".red)
        return
    }

    print("Processing \(project)...\n")

    let dir = FileManager.default.currentDirectoryPath
    let cartfilePath = dir.appendingPath(cartfile)
    let cartfileURL = URL(fileURLWithPath: cartfilePath)

    do {
        if try cartfileURL.checkResourceIsReachable() {
            print("Found \(cartfilePath)\n")
        }
    } catch let error {
        print("Error: \(error.localizedDescription)".red)
        print("Create `Cartfile` and execute `carthage update`")
        return
    }

    let pbxprojPath = dir.appendingPath(project).appendingPath(pbxproj)
    let pbxprojURL = URL(fileURLWithPath: pbxprojPath)

    do {
        if try pbxprojURL.checkResourceIsReachable() {
            print("Found \(pbxprojPath)\n")
        }
    } catch let error {
        print("Error: \(error.localizedDescription)".red)
        print("Cannot process \(pbxprojPath)")
        return
    }

    guard let data = try? Data(contentsOf: pbxprojURL) else { return }

    guard let dic = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else { return }
    var dicToWrite = dic

    guard let objects = dic["objects"] as? [String: Any] else { return }
    var objectsToWrite = objects

    var found = false
    var key = ""

    var currentInputPaths: [String] = []

    for (k, v) in objects {
        guard let dd = v as? [String: Any] else { continue }

        guard let isa = dd["isa"] as? String else { continue }
        guard isa == "PBXShellScriptBuildPhase" else { continue }

        guard let shellScript = dd["shellScript"] as? String else { continue }
        guard shellScript.hasSuffix("copy-frameworks") else { continue }
        guard let inputPaths = dd["inputPaths"] as? [String] else { continue }

        currentInputPaths = inputPaths

        found = true
        key = k
    }

    if !found {
        print("This project has no run scripts for Carthage".red)
        print("[Xcode] -> [Targets] -> [Build Phases]: [+ New Run Script Phase]")
        print("and add this command `/usr/local/bin/carthage copy-frameworks`")
        return
    }

    let prefixWithPlatform = prefix.appendingPath(p)
    let buildPathWithPlatform = "Carthage/Build".appendingPath(p)

    print("Searching frameworks in \(buildPathWithPlatform)...\n")

    guard let enumerator = FileManager.default.enumerator(atPath: buildPathWithPlatform) else { return }

    var frameworks: [String] = []
    for f in enumerator {
        guard let file = f as? String else { return }

        // Only include top level framework
        guard file.hasSuffix(".framework") && file.components(separatedBy: "/").count == 1 else { continue }
        frameworks.append(file)
    }

    guard !frameworks.isEmpty else {
        print("No frameworks found :(".red)
        print("execute `carthage update` or edit `Cartfile`")
        return
    }

    let frameworksWithPrefix = frameworks.map { prefixWithPlatform.appendingPath($0) }

    let new = Set(frameworksWithPrefix)
    let current = Set(currentInputPaths)
    let diff = new.subtracting(current)

    guard !diff.isEmpty else {
        print("Nothing to do.\n")
        print("Current Input Files:\n")
        currentInputPaths.forEach { print($0) }
        return
    }

    var frameworksDiff = [String](diff)

    while true {

        print("\nThese frameworks will be newly added to input files for Carthage Run Scripts\n")
        frameworksDiff.enumerated().forEach { print("\($0): \($1)") }

        print("\nThe result will be:\n")
        let tmp = currentInputPaths + frameworksDiff
        tmp.forEach { print($0.green) }

        print("\nis it OK? [[y]/n]")
        print("Please type the number if there are any frameworks you would like to exclude. (Example: 1, 3)")
        guard let yesno = readLine() else { return }

        if yesno == "y" || yesno.isEmpty {
            break
        } else {

            let exclude = yesno.characters.split(separator: ",").flatMap { Int(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
            let excludeUnique = [Int](Set(exclude))

            guard excludeUnique.count <= frameworksDiff.count else {
                print("Invalid input: Too many frameworks to exclude".red)
                return
            }

            guard let max = excludeUnique.max(), max <= frameworksDiff.count - 1 else {
                print("Invalid input: Out of bounds".red)
                return
            }

            excludeUnique.forEach { frameworksDiff.remove(at: $0) }

            guard !frameworksDiff.isEmpty else {
                print("Nothing to do.\n")
                print("Current Input Files:\n")
                currentInputPaths.forEach { print($0) }
                return
            }
        }
    }

    let frameworksToWrite = currentInputPaths + frameworksDiff

    var target = objects[key] as! [String: Any]
    target["inputPaths"] = frameworksToWrite
    objectsToWrite[key] = target
    dicToWrite["objects"] = objectsToWrite

    guard let dataToWrite = try? PropertyListSerialization.data(fromPropertyList: dicToWrite, format: .xml, options: .allZeros) else { return }

    do {
        try dataToWrite.write(to: pbxprojURL, options: .atomic)
    } catch let error {
        print("Error: \(error.localizedDescription)")
        return
    }

    print("Finished!")
    print("Please check if everything is fine :)")

    }.run()
