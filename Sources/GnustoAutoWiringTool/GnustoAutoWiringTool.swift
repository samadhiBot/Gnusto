import ArgumentParser
import Foundation

struct ConflictInfo {
    let id: String
    let type: String
    let files: [String]

    var description: String {
        let fileList = files.map { "    📁 \($0)" }.joined(separator: "\n")
        return """
            \(type): \(id)
            \(fileList)
            """
    }
}

enum AutoWiringError: Error {
    case duplicateIDs([ConflictInfo])
}

extension AutoWiringError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .duplicateIDs(let conflicts):
            let conflictDescriptions = conflicts.map { $0.description }.joined(separator: "\n\n")
            let totalCount = conflicts.count
            let idCount = conflicts.reduce(0) { $0 + $1.files.count }

            return """
                ❌ Found \(totalCount) duplicate ID conflicts affecting \(idCount) definitions:

                \(conflictDescriptions)

                Each ID must be unique across the entire game. Please rename the duplicates
                to resolve these conflicts.
                """
        }
    }
}

struct FileGameData {
    let gameData: GameData
    let fileName: String
}

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

        var fileGameDataList: [FileGameData] = []

        for sourceURL in sourceURLs {
            let scanner = Scanner(
                source: try String(contentsOf: sourceURL, encoding: .utf8)
            )
            let fileGameData = scanner.process()

            fileGameDataList.append(
                FileGameData(
                    gameData: fileGameData,
                    fileName: sourceURL.lastPathComponent
                ))

            print("📁 Processing: \(sourceURL.lastPathComponent)")
        }

        // Detect all conflicts across all files
        let conflicts = detectAllConflicts(fileGameDataList)

        // If conflicts found, report them all and fail
        if !conflicts.isEmpty {
            throw AutoWiringError.duplicateIDs(conflicts)
        }

        // No conflicts - safe to merge all data
        for fileData in fileGameDataList {
            allGameData = mergeGameDataUnsafe(allGameData, fileData.gameData)
        }

        // Print summary of discovered game data
        printGameDataSummary(allGameData)

        // Generate Swift code
        let codeGenerator = CodeGenerator()
        let generatedCode = codeGenerator.generate(from: allGameData)

        // Write generated code to output file
        let outputURL = URL(fileURLWithPath: output)
        try generatedCode.write(to: outputURL, atomically: true, encoding: .utf8)

        print("\n✅ Generated code written to: \(output)")
    }
}

// MARK: - Private helper methods

extension GnustoAutoWiringTool {
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
                !isTestFile(fileURL)  // Exclude test files
            else { continue }

            swiftFiles.append(fileURL)
        }

        return swiftFiles
    }

    private func isTestFile(_ fileURL: URL) -> Bool {
        let fileName = fileURL.lastPathComponent
        let pathComponents = fileURL.pathComponents

        // Exclude files ending with "Tests.swift"
        if fileName.hasSuffix("Tests.swift") {
            return true
        }

        // Exclude files in any "Tests" directory
        if pathComponents.contains("Tests") {
            return true
        }

        return false
    }

    private func detectAllConflicts(_ fileDataList: [FileGameData]) -> [ConflictInfo] {
        var allConflicts: [ConflictInfo] = []
        var idToFiles: [String: [String]] = [:]

        // Build comprehensive ID-to-files mapping
        for fileData in fileDataList {
            let fileName = fileData.fileName
            let gameData = fileData.gameData

            // Track all IDs from this file
            for id in gameData.locationIDs { addIDSource("LocationID:\(id)", fileName, &idToFiles) }
            for id in gameData.itemIDs { addIDSource("ItemID:\(id)", fileName, &idToFiles) }
            for id in gameData.globalIDs { addIDSource("GlobalID:\(id)", fileName, &idToFiles) }
            for id in gameData.fuseIDs { addIDSource("FuseID:\(id)", fileName, &idToFiles) }
            for id in gameData.daemonIDs { addIDSource("DaemonID:\(id)", fileName, &idToFiles) }
            for id in gameData.verbIDs { addIDSource("VerbID:\(id)", fileName, &idToFiles) }

            for id in gameData.itemEventHandlers {
                addIDSource("ItemEventHandler:\(id)", fileName, &idToFiles)
            }
            for id in gameData.locationEventHandlers {
                addIDSource("LocationEventHandler:\(id)", fileName, &idToFiles)
            }
            for id in gameData.itemComputeHandlers {
                addIDSource("ItemComputeHandler:\(id)", fileName, &idToFiles)
            }
            for id in gameData.locationComputeHandlers {
                addIDSource("LocationComputeHandler:\(id)", fileName, &idToFiles)
            }
            for id in gameData.gameBlueprintTypes {
                addIDSource("GameBlueprintType:\(id)", fileName, &idToFiles)
            }
            for id in gameData.gameAreaTypes {
                addIDSource("GameAreaType:\(id)", fileName, &idToFiles)
            }
            for id in gameData.customActionHandlers {
                addIDSource("CustomActionHandler:\(id)", fileName, &idToFiles)
            }
            for id in gameData.combatSystems {
                addIDSource("CombatSystem:\(id)", fileName, &idToFiles)
            }
            for id in gameData.combatMessengers {
                addIDSource("CombatMessenger:\(id)", fileName, &idToFiles)
            }
            for id in gameData.fuses { addIDSource("Fuse:\(id)", fileName, &idToFiles) }
            for id in gameData.daemons { addIDSource("Daemon:\(id)", fileName, &idToFiles) }
            for id in gameData.items { addIDSource("Item:\(id)", fileName, &idToFiles) }
            for id in gameData.locations { addIDSource("Location:\(id)", fileName, &idToFiles) }
        }

        // Find all conflicts (IDs appearing in multiple files)
        for (idWithType, files) in idToFiles {
            if files.count > 1 {
                let parts = idWithType.split(separator: ":", maxSplits: 1)
                let type = String(parts[0])
                let id = String(parts[1])

                allConflicts.append(
                    ConflictInfo(
                        id: id,
                        type: type,
                        files: files.sorted()
                    ))
            }
        }

        return allConflicts.sorted { $0.type < $1.type || ($0.type == $1.type && $0.id < $1.id) }
    }

    private func addIDSource(
        _ idWithType: String, _ fileName: String, _ idToFiles: inout [String: [String]]
    ) {
        if idToFiles[idWithType] == nil {
            idToFiles[idWithType] = []
        }
        idToFiles[idWithType]?.append(fileName)
    }

    private func mergeGameDataUnsafe(_ target: GameData, _ source: GameData) -> GameData {
        var merged = target

        merged.locationIDs.formUnion(source.locationIDs)
        merged.itemIDs.formUnion(source.itemIDs)
        merged.globalIDs.formUnion(source.globalIDs)
        merged.fuseIDs.formUnion(source.fuseIDs)
        merged.daemonIDs.formUnion(source.daemonIDs)
        merged.verbIDs.formUnion(source.verbIDs)

        merged.itemEventHandlers.formUnion(source.itemEventHandlers)
        merged.locationEventHandlers.formUnion(source.locationEventHandlers)
        merged.itemComputeHandlers.formUnion(source.itemComputeHandlers)
        merged.locationComputeHandlers.formUnion(source.locationComputeHandlers)
        merged.gameBlueprintTypes.formUnion(source.gameBlueprintTypes)
        merged.gameAreaTypes.formUnion(source.gameAreaTypes)
        merged.customActionHandlers.formUnion(source.customActionHandlers)
        merged.combatSystems.formUnion(source.combatSystems)
        merged.combatMessengers.formUnion(source.combatMessengers)
        merged.fuses.formUnion(source.fuses)
        merged.daemons.formUnion(source.daemons)

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
        print("  🎯 Custom Verbs: \(gameData.verbIDs.sorted().joined(separator: ", "))")
        print(
            "  🎪 GameBlueprint Types: \(gameData.gameBlueprintTypes.sorted().joined(separator: ", "))"
        )
        print("  🏠 Game Area Types: \(gameData.gameAreaTypes.sorted().joined(separator: ", "))")
        print(
            "  🎭 Item Event Handlers: \(gameData.itemEventHandlers.sorted().joined(separator: ", "))"
        )
        print(
            "  🏟️  Location Event Handlers: \(gameData.locationEventHandlers.sorted().joined(separator: ", "))"
        )
        print(
            "  🧮 Item Compute Handlers: \(gameData.itemComputeHandlers.sorted().joined(separator: ", "))"
        )
        print(
            "  🏗️  Location Compute Handlers: \(gameData.locationComputeHandlers.sorted().joined(separator: ", "))"
        )
        print(
            "  🎬 Custom Action Handlers: \(gameData.customActionHandlers.sorted().joined(separator: ", "))"
        )
        print("  ⚔️ Combat Systems: \(gameData.combatSystems.sorted().joined(separator: ", "))")
        print(
            "  📢 Combat Messengers: \(gameData.combatMessengers.sorted().joined(separator: ", "))")
        print("  🧨 Fuse Definitions: \(gameData.fuses.sorted().joined(separator: ", "))")
        print("  👿 Daemon Definitions: \(gameData.daemons.sorted().joined(separator: ", "))")
        print("  📦 Item Properties: \(gameData.items.sorted().joined(separator: ", "))")
        print("  📍 Location Properties: \(gameData.locations.sorted().joined(separator: ", "))")
    }
}
