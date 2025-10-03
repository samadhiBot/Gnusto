import ArgumentParser
import Foundation

struct ConflictLocation {
    let fileName: String
    let fullPath: String
    let lineNumber: Int
}

struct ConflictInfo {
    let id: String
    let type: String
    let locations: [ConflictLocation]

    var description: String {
        let fileList = locations.map { "    📁 \($0.fileName):\($0.lineNumber)" }.joined(
            separator: "\n")
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
            // Generate Xcode-compatible error format for each conflict
            var xcodeErrors: [String] = []

            for conflict in conflicts {
                let actionableMessage =
                    "Duplicate \(conflict.type) '\(conflict.id)' found in \(conflict.locations.count) files. Rename one of them to resolve conflict."

                // Add an error line for each location containing this duplicate
                for location in conflict.locations {
                    xcodeErrors.append(
                        "\(location.fullPath):\(location.lineNumber):1: error: \(actionableMessage)"
                    )
                }

                // Add a note with guidance
                let guidance =
                    "note: Search for 'id: .\(conflict.id)' in these files and rename duplicates to unique IDs"
                if let firstLocation = conflict.locations.first {
                    xcodeErrors.append(
                        "\(firstLocation.fullPath):\(firstLocation.lineNumber):1: \(guidance)")
                }
            }

            // Add actionable summary
            let totalCount = conflicts.count
            let idCount = conflicts.reduce(0) { $0 + $1.locations.count }
            xcodeErrors.append(
                "error: Build failed due to \(totalCount) duplicate ID conflicts affecting \(idCount) definitions. Each ID must be unique across the entire game."
            )
            xcodeErrors.append(
                "note: Fix duplicates by renaming IDs to unique values, e.g., change 'id: .chest' to 'id: .treasureChest' or 'id: .woodenChest'"
            )

            return xcodeErrors.joined(separator: "\n")
        }
    }
}

struct FileGameData {
    let gameData: GameData
    let fileName: String
    let fullPath: String
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
                source: try String(contentsOf: sourceURL, encoding: .utf8),
                fileName: sourceURL.lastPathComponent
            )
            let fileGameData = scanner.process()

            fileGameDataList.append(
                FileGameData(
                    gameData: fileGameData,
                    fileName: sourceURL.lastPathComponent,
                    fullPath: sourceURL.path
                ))

            // Process file silently - summary will be shown at end
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

        // Generate Swift code
        let codeGenerator = CodeGenerator()
        let generatedCode = codeGenerator.generate(from: allGameData)

        // Write generated code to output file
        let outputURL = URL(fileURLWithPath: output)
        try generatedCode.write(to: outputURL, atomically: true, encoding: .utf8)

        // Print success summary
        let fileCount = fileGameDataList.count
        let totalIDs =
            allGameData.locationIDs.keys.count + allGameData.itemIDs.keys.count
            + allGameData.globalIDs.keys.count
            + allGameData.fuseIDs.keys.count + allGameData.daemonIDs.keys.count
            + allGameData.verbIDs.keys.count

        print(
            "✅ Successfully processed \(fileCount) files and generated \(totalIDs) ID definitions")
        print("📝 Output written to: \(output)")
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
        var idToLocations: [String: [ConflictLocation]] = [:]

        // Build comprehensive ID-to-files mapping (avoiding duplicates)
        for fileData in fileDataList {
            let fileName = fileData.fileName
            let fullPath = fileData.fullPath
            let gameData = fileData.gameData

            // Track main ID types with actual source locations
            for (id, location) in gameData.locationIDs {
                addIDLocation(
                    "Location:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }
            for (id, location) in gameData.itemIDs {
                addIDLocation("Item:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }
            for (id, location) in gameData.globalIDs {
                addIDLocation(
                    "GlobalID:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }
            for (id, location) in gameData.fuseIDs {
                addIDLocation("Fuse:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }
            for (id, location) in gameData.daemonIDs {
                addIDLocation(
                    "Daemon:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }
            for (id, location) in gameData.verbIDs {
                addIDLocation("Verb:\(id)", fileName, fullPath, location.lineNumber, &idToLocations)
            }

            for id in gameData.itemEventHandlers {
                addIDLocation("ItemEventHandler:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.locationEventHandlers {
                addIDLocation("LocationEventHandler:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.itemComputeHandlers {
                addIDLocation("ItemComputeHandler:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.locationComputeHandlers {
                addIDLocation("LocationComputeHandler:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.gameBlueprintTypes {
                addIDLocation("GameBlueprint:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.gameAreaTypes {
                addIDLocation("GameArea:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.customActionHandlers {
                addIDLocation("ActionHandler:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.combatSystems {
                addIDLocation("CombatSystem:\(id)", fileName, fullPath, 1, &idToLocations)
            }
            for id in gameData.combatMessengers {
                addIDLocation("CombatMessenger:\(id)", fileName, fullPath, 1, &idToLocations)
            }
        }

        // Find all conflicts (IDs appearing in multiple locations)
        for (idWithType, locations) in idToLocations {
            if locations.count > 1 {
                let parts = idWithType.split(separator: ":", maxSplits: 1)
                let type = String(parts[0])
                let id = String(parts[1])

                allConflicts.append(
                    ConflictInfo(
                        id: id,
                        type: type,
                        locations: locations.sorted { $0.fullPath < $1.fullPath }
                    ))
            }
        }

        return allConflicts.sorted { $0.type < $1.type || ($0.type == $1.type && $0.id < $1.id) }
    }

    private func addIDLocation(
        _ idWithType: String, _ fileName: String, _ fullPath: String, _ lineNumber: Int,
        _ idToLocations: inout [String: [ConflictLocation]]
    ) {
        if idToLocations[idWithType] == nil {
            idToLocations[idWithType] = []
        }
        let location = ConflictLocation(
            fileName: fileName,
            fullPath: fullPath,
            lineNumber: lineNumber
        )
        idToLocations[idWithType]?.append(location)
    }

    private func mergeGameDataUnsafe(_ target: GameData, _ source: GameData) -> GameData {
        var merged = target

        merged.locationIDs.merge(source.locationIDs) { _, new in new }
        merged.itemIDs.merge(source.itemIDs) { _, new in new }
        merged.globalIDs.merge(source.globalIDs) { _, new in new }
        merged.fuseIDs.merge(source.fuseIDs) { _, new in new }
        merged.daemonIDs.merge(source.daemonIDs) { _, new in new }
        merged.verbIDs.merge(source.verbIDs) { _, new in new }

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
        print("  📍 LocationIDs: \(gameData.locationIDs.keys.sorted().joined(separator: ", "))")
        print("  📦 ItemIDs: \(gameData.itemIDs.keys.sorted().joined(separator: ", "))")
        print("  🌐 GlobalIDs: \(gameData.globalIDs.keys.sorted().joined(separator: ", "))")
        print("  🧨 FuseIDs: \(gameData.fuseIDs.keys.sorted().joined(separator: ", "))")
        print("  👿 DaemonIDs: \(gameData.daemonIDs.keys.sorted().joined(separator: ", "))")
        print("  🎯 Custom Verbs: \(gameData.verbIDs.keys.sorted().joined(separator: ", "))")
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
