import Foundation
import SwiftParser
import SwiftSyntax

struct Scanner {
    let rootURL: URL

    func process() throws {
        for sourceURL in findSwiftFiles() {
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let tree = Parser.parse(source: source)
            let collector = TypeInfoCollector(viewMode: .sourceAccurate)
            collector.walk(tree)

            // TODO: Process collector.collectedTypes to extract game-specific data
            print("📁 Processing: \(sourceURL.lastPathComponent)")
            for typeInfo in collector.collectedTypes {
                print("  🏗️  Found type: \(typeInfo.name) (\(typeInfo.kind)) with \(typeInfo.properties.count) properties")
            }
        }
    }
}

extension Scanner {
    private func findSwiftFiles() -> [URL] {
        guard
            let enumerator = FileManager.default.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else { return [] }

        var swiftFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            guard
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                resourceValues.isDirectory == false,
                fileURL.pathExtension == "swift",
                !fileURL.lastPathComponent.hasSuffix("Tests.swift") // Exclude test files
            else { continue }

            swiftFiles.append(fileURL)
        }

        return swiftFiles
    }
}
