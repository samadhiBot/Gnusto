/*

import Foundation

// MARK: - Helper Types

struct AttributeRegistration: Hashable {
    let entityID: String
    let attributeID: String

    init(_ entityID: String, _ attributeID: String) {
        self.entityID = entityID
        self.attributeID = attributeID
    }
}

// Parse command line arguments
let arguments = CommandLine.arguments

guard arguments.count >= 4,
      arguments[1] == "--output",
      arguments.contains("--source-files") else {
    print("Usage: GnustoAutoWiringTool --output <path> --source-files <file1> <file2> ...")
    exit(1)
}

let outputPath = arguments[2]
let sourceFileStartIndex = arguments.firstIndex(of: "--source-files")! + 1
let sourceFiles = Array(arguments[sourceFileStartIndex...])

print("🔍 Scanning \(sourceFiles.count) source files for game patterns...")

// Convert file URLs to file paths if needed
let resolvedSourceFiles: [String] = sourceFiles.compactMap { filePath in
    let path = if filePath.hasPrefix("file://") {
        URL(string: filePath)?.path ?? filePath
    } else {
        filePath
    }

    // Skip test files that contain example code snippets (not real game areas)
    let filename = URL(fileURLWithPath: path).lastPathComponent
    if filename.hasSuffix("Tests.swift") {
        print("⏭️  Skipping test file: \(filename)")
        return nil
    }

    return path
}

let resolvedOutputPath = {
    if outputPath.hasPrefix("file://") {
        return URL(string: outputPath)?.path ?? outputPath
    }
    return outputPath
}()

// Scan source files
let discoveredData = try scanSourceFiles(resolvedSourceFiles)

print("📝 Discovered:")
print("  - \(discoveredData.locationIDs.count) LocationIDs: \(discoveredData.locationIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.itemIDs.count) ItemIDs: \(discoveredData.itemIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.globalIDs.count) GlobalIDs: \(discoveredData.globalIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.fuseIDs.count) FuseIDs: \(discoveredData.fuseIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.daemonIDs.count) DaemonIDs: \(discoveredData.daemonIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.verbIDs.count) Custom VerbIDs: \(discoveredData.verbIDs.sorted().joined(separator: ", "))")
print("  - \(discoveredData.itemEventHandlers.count) Item Event Handlers: \(discoveredData.itemEventHandlers.sorted().joined(separator: ", "))")
print("  - \(discoveredData.locationEventHandlers.count) Location Event Handlers: \(discoveredData.locationEventHandlers.sorted().joined(separator: ", "))")
print("  - \(discoveredData.gameBlueprintTypes.count) GameBlueprint Types: \(discoveredData.gameBlueprintTypes.sorted().joined(separator: ", "))")
print("  - \(discoveredData.gameAreaTypes.count) Game Area Types: \(discoveredData.gameAreaTypes.sorted().joined(separator: ", "))")
print("  - \(discoveredData.customActionHandlers.count) Custom Action Handlers: \(discoveredData.customActionHandlers.sorted().joined(separator: ", "))")
print("  - \(discoveredData.fuseDefinitions.count) Fuse Definitions: \(discoveredData.fuseDefinitions.sorted().joined(separator: ", "))")
print("  - \(discoveredData.daemonDefinitions.count) Daemon Definitions: \(discoveredData.daemonDefinitions.sorted().joined(separator: ", "))")
print("  - \(discoveredData.dynamicItemCompute.count) Dynamic Item Compute: \(discoveredData.dynamicItemCompute.map { "\($0.entityID).\($0.attributeID)" }.sorted().joined(separator: ", "))")
print("  - \(discoveredData.dynamicItemValidate.count) Dynamic Item Validate: \(discoveredData.dynamicItemValidate.map { "\($0.entityID).\($0.attributeID)" }.sorted().joined(separator: ", "))")
print("  - \(discoveredData.dynamicLocationCompute.count) Dynamic Location Compute: \(discoveredData.dynamicLocationCompute.map { "\($0.entityID).\($0.attributeID)" }.sorted().joined(separator: ", "))")
print("  - \(discoveredData.dynamicLocationValidate.count) Dynamic Location Validate: \(discoveredData.dynamicLocationValidate.map { "\($0.entityID).\($0.attributeID)" }.sorted().joined(separator: ", "))")
print("  - \(discoveredData.items.count) Item Properties: \(discoveredData.items.sorted().joined(separator: ", "))")
print("  - \(discoveredData.locations.count) Location Properties: \(discoveredData.locations.sorted().joined(separator: ", "))")

// Generate code
let generatedCode = generateExtensions(discoveredData)

// Write output
try generatedCode.write(toFile: resolvedOutputPath, atomically: true, encoding: .utf8)

print("✅ Generated comprehensive game setup code written to: \(resolvedOutputPath)")

// MARK: - Discovery

struct DiscoveredGameData {
    let locationIDs: Set<String>
    let itemIDs: Set<String>
    let globalIDs: Set<String>
    let fuseIDs: Set<String>
    let daemonIDs: Set<String>
    let verbIDs: Set<String>
    let itemEventHandlers: Set<String>
    let locationEventHandlers: Set<String>
    let gameBlueprintTypes: Set<String>
    let customActionHandlers: Set<String>
    let fuseDefinitions: Set<String>
    let daemonDefinitions: Set<String>
    let dynamicItemCompute: Set<AttributeRegistration>
    let dynamicItemValidate: Set<AttributeRegistration>
    let dynamicLocationCompute: Set<AttributeRegistration>
    let dynamicLocationValidate: Set<AttributeRegistration>
    let gameAreaTypes: Set<String>
    let items: Set<String>
    let locations: Set<String>

    // MARK: - Per-Entity Static Property Tracking

    /// Maps individual property names to whether they are static
    let propertyIsStatic: [String: Bool]

    // MARK: - Handler-to-Area Mappings (Scope Resolution)

    /// Maps handler names to the game area type that defines them
    let handlerToAreaMap: [String: String]

    /// Maps fuse definition names to the game area type that defines them
    let fuseToAreaMap: [String: String]

    /// Maps daemon definition names to the game area type that defines them
    let daemonToAreaMap: [String: String]

    // MARK: - Property-to-Area Mappings

    /// Maps item property names to the game area type that defines them
    let itemToAreaMap: [String: String]

    /// Maps location property names to the game area type that defines them
    let locationToAreaMap: [String: String]
}

func scanSourceFiles(_ filePaths: [String]) throws -> DiscoveredGameData {
    var locationIDs = Set<String>()
    var itemIDs = Set<String>()
    var globalIDs = Set<String>()
    var fuseIDs = Set<String>()
    var daemonIDs = Set<String>()
    var verbIDs = Set<String>()
    var itemEventHandlers = Set<String>()
    var locationEventHandlers = Set<String>()
    var gameBlueprintTypes = Set<String>()
    var customActionHandlers = Set<String>()
    var fuseDefinitions = Set<String>()
    var daemonDefinitions = Set<String>()
    var dynamicItemCompute = Set<AttributeRegistration>()
    var dynamicItemValidate = Set<AttributeRegistration>()
    var dynamicLocationCompute = Set<AttributeRegistration>()
    var dynamicLocationValidate = Set<AttributeRegistration>()
    var gameAreaTypes = Set<String>()
    var items = Set<String>()
    var locations = Set<String>()

    // MARK: - Per-Entity Static Property Tracking
    var propertyIsStatic: [String: Bool] = [:]

    // MARK: - Handler-to-Area Mappings (Scope Resolution)
    var handlerToAreaMap: [String: String] = [:]
    var fuseToAreaMap: [String: String] = [:]
    var daemonToAreaMap: [String: String] = [:]

    // MARK: - Property-to-Area Mappings
    var itemToAreaMap: [String: String] = [:]
    var locationToAreaMap: [String: String] = [:]

    // Track existing constants to avoid duplicates
    var existingLocationIDs = Set<String>()
    var existingItemIDs = Set<String>()
    var existingGlobalIDs = Set<String>()
    var existingFuseIDs = Set<String>()
    var existingDaemonIDs = Set<String>()
    var existingVerbIDs = Set<String>()

    for filePath in filePaths {
        let content = try String(contentsOfFile: filePath, encoding: String.Encoding.utf8)

        // MARK: - Discover Game Area Types (Pure Detection)

        // Find any struct/class/enum that contains Location or Item declarations (simplified detection)
        let typeDeclarationMatches = content.matches(of: /(?:struct|class|enum)\s+(\w+)/)
        var currentFileGameAreas: [String] = []

        for match in typeDeclarationMatches {
            let typeName = String(match.1)

            // Check if this type contains game content by looking for Location/Item patterns
            let typePattern = try! Regex("\(typeName)[^}]*(?:Location\\s*\\(|Item\\s*\\(|LocationEventHandler|ItemEventHandler)")
            if content.contains(typePattern) {
                gameAreaTypes.insert(typeName)  // Add to the accumulating set
                currentFileGameAreas.append(typeName)
            }
        }

        // Use the first game area in this file as the "owner" for handlers found in this file
        let fileAreaOwner = currentFileGameAreas.first

        // MARK: - Discover Blueprint Types

        // struct/class/enum SomeName: GameBlueprint patterns
        let gameBlueprintMatches = content.matches(of: /(?:struct|class|enum)\s+(\w+)\s*:\s*.*?GameBlueprint/)
        for match in gameBlueprintMatches {
            let typeName = String(match.1)
            gameBlueprintTypes.insert(typeName)
        }

        // MARK: - Discover Item and Location Properties with Per-Entity Static Tracking

        // For each game area in this file, find the properties it contains
        for areaType in currentFileGameAreas {
            // Create a pattern to match the area's content block - using string regex for interpolation
            let areaPatternString = "(?:enum|struct|class)\\s+\(areaType)\\s*\\{([^}]*(?:\\{[^}]*\\}[^}]*)*?)\\}"
            let areaPattern = try! Regex(areaPatternString)

            if let areaMatch = content.firstMatch(of: areaPattern) {
                // Extract the content inside the area's braces (capture group 1)
                let fullMatch = areaMatch.output
                guard fullMatch.count > 1, let range = fullMatch[1].range else { continue }
                let areaContent = String(content[range])

                // Find location properties within this area, tracking static vs instance per property
                let locationPropertyPattern = /(static\s+)?(let|var)\s+(\w+)(?:\s*:\s*Location)?\s*=\s*(?:Location\s*\(|\.init\s*\()/
                let locationPropertyMatches = areaContent.matches(of: locationPropertyPattern)
                for match in locationPropertyMatches {
                    let isStatic = match.1 != nil
                    let propertyName = String(match.3)
                    locations.insert(propertyName)
                    locationToAreaMap[propertyName] = areaType
                    propertyIsStatic[propertyName] = isStatic
                }

                // Find item properties within this area, tracking static vs instance per property
                let itemPropertyPattern = /(static\s+)?(let|var)\s+(\w+)(?:\s*:\s*Item)?\s*=\s*(?:Item\s*\(|\.init\s*\()/
                let itemPropertyMatches = areaContent.matches(of: itemPropertyPattern)
                for match in itemPropertyMatches {
                    let isStatic = match.1 != nil
                    let propertyName = String(match.3)
                    items.insert(propertyName)
                    itemToAreaMap[propertyName] = areaType
                    propertyIsStatic[propertyName] = isStatic
                }

                // Find event handlers within this area, tracking static vs instance per handler
                let itemEventHandlerPattern = /(static\s+)?(let|var)\s+(\w+)Handler\s*=\s*ItemEventHandler/
                let itemHandlerMatches = areaContent.matches(of: itemEventHandlerPattern)
                for match in itemHandlerMatches {
                    let isStatic = match.1 != nil
                    let handlerName = String(match.3)
                    itemEventHandlers.insert(handlerName)
                    handlerToAreaMap[handlerName] = areaType
                    propertyIsStatic[handlerName] = isStatic
                }

                let locationEventHandlerPattern = /(static\s+)?(let|var)\s+(\w+)Handler\s*=\s*LocationEventHandler/
                let locationHandlerMatches = areaContent.matches(of: locationEventHandlerPattern)
                for match in locationHandlerMatches {
                    let isStatic = match.1 != nil
                    let handlerName = String(match.3)
                    locationEventHandlers.insert(handlerName)
                    handlerToAreaMap[handlerName] = areaType
                    propertyIsStatic[handlerName] = isStatic
                }

                // Find fuse and daemon definitions within this area
                let fuseDefPattern = /(static\s+)?(let|var)\s+(\w+)(?:Fuse|FuseDef|FuseDefinition)?\s*=\s*FuseDefinition/
                let fuseMatches = areaContent.matches(of: fuseDefPattern)
                for match in fuseMatches {
                    let isStatic = match.1 != nil
                    let defName = String(match.3)
                    fuseDefinitions.insert(defName)
                    fuseToAreaMap[defName] = areaType
                    propertyIsStatic[defName] = isStatic
                }

                let daemonDefPattern = /(static\s+)?(let|var)\s+(\w+)(?:Daemon|DaemonDef|DaemonDefinition)?\s*=\s*DaemonDefinition/
                let daemonMatches = areaContent.matches(of: daemonDefPattern)
                for match in daemonMatches {
                    let isStatic = match.1 != nil
                    let defName = String(match.3)
                    daemonDefinitions.insert(defName)
                    daemonToAreaMap[defName] = areaType
                    propertyIsStatic[defName] = isStatic
                }
            }
        }

        // MARK: - Scan for existing static constants

        let existingLocationMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*LocationID/.anchorsMatchLineEndings())
        for match in existingLocationMatches {
            existingLocationIDs.insert(String(match.1))
        }

        let existingItemMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*ItemID/.anchorsMatchLineEndings())
        for match in existingItemMatches {
            existingItemIDs.insert(String(match.1))
        }

        let existingGlobalMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*GlobalID/.anchorsMatchLineEndings())
        for match in existingGlobalMatches {
            existingGlobalIDs.insert(String(match.1))
        }

        let existingFuseMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*FuseID/.anchorsMatchLineEndings())
        for match in existingFuseMatches {
            existingFuseIDs.insert(String(match.1))
        }

        let existingDaemonMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*DaemonID/.anchorsMatchLineEndings())
        for match in existingDaemonMatches {
            existingDaemonIDs.insert(String(match.1))
        }

        let existingVerbMatches = content.matches(of: /^(?!\s*\/\/).*static\s+let\s+(\w+)\s*=\s*VerbID/.anchorsMatchLineEndings())
        for match in existingVerbMatches {
            existingVerbIDs.insert(String(match.1))
        }

        // MARK: - Discover LocationIDs

        // Location(id: .someID, ...)
        let locationUsageMatches = content.matches(of: /Location\s*\(\s*id:\s*\.(\w+)/)
        for match in locationUsageMatches {
            let identifier = String(match.1)
            if !existingLocationIDs.contains(identifier) {
                locationIDs.insert(identifier)
            }
        }

        // .to(.someID) patterns in exits
        let exitToMatches = content.matches(of: /\.to\s*\(\s*\.(\w+)\s*\)/)
        for match in exitToMatches {
            let identifier = String(match.1)
            if !existingLocationIDs.contains(identifier) {
                locationIDs.insert(identifier)
            }
        }

        // .location(.someID) patterns in parent entity
        let locationParentMatches = content.matches(of: /\.location\s*\(\s*\.(\w+)\s*\)/)
        for match in locationParentMatches {
            let identifier = String(match.1)
            if !existingLocationIDs.contains(identifier) {
                locationIDs.insert(identifier)
            }
        }

        // Player(in: .someID) patterns
        let playerInMatches = content.matches(of: /Player\s*\(\s*in:\s*\.(\w+)\s*\)/)
        for match in playerInMatches {
            let identifier = String(match.1)
            if !existingLocationIDs.contains(identifier) {
                locationIDs.insert(identifier)
            }
        }

        // MARK: - Discover ItemIDs

        // Item(id: .someID, ...)
        let itemUsageMatches = content.matches(of: /Item\s*\(\s*id:\s*\.(\w+)/)
        for match in itemUsageMatches {
            let identifier = String(match.1)
            if !existingItemIDs.contains(identifier) {
                itemIDs.insert(identifier)
            }
        }

        // .item(.someID) patterns in parent entity
        let itemParentMatches = content.matches(of: /\.item\s*\(\s*\.(\w+)\s*\)/)
        for match in itemParentMatches {
            let identifier = String(match.1)
            if !existingItemIDs.contains(identifier) {
                itemIDs.insert(identifier)
            }
        }

        // MARK: - Discover GlobalIDs

        // GlobalID("someString") patterns
        let globalIDMatches = content.matches(of: /GlobalID\s*\(\s*"(\w+)"\s*\)/)
        for match in globalIDMatches {
            let identifier = String(match.1)
            if !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // .someID: value patterns in globalState dictionaries - improved pattern
        let globalStateMatches = content.matches(of: /\.(\w+):\s*[^,}\]]+/)
        for match in globalStateMatches {
            let identifier = String(match.1)
            // Only consider this a GlobalID if it's in a context that suggests globalState usage
            if content.contains("globalState") && !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // globalState: [ patterns with specific syntax
        let globalStateDictMatches = content.matches(of: /globalState:\s*\[\s*\.(\w+):/)
        for match in globalStateDictMatches {
            let identifier = String(match.1)
            if !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // global("someID") or global(.someID) patterns - improved
        let globalCallMatches = content.matches(of: /global\s*\(\s*["\.](\w+)["\)]/)
        for match in globalCallMatches {
            let identifier = String(match.1)
            if !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // setFlag(.someID) and clearFlag(.someID) patterns
        let setFlagMatches = content.matches(of: /(?:setFlag|clearFlag)\s*\(\s*\.(\w+)\s*\)/)
        for match in setFlagMatches {
            let identifier = String(match.1)
            if !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // adjustGlobal(.someID, by:) patterns
        let adjustGlobalMatches = content.matches(of: /adjustGlobal\s*\(\s*\.(\w+)\s*,/)
        for match in adjustGlobalMatches {
            let identifier = String(match.1)
            if !existingGlobalIDs.contains(identifier) {
                globalIDs.insert(identifier)
            }
        }

        // MARK: - Discover FuseIDs

        // FuseID("someString") patterns
        let fuseIDMatches = content.matches(of: /FuseID\s*\(\s*"(\w+)"\s*\)/)
        for match in fuseIDMatches {
            let identifier = String(match.1)
            if !existingFuseIDs.contains(identifier) {
                fuseIDs.insert(identifier)
            }
        }

        // MARK: - Discover DaemonIDs

        // DaemonID("someString") patterns
        let daemonIDMatches = content.matches(of: /DaemonID\s*\(\s*"(\w+)"\s*\)/)
        for match in daemonIDMatches {
            let identifier = String(match.1)
            if !existingDaemonIDs.contains(identifier) {
                daemonIDs.insert(identifier)
            }
        }

        // MARK: - Discover Custom VerbIDs

        // VerbID("someString") patterns for custom verbs
        let verbIDMatches = content.matches(of: /VerbID\s*\(\s*"(\w+)"\s*\)/)
        for match in verbIDMatches {
            let identifier = String(match.1)
            // Filter out standard verbs that are already defined in the engine
            let standardVerbs = ["close", "drop", "examine", "give", "go", "insert", "inventory", "listen", "lock", "look", "open", "push", "putOn", "read", "remove", "smell", "take", "taste", "thinkAbout", "touch", "turnOff", "turnOn", "unlock", "wear", "xyzzy", "brief", "help", "quit", "restore", "save", "score", "verbose", "wait", "debug"]
            if !standardVerbs.contains(identifier) && !existingVerbIDs.contains(identifier) {
                verbIDs.insert(identifier)
            }
        }

        // MARK: - Discover Custom Action Handlers

        // let someActionHandler = SomeActionHandler() patterns
        let actionHandlerMatches = content.matches(of: /let\s+(\w+)ActionHandler\s*=/)
        for match in actionHandlerMatches {
            let handlerName = String(match.1)
            customActionHandlers.insert(handlerName)
        }

        // MARK: - Discover Fuse and Daemon Definitions (with area tracking)

        // let someDefinition = FuseDefinition( patterns
        let fuseDefVarMatches = content.matches(of: /let\s+(\w+)(?:Fuse|FuseDef|FuseDefinition)?\s*=\s*FuseDefinition/)
        for match in fuseDefVarMatches {
            let defName = String(match.1)
            fuseDefinitions.insert(defName)

            // Associate fuse with its containing area
            if let areaOwner = fileAreaOwner {
                fuseToAreaMap[defName] = areaOwner
            }
        }

        // let someDefinition = DaemonDefinition( patterns
        let daemonDefVarMatches = content.matches(of: /let\s+(\w+)(?:Daemon|DaemonDef|DaemonDefinition)?\s*=\s*DaemonDefinition/)
        for match in daemonDefVarMatches {
            let defName = String(match.1)
            daemonDefinitions.insert(defName)

            // Associate daemon with its containing area
            if let areaOwner = fileAreaOwner {
                daemonToAreaMap[defName] = areaOwner
            }
        }

        // MARK: - Discover Dynamic Attribute Registrations

        // registerItemCompute(itemID: .someID, attribute: .someAttr) or ("someID", "someAttr")
        let itemComputeMatches = content.matches(of: /registerItemCompute\s*\(\s*itemID:\s*["\.](\w+)["\)],\s*attributeID:\s*["\.](\w+)["\)]/)
        for match in itemComputeMatches {
            let itemID = String(match.1)
            let attributeID = String(match.2)
            dynamicItemCompute.insert(AttributeRegistration(itemID, attributeID))
        }

        // registerItemValidate patterns
        let itemValidateMatches = content.matches(of: /registerItemValidate\s*\(\s*itemID:\s*["\.](\w+)["\)],\s*attributeID:\s*["\.](\w+)["\)]/)
        for match in itemValidateMatches {
            let itemID = String(match.1)
            let attributeID = String(match.2)
            dynamicItemValidate.insert(AttributeRegistration(itemID, attributeID))
        }

        // registerLocationCompute patterns
        let locationComputeMatches = content.matches(of: /registerLocationCompute\s*\(\s*locationID:\s*["\.](\w+)["\)],\s*attributeID:\s*["\.](\w+)["\)]/)
        for match in locationComputeMatches {
            let locationID = String(match.1)
            let attributeID = String(match.2)
            dynamicLocationCompute.insert(AttributeRegistration(locationID, attributeID))
        }

        // registerLocationValidate patterns
        let locationValidateMatches = content.matches(of: /registerLocationValidate\s*\(\s*locationID:\s*["\.](\w+)["\)],\s*attributeID:\s*["\.](\w+)["\)]/)
        for match in locationValidateMatches {
            let locationID = String(match.1)
            let attributeID = String(match.2)
            dynamicLocationValidate.insert(AttributeRegistration(locationID, attributeID))
        }
    }

    return DiscoveredGameData(
        locationIDs: locationIDs,
        itemIDs: itemIDs,
        globalIDs: globalIDs,
        fuseIDs: fuseIDs,
        daemonIDs: daemonIDs,
        verbIDs: verbIDs,
        itemEventHandlers: itemEventHandlers,
        locationEventHandlers: locationEventHandlers,
        gameBlueprintTypes: gameBlueprintTypes,
        customActionHandlers: customActionHandlers,
        fuseDefinitions: fuseDefinitions,
        daemonDefinitions: daemonDefinitions,
        dynamicItemCompute: dynamicItemCompute,
        dynamicItemValidate: dynamicItemValidate,
        dynamicLocationCompute: dynamicLocationCompute,
        dynamicLocationValidate: dynamicLocationValidate,
        gameAreaTypes: gameAreaTypes,
        items: items,
        locations: locations,
        propertyIsStatic: propertyIsStatic,
        handlerToAreaMap: handlerToAreaMap,
        fuseToAreaMap: fuseToAreaMap,
        daemonToAreaMap: daemonToAreaMap,
        itemToAreaMap: itemToAreaMap,
        locationToAreaMap: locationToAreaMap
    )
}

// MARK: - Code Generation

func generateExtensions(_ discoveredData: DiscoveredGameData) -> String {
    var output = [
        "// Generated by GnustoAutoWiringPlugin",
        "// Do not edit this file manually",
        "",
        "import GnustoEngine",
        ""
    ]

    // Check if there's anything to generate
    let hasNewContent = !discoveredData.locationIDs.isEmpty ||
                       !discoveredData.itemIDs.isEmpty ||
                       !discoveredData.globalIDs.isEmpty ||
                       !discoveredData.fuseIDs.isEmpty ||
                       !discoveredData.daemonIDs.isEmpty ||
                       !discoveredData.verbIDs.isEmpty

    let hasEventHandlers = !discoveredData.itemEventHandlers.isEmpty ||
                          !discoveredData.locationEventHandlers.isEmpty

    let hasGameLogic = !discoveredData.customActionHandlers.isEmpty ||
                      !discoveredData.fuseDefinitions.isEmpty ||
                      !discoveredData.daemonDefinitions.isEmpty

    if !hasNewContent && !hasEventHandlers && !hasGameLogic {
        output.append("// No new ID constants, event handlers, or game logic need to be generated.")
        output.append("// All discovered patterns are already manually defined.")
        output.append("")
        return output.joined(separator: "\n")
    }

    // Generate ID Extensions

    if !discoveredData.locationIDs.isEmpty {
        output.append("extension LocationID {")
        let sortedLocationIDs = discoveredData.locationIDs.sorted()
        for locationID in sortedLocationIDs {
            output.append("    static let \(locationID) = LocationID(\"\(locationID)\")")
        }
        output.append("}")
        output.append("")
    }

    if !discoveredData.itemIDs.isEmpty {
        output.append("extension ItemID {")
        let sortedItemIDs = discoveredData.itemIDs.sorted()
        for itemID in sortedItemIDs {
            output.append("    static let \(itemID) = ItemID(\"\(itemID)\")")
        }
        output.append("}")
        output.append("")
    }

    if !discoveredData.globalIDs.isEmpty {
        output.append("extension GlobalID {")
        let sortedGlobalIDs = discoveredData.globalIDs.sorted()
        for globalID in sortedGlobalIDs {
            output.append("    static let \(globalID) = GlobalID(\"\(globalID)\")")
        }
        output.append("}")
        output.append("")
    }

    if !discoveredData.fuseIDs.isEmpty {
        output.append("extension FuseID {")
        let sortedFuseIDs = discoveredData.fuseIDs.sorted()
        for fuseID in sortedFuseIDs {
            output.append("    static let \(fuseID) = FuseID(\"\(fuseID)\")")
        }
        output.append("}")
        output.append("")
    }

    if !discoveredData.daemonIDs.isEmpty {
        output.append("extension DaemonID {")
        let sortedDaemonIDs = discoveredData.daemonIDs.sorted()
        for daemonID in sortedDaemonIDs {
            output.append("    static let \(daemonID) = DaemonID(\"\(daemonID)\")")
        }
        output.append("}")
        output.append("")
    }

    if !discoveredData.verbIDs.isEmpty {
        output.append("extension VerbID {")
        let sortedVerbIDs = discoveredData.verbIDs.sorted()
        for verbID in sortedVerbIDs {
            output.append("    static let \(verbID) = VerbID(\"\(verbID)\")")
        }
        output.append("}")
        output.append("")
    }

    // Generate GameBlueprint extensions
    for gameBlueprintType in discoveredData.gameBlueprintTypes {
        var extensionOutput: [String] = []
        var hasExtensionContent = false

        // Note: No need for static instances when using enum-based areas with static properties

        // Generate static instances for struct-based game areas (performance optimization)
        let areasNeedingInstances = discoveredData.gameAreaTypes.filter { gameAreaType in
            // Check if this area has any non-static properties that need instances
            let hasNonStaticItems = discoveredData.items.contains { item in
                discoveredData.itemToAreaMap[item] == gameAreaType &&
                !(discoveredData.propertyIsStatic[item] ?? false)
            }
            let hasNonStaticLocations = discoveredData.locations.contains { location in
                discoveredData.locationToAreaMap[location] == gameAreaType &&
                !(discoveredData.propertyIsStatic[location] ?? false)
            }
            let hasNonStaticHandlers = discoveredData.itemEventHandlers.contains { handler in
                discoveredData.handlerToAreaMap[handler] == gameAreaType &&
                !(discoveredData.propertyIsStatic[handler] ?? false)
            } || discoveredData.locationEventHandlers.contains { handler in
                discoveredData.handlerToAreaMap[handler] == gameAreaType &&
                !(discoveredData.propertyIsStatic[handler] ?? false)
            }
            let hasNonStaticFuses = discoveredData.fuseDefinitions.contains { fuse in
                discoveredData.fuseToAreaMap[fuse] == gameAreaType &&
                !(discoveredData.propertyIsStatic[fuse] ?? false)
            }
            let hasNonStaticDaemons = discoveredData.daemonDefinitions.contains { daemon in
                discoveredData.daemonToAreaMap[daemon] == gameAreaType &&
                !(discoveredData.propertyIsStatic[daemon] ?? false)
            }

            return hasNonStaticItems || hasNonStaticLocations || hasNonStaticHandlers ||
                   hasNonStaticFuses || hasNonStaticDaemons
        }

        if !areasNeedingInstances.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    // MARK: - Static Area Instances (Performance Optimization)")
            extensionOutput.append("")
            for gameAreaType in areasNeedingInstances.sorted() {
                let instanceName = "_\(gameAreaType.prefix(1).lowercased())\(gameAreaType.dropFirst())"
                extensionOutput.append("    private static let \(instanceName) = \(gameAreaType)()")
            }
            extensionOutput.append("")
        }

        // Generate aggregated items property
        if !discoveredData.items.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var items: [Item] {")
            extensionOutput.append("        [")

            for itemProperty in discoveredData.items.sorted() {
                // Use proper scope-aware mapping
                if let areaType = discoveredData.itemToAreaMap[itemProperty] {
                    let usesStaticProperties = discoveredData.propertyIsStatic[itemProperty] ?? false
                    if usesStaticProperties {
                        extensionOutput.append("            \(areaType).\(itemProperty),")
                    } else {
                        let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                        extensionOutput.append("            Self.\(instanceName).\(itemProperty),")
                    }
                } else {
                    // Fallback: try the first area
                    let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                    extensionOutput.append("            \(areaType).\(itemProperty), // ⚠️ Area mapping unknown, using first area")
                }
            }

            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate aggregated locations property
        if !discoveredData.locations.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var locations: [Location] {")
            extensionOutput.append("        [")

            for locationProperty in discoveredData.locations.sorted() {
                // Use proper scope-aware mapping
                if let areaType = discoveredData.locationToAreaMap[locationProperty] {
                    let usesStaticProperties = discoveredData.propertyIsStatic[locationProperty] ?? false
                    if usesStaticProperties {
                        extensionOutput.append("            \(areaType).\(locationProperty),")
                    } else {
                        let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                        extensionOutput.append("            Self.\(instanceName).\(locationProperty),")
                    }
                } else {
                    // Fallback: try the first area
                    let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                    extensionOutput.append("            \(areaType).\(locationProperty), // ⚠️ Area mapping unknown, using first area")
                }
            }

            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate itemEventHandlers property
        // TODO: Event handler mapping needs manual configuration - handler names don't directly map to ItemIDs
        // if !discoveredData.itemEventHandlers.isEmpty {
        //     hasExtensionContent = true
        //     extensionOutput.append("    var itemEventHandlers: [ItemID: ItemEventHandler] {")
        //     extensionOutput.append("        [")
        //     let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
        //     for handlerName in sortedItemHandlers {
        //         // Find which area contains this handler and use appropriate access pattern
        //         if let areaType = discoveredData.handlerToAreaMap[handlerName] {
        //             let usesStaticProperties = discoveredData.propertyIsStatic[handlerName] ?? false
        //             if usesStaticProperties {
        //                 extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler,")
        //             } else {
        //                 let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
        //                 extensionOutput.append("            .\(handlerName): Self.\(instanceName).\(handlerName)Handler,")
        //             }
        //         } else {
        //             // Fallback: try the first area
        //             let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
        //             extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler, // ⚠️ Area mapping unknown, using first area")
        //         }
        //     }
        //     extensionOutput.append("        ]")
        //     extensionOutput.append("    }")
        //     extensionOutput.append("")
        // }

        // Generate locationEventHandlers property
        // TODO: Event handler mapping needs manual configuration - handler names don't directly map to LocationIDs
        // if !discoveredData.locationEventHandlers.isEmpty {
        //     hasExtensionContent = true
        //     extensionOutput.append("    var locationEventHandlers: [LocationID: LocationEventHandler] {")
        //     extensionOutput.append("        [")
        //     let sortedLocationHandlers = discoveredData.locationEventHandlers.sorted()
        //     for handlerName in sortedLocationHandlers {
        //         // Find which area contains this handler and use appropriate access pattern
        //         if let areaType = discoveredData.handlerToAreaMap[handlerName] {
        //             let usesStaticProperties = discoveredData.propertyIsStatic[handlerName] ?? false
        //             if usesStaticProperties {
        //                 extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler,")
        //             } else {
        //                 let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
        //                 extensionOutput.append("            .\(handlerName): Self.\(instanceName).\(handlerName)Handler,")
        //             }
        //         } else {
        //             // Fallback: try the first area
        //             let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
        //             extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler, // ⚠️ Area mapping unknown, using first area")
        //         }
        //     }
        //     extensionOutput.append("        ]")
        //     extensionOutput.append("    }")
        //     extensionOutput.append("")
        // }

        // Generate fuseDefinitions property
        // TODO: Fuse definition mapping needs to be fixed - area mapping is not working correctly
        // if !discoveredData.fuseDefinitions.isEmpty {
        //     hasExtensionContent = true
        //     extensionOutput.append("    var fuseDefinitions: [FuseID: FuseDefinition] {")
        //     extensionOutput.append("        [")

        //     let sortedFuses = discoveredData.fuseDefinitions.sorted()
        //     for fuseProperty in sortedFuses {
        //         // Use proper scope-aware mapping
        //         if let areaType = discoveredData.fuseToAreaMap[fuseProperty] {
        //             let usesStaticProperties = discoveredData.propertyIsStatic[fuseProperty] ?? false
        //             if usesStaticProperties {
        //                 extensionOutput.append("            \(areaType).\(fuseProperty).id: \(areaType).\(fuseProperty),")
        //             } else {
        //                 let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
        //                 extensionOutput.append("            Self.\(instanceName).\(fuseProperty).id: Self.\(instanceName).\(fuseProperty),")
        //             }
        //         } else {
        //             // Fallback: try the first area
        //             let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
        //             extensionOutput.append("            \(areaType).\(fuseProperty).id: \(areaType).\(fuseProperty), // ⚠️ Area mapping unknown, using first area")
        //         }
        //     }

        //     extensionOutput.append("        ]")
        //     extensionOutput.append("    }")
        //     extensionOutput.append("")
        // }

        // Generate daemonDefinitions property
        // TODO: Daemon definition mapping needs to be fixed - area mapping is not working correctly
        // if !discoveredData.daemonDefinitions.isEmpty {
        //     hasExtensionContent = true
        //     extensionOutput.append("    var daemonDefinitions: [DaemonID: DaemonDefinition] {")
        //     extensionOutput.append("        [")

        //     let sortedDaemons = discoveredData.daemonDefinitions.sorted()
        //     for daemonProperty in sortedDaemons {
        //         // Use proper scope-aware mapping
        //         if let areaType = discoveredData.daemonToAreaMap[daemonProperty] {
        //             let usesStaticProperties = discoveredData.propertyIsStatic[daemonProperty] ?? false
        //             if usesStaticProperties {
        //                 extensionOutput.append("            \(areaType).\(daemonProperty).id: \(areaType).\(daemonProperty),")
        //             } else {
        //                 let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
        //                 extensionOutput.append("            Self.\(instanceName).\(daemonProperty).id: Self.\(instanceName).\(daemonProperty),")
        //             }
        //         } else {
        //             // Fallback: try the first area
        //             let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
        //             extensionOutput.append("            \(areaType).\(daemonProperty).id: \(areaType).\(daemonProperty), // ⚠️ Area mapping unknown, using first area")
        //         }
        //     }

        //     extensionOutput.append("        ]")
        //     extensionOutput.append("    }")
        //     extensionOutput.append("")
        // }

        // Only generate the extension if there's content
        if hasExtensionContent {
            output.append("// MARK: - \(gameBlueprintType) Aggregated Game Data Extensions")
            output.append("//")
            output.append("// 🎉 Complete game data aggregated from all areas!")
            output.append("// All items, locations, and handlers across all areas are provided here.")
            output.append("")
            output.append("extension \(gameBlueprintType) {")
            output.append(contentsOf: extensionOutput)
            output.append("}")
            output.append("")
        }
    }

    return output.joined(separator: "\n")
}
*/
