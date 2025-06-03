import ArgumentParser
import Foundation

@main
struct GnustoAutoWiringTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gnusto-auto-wire",
        abstract: """
            Scans game code and generates necessary ID constants, \
            extensions, and GameBlueprint wiring.
            """,
        version: "0.1.0"
    )

    @Option(help: "An output file for generated content.")
    var output: String

    @Option(help: "A source directory containing files to scan.")
    var source: String

    func run() async throws {
        let sourceURLs = findSwiftFiles(
            in: URL(fileURLWithPath: source)
        )
        var allGameData = GameData()

        for sourceURL in sourceURLs {
            let scanner = Scanner(
                source: try String(contentsOf: sourceURL, encoding: .utf8)
            )
            let fileGameData = scanner.process()

            allGameData = mergeGameData(allGameData, fileGameData)

            print("📁 Processing: \(sourceURL.lastPathComponent)")
        }

        // Print summary of discovered game data
        printGameDataSummary(allGameData)
    }

    private func findSwiftFiles(in rootURL: URL) -> [URL] {
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

    private func mergeGameData(_ target: GameData, _ source: GameData) -> GameData {
        var merged = target

        merged.locationIDs.formUnion(source.locationIDs)
        merged.itemIDs.formUnion(source.itemIDs)
        merged.globalIDs.formUnion(source.globalIDs)
        merged.fuseIDs.formUnion(source.fuseIDs)
        merged.daemonIDs.formUnion(source.daemonIDs)
        merged.verbIDs.formUnion(source.verbIDs)

        merged.itemEventHandlers.formUnion(source.itemEventHandlers)
        merged.locationEventHandlers.formUnion(source.locationEventHandlers)
        merged.gameBlueprintTypes.formUnion(source.gameBlueprintTypes)
        merged.gameAreaTypes.formUnion(source.gameAreaTypes)
        merged.customActionHandlers.formUnion(source.customActionHandlers)
        merged.fuseDefinitions.formUnion(source.fuseDefinitions)
        merged.daemonDefinitions.formUnion(source.daemonDefinitions)

        merged.items.formUnion(source.items)
        merged.locations.formUnion(source.locations)

        merged.itemToAreaMap.merge(source.itemToAreaMap) { _, new in new }
        merged.locationToAreaMap.merge(source.locationToAreaMap) { _, new in new }
        merged.handlerToAreaMap.merge(source.handlerToAreaMap) { _, new in new }
        merged.propertyIsStatic.merge(source.propertyIsStatic) { _, new in new }

        return merged
    }

    private func printGameDataSummary(_ gameData: GameData) {
        print("\n🎮 Discovered Game Data:")
        print("  📍 LocationIDs: \(gameData.locationIDs.sorted().joined(separator: ", "))")
        print("  📦 ItemIDs: \(gameData.itemIDs.sorted().joined(separator: ", "))")
        print("  🌐 GlobalIDs: \(gameData.globalIDs.sorted().joined(separator: ", "))")
        print("  🧨 FuseIDs: \(gameData.fuseIDs.sorted().joined(separator: ", "))")
        print("  👿 DaemonIDs: \(gameData.daemonIDs.sorted().joined(separator: ", "))")
        print("  🎯 Custom VerbIDs: \(gameData.verbIDs.sorted().joined(separator: ", "))")
        print("  🎪 GameBlueprint Types: \(gameData.gameBlueprintTypes.sorted().joined(separator: ", "))")
        print("  🏠 Game Area Types: \(gameData.gameAreaTypes.sorted().joined(separator: ", "))")
        print("  🎭 Item Event Handlers: \(gameData.itemEventHandlers.sorted().joined(separator: ", "))")
        print("  🏟️  Location Event Handlers: \(gameData.locationEventHandlers.sorted().joined(separator: ", "))")
        print("  🎬 Custom Action Handlers: \(gameData.customActionHandlers.sorted().joined(separator: ", "))")
        print("  🧨 Fuse Definitions: \(gameData.fuseDefinitions.sorted().joined(separator: ", "))")
        print("  👿 Daemon Definitions: \(gameData.daemonDefinitions.sorted().joined(separator: ", "))")
        print("  📦 Item Properties: \(gameData.items.sorted().joined(separator: ", "))")
        print("  📍 Location Properties: \(gameData.locations.sorted().joined(separator: ", "))")
    }
}
