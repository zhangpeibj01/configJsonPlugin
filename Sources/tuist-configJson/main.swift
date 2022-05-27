import Foundation
import ArgumentParser

struct ConfigJsonOptions: ParsableArguments {

    @Flag(help: "Show config.json content")
    var show = false

    @Flag(help: "Clear config.json content")
    var clear = false

    @Option(help: "add key-value to config.json, supported key: 'mockAllModules', 'focusModules', 'mockModules', 'integrateSwiftLint', 'uploadBuildLog', 'keepAllTargets', 'previewMode', 'enableRemoteCache', 'remoteCacheProducer', 'remotePreviewResumeCacheProducer', example: \"focusModules: [StudyGroup]\".")
    var add: String?

    @Option(help: "remove key-value from config.json, supported key: 'mockAllModules', 'focusModules', 'mockModules', 'integrateSwiftLint', 'uploadBuildLog', 'keepAllTargets', 'previewMode', 'enableRemoteCache', 'remoteCacheProducer', 'remotePreviewResumeCacheProducer', example: \"mockAllModules\".")
    var remove: String?
}

let path = FileManager.default.currentDirectoryPath + "/Tuist/config.json"
let pathURL = URL(fileURLWithPath: path)

var fileString: String {
    do {
        let data = try Data(contentsOf: pathURL)
        let convertedString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        return convertedString
    } catch { return "" }
}

let options = ConfigJsonOptions.parseOrExit()

if options.show {
    createFile()
    print(fileString)
}

if options.clear {
    deleteFile()
    createFile()
}

if
    let remove = options.remove,
    let result = stringRemoved(targetString: remove, originString: fileString)
{
    deleteFile()
    createFile(originString: result)
}

if let add = options.add {
    let range = add.range(of: ":")
    if let range = range {
        let prefixString = "\(add.prefix(upTo: range.lowerBound))"
        let suffixString = add.suffix(from: range.upperBound)
        var resultString = stringRemoved(targetString: prefixString, originString: fileString) ?? fileString
        let remainString = resultString.count == 4 ? "\n" : ",\n"
        let insertIndex = fileString.index(fileString.startIndex, offsetBy: 2)
        resultString.insert(contentsOf: "\"\(prefixString)\":\(suffixString)\(remainString)", at: insertIndex)
        deleteFile()
        createFile(originString: resultString)
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/bin/zsh")
task.arguments = ["-c", "tuist clean manifests"]
task.standardOutput = nil
try task.run()
task.waitUntilExit()

// MARK: - Helper
func createFile(originString: String = "{\n\n}") {
    if !FileManager.default.fileExists(atPath: pathURL.path) {
        let data = originString.data(using: .utf8)
        FileManager.default.createFile(atPath: pathURL.path, contents: data, attributes: nil)
    }
}

func deleteFile() {
    do {
        try FileManager.default.removeItem(atPath: path)
    } catch { }
}

func stringRemoved(targetString: String, originString: String) -> String? {
    let modifiedTargetString = "\"\(targetString)\""
    let prefixRange = originString.range(of: modifiedTargetString)
    if let prefixRange = prefixRange {
        let preString = originString.prefix(upTo: prefixRange.lowerBound)
        let remainString = originString.suffix(from: prefixRange.upperBound)
        let suffixRange = remainString.range(of: "\n")
        if let suffixRange = suffixRange {
            let suffixString = remainString.suffix(from: suffixRange.upperBound)
            var resultString = "\(preString)\(suffixString)"
            var count = 0
            for element in resultString {
                if element == "\n" {
                    count += 1
                }
            }
            if count == 3 {
                resultString = resultString.replacingOccurrences(of: ",", with: "")
            }
            return "\(resultString)"
        }
    }
    return nil
}
