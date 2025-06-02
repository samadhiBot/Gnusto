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
let resolvedSourceFiles = sourceFiles.map { filePath in
    if filePath.hasPrefix("file://") {
        return URL(string: filePath)?.path ?? filePath
    }
    return filePath
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
    let gameAreaTypes: Set<String>  // Renamed from areaBlueprintTypes
    let items: Set<String>  // Property names
    let locations: Set<String>  // Property names

    // MARK: - Static vs Instance Property Detection

    /// Maps game area type names to whether they use static properties (true = static, false = instance)
    let gameAreaUsesStaticProperties: [String: Bool]

    // MARK: - Handler-to-Area Mappings (Scope Resolution)

    /// Maps handler names to the game area type that defines them
    let handlerToAreaMap: [String: String]

    /// Maps fuse definition names to the game area type that defines them
    let fuseToAreaMap: [String: String]

    /// Maps daemon definition names to the game area type that defines them
    let daemonToAreaMap: [String: String]
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

    // MARK: - Static vs Instance Property Detection
    var gameAreaUsesStaticProperties: [String: Bool] = [:]

    // MARK: - Handler-to-Area Mappings (Scope Resolution)
    var handlerToAreaMap: [String: String] = [:]
    var fuseToAreaMap: [String: String] = [:]
    var daemonToAreaMap: [String: String] = [:]

    // Track existing constants to avoid duplicates
    var existingLocationIDs = Set<String>()
    var existingItemIDs = Set<String>()
    var existingGlobalIDs = Set<String>()
    var existingFuseIDs = Set<String>()
    var existingDaemonIDs = Set<String>()
    var existingVerbIDs = Set<String>()

    for filePath in filePaths {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)

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

                // Detect if this game area uses static properties
                let staticPattern = try! Regex("static\\s+let\\s+\\w+\\s*=\\s*(?:Location|Item)\\s*\\(")
                let hasStaticProperties = content.contains(staticPattern)
                gameAreaUsesStaticProperties[typeName] = hasStaticProperties
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

        // MARK: - Discover Item and Location Properties (Multiple Patterns)

        // Enhanced pattern matching for: let/var name = Location/Item( and let/var name: Type = Location/Item(
        let locationPropertyPattern = /(?:static\s+)?(?:let|var)\s+(\w+)(?:\s*:\s*Location)?\s*=\s*(?:Location\s*\(|\.init\s*\()/
        let locationPropertyMatches = content.matches(of: locationPropertyPattern)
        for match in locationPropertyMatches {
            let propertyName = String(match.1)
            locations.insert(propertyName)
        }

        let itemPropertyPattern = /(?:static\s+)?(?:let|var)\s+(\w+)(?:\s*:\s*Item)?\s*=\s*(?:Item\s*\(|\.init\s*\()/
        let itemPropertyMatches = content.matches(of: itemPropertyPattern)
        for match in itemPropertyMatches {
            let propertyName = String(match.1)
            items.insert(propertyName)
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

        // customActionHandlers: [.someVerb: handler] patterns
        let customHandlerMatches = content.matches(of: /\.(\w+):\s*\w+ActionHandler/)
        for match in customHandlerMatches {
            let identifier = String(match.1)
            if !existingVerbIDs.contains(identifier) {
                verbIDs.insert(identifier)
            }
        }

        // MARK: - Discover Event Handlers (with area tracking)

        // Item Event Handlers: let someNameHandler = ItemEventHandler (instance)
        let itemEventHandlerMatches = content.matches(of: /let\s+(\w+)Handler\s*=\s*ItemEventHandler/)
        for match in itemEventHandlerMatches {
            let handlerName = String(match.1)
            itemEventHandlers.insert(handlerName)

            // Associate handler with its containing area
            if let areaOwner = fileAreaOwner {
                handlerToAreaMap[handlerName] = areaOwner
            }
        }

        // Item Event Handlers: static let someNameHandler = ItemEventHandler (static)
        let staticItemEventHandlerMatches = content.matches(of: /static\s+let\s+(\w+)Handler\s*=\s*ItemEventHandler/)
        for match in staticItemEventHandlerMatches {
            let handlerName = String(match.1)
            itemEventHandlers.insert(handlerName)

            // Associate handler with its containing area
            if let areaOwner = fileAreaOwner {
                handlerToAreaMap[handlerName] = areaOwner
            }
        }

        // Location Event Handlers: let someNameHandler = LocationEventHandler (instance)
        let locationEventHandlerMatches = content.matches(of: /let\s+(\w+)Handler\s*=\s*LocationEventHandler/)
        for match in locationEventHandlerMatches {
            let handlerName = String(match.1)
            locationEventHandlers.insert(handlerName)

            // Associate handler with its containing area
            if let areaOwner = fileAreaOwner {
                handlerToAreaMap[handlerName] = areaOwner
            }
        }

        // Location Event Handlers: static let someNameHandler = LocationEventHandler (static)
        let staticLocationEventHandlerMatches = content.matches(of: /static\s+let\s+(\w+)Handler\s*=\s*LocationEventHandler/)
        for match in staticLocationEventHandlerMatches {
            let handlerName = String(match.1)
            locationEventHandlers.insert(handlerName)

            // Associate handler with its containing area
            if let areaOwner = fileAreaOwner {
                handlerToAreaMap[handlerName] = areaOwner
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
        gameAreaUsesStaticProperties: gameAreaUsesStaticProperties,
        handlerToAreaMap: handlerToAreaMap,
        fuseToAreaMap: fuseToAreaMap,
        daemonToAreaMap: daemonToAreaMap
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
        let structBasedAreas = discoveredData.gameAreaTypes.filter { gameAreaType in
            !(discoveredData.gameAreaUsesStaticProperties[gameAreaType] ?? false)
        }

        if !structBasedAreas.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    // MARK: - Static Area Instances (Performance Optimization)")
            extensionOutput.append("")
            for gameAreaType in structBasedAreas.sorted() {
                let instanceName = "_\(gameAreaType.prefix(1).lowercased())\(gameAreaType.dropFirst())"
                extensionOutput.append("    private static let \(instanceName) = \(gameAreaType)()")
            }
            extensionOutput.append("")
        }

        // Generate timeRegistry property
        if !discoveredData.fuseDefinitions.isEmpty || !discoveredData.daemonDefinitions.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var timeRegistry: TimeRegistry {")
            extensionOutput.append("        let registry = TimeRegistry()")

            if !discoveredData.fuseDefinitions.isEmpty {
                extensionOutput.append("")
                extensionOutput.append("        // Auto-discovered Fuse Definitions")
                let sortedFuses = discoveredData.fuseDefinitions.sorted()
                for fuseProperty in sortedFuses {
                    // Use proper scope-aware mapping
                    if let areaType = discoveredData.fuseToAreaMap[fuseProperty] {
                        let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[areaType] ?? false
                        if usesStaticProperties {
                            extensionOutput.append("        registry.registerFuse(\(areaType).\(fuseProperty))")
                        } else {
                            let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                            extensionOutput.append("        registry.registerFuse(Self.\(instanceName).\(fuseProperty))")
                        }
                    } else {
                        // Fallback: try the first area
                        let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                        extensionOutput.append("        registry.registerFuse(\(areaType).\(fuseProperty)) // ⚠️ Area mapping unknown, using first area")
                    }
                }
            }

            if !discoveredData.daemonDefinitions.isEmpty {
                extensionOutput.append("")
                extensionOutput.append("        // Auto-discovered Daemon Definitions")
                let sortedDaemons = discoveredData.daemonDefinitions.sorted()
                for daemonProperty in sortedDaemons {
                    // Use proper scope-aware mapping
                    if let areaType = discoveredData.daemonToAreaMap[daemonProperty] {
                        let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[areaType] ?? false
                        if usesStaticProperties {
                            extensionOutput.append("        registry.registerDaemon(\(areaType).\(daemonProperty))")
                        } else {
                            let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                            extensionOutput.append("        registry.registerDaemon(Self.\(instanceName).\(daemonProperty))")
                        }
                    } else {
                        // Fallback: try the first area
                        let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                        extensionOutput.append("        registry.registerDaemon(\(areaType).\(daemonProperty)) // ⚠️ Area mapping unknown, using first area")
                    }
                }
            }

            extensionOutput.append("")
            extensionOutput.append("        return registry")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate aggregated items property
        if !discoveredData.gameAreaTypes.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var items: [Item] {")
            extensionOutput.append("        [")
            for gameAreaType in discoveredData.gameAreaTypes.sorted() {
                let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[gameAreaType] ?? false

                for itemProperty in discoveredData.items.sorted() {
                    if usesStaticProperties {
                        // For enums/types with static properties: DirectType.property
                        extensionOutput.append("            \(gameAreaType).\(itemProperty),")
                    } else {
                        // For structs with instance properties: create static instance
                        let instanceName = "_\(gameAreaType.prefix(1).lowercased())\(gameAreaType.dropFirst())"
                        extensionOutput.append("            Self.\(instanceName).\(itemProperty),")
                    }
                }
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate aggregated locations property
        if !discoveredData.gameAreaTypes.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var locations: [Location] {")
            extensionOutput.append("        [")
            for gameAreaType in discoveredData.gameAreaTypes.sorted() {
                let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[gameAreaType] ?? false

                for locationProperty in discoveredData.locations.sorted() {
                    if usesStaticProperties {
                        // For enums/types with static properties: DirectType.property
                        extensionOutput.append("            \(gameAreaType).\(locationProperty),")
                    } else {
                        // For structs with instance properties: create static instance
                        let instanceName = "_\(gameAreaType.prefix(1).lowercased())\(gameAreaType.dropFirst())"
                        extensionOutput.append("            Self.\(instanceName).\(locationProperty),")
                    }
                }
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate itemEventHandlers property
        if !discoveredData.itemEventHandlers.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var itemEventHandlers: [ItemID: ItemEventHandler] {")
            extensionOutput.append("        [")
            let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
            for handlerName in sortedItemHandlers {
                // Find which area contains this handler and use appropriate access pattern
                if let areaType = discoveredData.handlerToAreaMap[handlerName] {
                    let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[areaType] ?? false
                    if usesStaticProperties {
                        extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler,")
                    } else {
                        let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                        extensionOutput.append("            .\(handlerName): Self.\(instanceName).\(handlerName)Handler,")
                    }
                } else {
                    // Fallback: try the first area
                    let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                    extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler, // ⚠️ Area mapping unknown, using first area")
                }
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

        // Generate locationEventHandlers property
        if !discoveredData.locationEventHandlers.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var locationEventHandlers: [LocationID: LocationEventHandler] {")
            extensionOutput.append("        [")
            let sortedLocationHandlers = discoveredData.locationEventHandlers.sorted()
            for handlerName in sortedLocationHandlers {
                // Find which area contains this handler and use appropriate access pattern
                if let areaType = discoveredData.handlerToAreaMap[handlerName] {
                    let usesStaticProperties = discoveredData.gameAreaUsesStaticProperties[areaType] ?? false
                    if usesStaticProperties {
                        extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler,")
                    } else {
                        let instanceName = "_\(areaType.prefix(1).lowercased())\(areaType.dropFirst())"
                        extensionOutput.append("            .\(handlerName): Self.\(instanceName).\(handlerName)Handler,")
                    }
                } else {
                    // Fallback: try the first area
                    let areaType = discoveredData.gameAreaTypes.first ?? "/* Area type not found */"
                    extensionOutput.append("            .\(handlerName): \(areaType).\(handlerName)Handler, // ⚠️ Area mapping unknown, using first area")
                }
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }

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
