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
    print("Usage: FrobozzMagicIDTool --output <path> --source-files <file1> <file2> ...")
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
print("  - \(discoveredData.areaBlueprintTypes.count) AreaBlueprint Types: \(discoveredData.areaBlueprintTypes.sorted().joined(separator: ", "))")
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
    let areaBlueprintTypes: Set<String>
    let items: Set<String>  // Property names
    let locations: Set<String>  // Property names
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
    var areaBlueprintTypes = Set<String>()
    var items = Set<String>()
    var locations = Set<String>()
    
    // Track existing constants to avoid duplicates
    var existingLocationIDs = Set<String>()
    var existingItemIDs = Set<String>()
    var existingGlobalIDs = Set<String>()
    var existingFuseIDs = Set<String>()
    var existingDaemonIDs = Set<String>()
    var existingVerbIDs = Set<String>()
    
    for filePath in filePaths {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        
        // MARK: - Scan for existing static constants
        
        let existingLocationMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*LocationID/)
        for match in existingLocationMatches {
            existingLocationIDs.insert(String(match.1))
        }
        
        let existingItemMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*ItemID/)
        for match in existingItemMatches {
            existingItemIDs.insert(String(match.1))
        }
        
        let existingGlobalMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*GlobalID/)
        for match in existingGlobalMatches {
            existingGlobalIDs.insert(String(match.1))
        }
        
        let existingFuseMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*FuseID/)
        for match in existingFuseMatches {
            existingFuseIDs.insert(String(match.1))
        }
        
        let existingDaemonMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*DaemonID/)
        for match in existingDaemonMatches {
            existingDaemonIDs.insert(String(match.1))
        }
        
        let existingVerbMatches = content.matches(of: /static\s+let\s+(\w+)\s*=\s*VerbID/)
        for match in existingVerbMatches {
            existingVerbIDs.insert(String(match.1))
        }
        
        // MARK: - Discover Blueprint Types
        
        // struct SomeName: GameBlueprint patterns
        let gameBlueprintMatches = content.matches(of: /(?:struct|class)\s+(\w+)\s*:\s*.*?GameBlueprint/)
        for match in gameBlueprintMatches {
            let typeName = String(match.1)
            gameBlueprintTypes.insert(typeName)
        }
        
        // struct SomeName: AreaBlueprint patterns
        let areaBlueprintMatches = content.matches(of: /(?:struct|class)\s+(\w+)\s*:\s*.*?AreaBlueprint/)
        for match in areaBlueprintMatches {
            let typeName = String(match.1)
            areaBlueprintTypes.insert(typeName)
        }
        
        // MARK: - Discover Item and Location Properties
        
        // let someName = Item( patterns
        let itemPropertyMatches = content.matches(of: /let\s+(\w+)\s*=\s*Item\s*\(/)
        for match in itemPropertyMatches {
            let propertyName = String(match.1)
            items.insert(propertyName)
        }
        
        // let someName = Location( patterns
        let locationPropertyMatches = content.matches(of: /let\s+(\w+)\s*=\s*Location\s*\(/)
        for match in locationPropertyMatches {
            let propertyName = String(match.1)
            locations.insert(propertyName)
        }
        
        // MARK: - Discover Dynamic Attribute Registrations
        
        // registerItemCompute(itemID: .someID, attributeID: .someAttr) or ("someID", "someAttr")
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
        
        // FuseDefinition(id: .someID, ...) patterns
        let fuseDefMatches = content.matches(of: /FuseDefinition\s*\(\s*id:\s*\.(\w+)/)
        for match in fuseDefMatches {
            let identifier = String(match.1)
            if !existingFuseIDs.contains(identifier) {
                fuseIDs.insert(identifier)
            }
        }
        
        // FuseDefinition(id: "someString", ...) patterns
        let fuseDefStringMatches = content.matches(of: /FuseDefinition\s*\(\s*id:\s*"(\w+)"/)
        for match in fuseDefStringMatches {
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
        
        // DaemonDefinition(id: .someID, ...) patterns
        let daemonDefMatches = content.matches(of: /DaemonDefinition\s*\(\s*id:\s*\.(\w+)/)
        for match in daemonDefMatches {
            let identifier = String(match.1)
            if !existingDaemonIDs.contains(identifier) {
                daemonIDs.insert(identifier)
            }
        }
        
        // DaemonDefinition(id: "someString", ...) patterns
        let daemonDefStringMatches = content.matches(of: /DaemonDefinition\s*\(\s*id:\s*"(\w+)"/)
        for match in daemonDefStringMatches {
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
        
        // MARK: - Discover Event Handlers
        
        // Look for ItemEventHandler variables following naming convention
        let itemHandlerMatches = content.matches(of: /let\s+(\w+)Handler\s*=\s*ItemEventHandler/)
        for match in itemHandlerMatches {
            let handlerName = String(match.1)
            itemEventHandlers.insert(handlerName)
        }
        
        // Look for LocationEventHandler variables following naming convention
        let locationHandlerMatches = content.matches(of: /let\s+(\w+)Handler\s*=\s*LocationEventHandler/)
        for match in locationHandlerMatches {
            let handlerName = String(match.1)
            locationEventHandlers.insert(handlerName)
        }
        
        // MARK: - Discover Custom Action Handlers
        
        // let someActionHandler = SomeActionHandler() patterns
        let actionHandlerMatches = content.matches(of: /let\s+(\w+)ActionHandler\s*=/)
        for match in actionHandlerMatches {
            let handlerName = String(match.1)
            customActionHandlers.insert(handlerName)
        }
        
        // MARK: - Discover Fuse and Daemon Definitions
        
        // let someDefinition = FuseDefinition( patterns
        let fuseDefVarMatches = content.matches(of: /let\s+(\w+)(?:Fuse|FuseDef|FuseDefinition)?\s*=\s*FuseDefinition/)
        for match in fuseDefVarMatches {
            let defName = String(match.1)
            fuseDefinitions.insert(defName)
        }
        
        // let someDefinition = DaemonDefinition( patterns
        let daemonDefVarMatches = content.matches(of: /let\s+(\w+)(?:Daemon|DaemonDef|DaemonDefinition)?\s*=\s*DaemonDefinition/)
        for match in daemonDefVarMatches {
            let defName = String(match.1)
            daemonDefinitions.insert(defName)
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
        areaBlueprintTypes: areaBlueprintTypes,
        items: items,
        locations: locations
    )
}

// MARK: - Code Generation

func generateExtensions(_ discoveredData: DiscoveredGameData) -> String {
    var output = [
        "// Generated by FrobozzMagicIDPlugin",
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
    
    // Generate GameBlueprint Extensions (The Big Innovation!)
    
    for gameBlueprintType in discoveredData.gameBlueprintTypes.sorted() {
        var hasExtensionContent = false
        var extensionOutput: [String] = []
        
        // Generate itemEventHandlers property
        if !discoveredData.itemEventHandlers.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var itemEventHandlers: [ItemID: ItemEventHandler] {")
            extensionOutput.append("        [")
            let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
            for handlerName in sortedItemHandlers {
                extensionOutput.append("            .\(handlerName): \(handlerName)Handler,")
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
                extensionOutput.append("            .\(handlerName): \(handlerName)Handler,")
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }
        
        // Generate customActionHandlers property
        if !discoveredData.customActionHandlers.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var customActionHandlers: [VerbID: ActionHandler] {")
            extensionOutput.append("        [")
            let sortedActionHandlers = discoveredData.customActionHandlers.sorted()
            for handlerName in sortedActionHandlers {
                // Try to derive the verb from the handler name
                let verbName = handlerName.lowercased()
                extensionOutput.append("            .\(verbName): \(handlerName)ActionHandler,")
            }
            extensionOutput.append("        ]")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }
        
        // Generate timeRegistry property
        if !discoveredData.fuseDefinitions.isEmpty || !discoveredData.daemonDefinitions.isEmpty {
            hasExtensionContent = true
            extensionOutput.append("    var timeRegistry: TimeRegistry {")
            extensionOutput.append("        TimeRegistry(")
            
            if !discoveredData.fuseDefinitions.isEmpty {
                extensionOutput.append("            fuseDefinitions: [")
                let sortedFuseDefinitions = discoveredData.fuseDefinitions.sorted()
                for fuseDef in sortedFuseDefinitions {
                    // Handle common naming patterns
                    extensionOutput.append("                \(fuseDef),")
                }
                extensionOutput.append("            ],")
            }
            
            if !discoveredData.daemonDefinitions.isEmpty {
                extensionOutput.append("            daemonDefinitions: [")
                let sortedDaemonDefinitions = discoveredData.daemonDefinitions.sorted()
                for daemonDef in sortedDaemonDefinitions {
                    extensionOutput.append("                \(daemonDef),")
                }
                extensionOutput.append("            ]")
            }
            
            extensionOutput.append("        )")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }
        
        // Generate dynamicAttributeRegistry property
        let hasDynamicAttributes = !discoveredData.dynamicItemCompute.isEmpty ||
                                  !discoveredData.dynamicItemValidate.isEmpty ||
                                  !discoveredData.dynamicLocationCompute.isEmpty ||
                                  !discoveredData.dynamicLocationValidate.isEmpty
        
        if hasDynamicAttributes {
            hasExtensionContent = true
            extensionOutput.append("    var dynamicAttributeRegistry: DynamicAttributeRegistry {")
            extensionOutput.append("        var registry = DynamicAttributeRegistry()")
            extensionOutput.append("")
            
            // Generate item compute registrations
            for registration in discoveredData.dynamicItemCompute.sorted(by: { $0.entityID < $1.entityID }) {
                extensionOutput.append("        registry.registerItemCompute(itemID: .\(registration.entityID), attributeID: .\(registration.attributeID)) { item, gameState in")
                extensionOutput.append("            // TODO: Implement \(registration.entityID).\(registration.attributeID) compute logic")
                extensionOutput.append("            return .undefined")
                extensionOutput.append("        }")
                extensionOutput.append("")
            }
            
            // Generate item validate registrations
            for registration in discoveredData.dynamicItemValidate.sorted(by: { $0.entityID < $1.entityID }) {
                extensionOutput.append("        registry.registerItemValidate(itemID: .\(registration.entityID), attributeID: .\(registration.attributeID)) { item, newValue in")
                extensionOutput.append("            // TODO: Implement \(registration.entityID).\(registration.attributeID) validation logic")
                extensionOutput.append("            return true")
                extensionOutput.append("        }")
                extensionOutput.append("")
            }
            
            // Generate location compute registrations
            for registration in discoveredData.dynamicLocationCompute.sorted(by: { $0.entityID < $1.entityID }) {
                extensionOutput.append("        registry.registerLocationCompute(locationID: .\(registration.entityID), attributeID: .\(registration.attributeID)) { location, gameState in")
                extensionOutput.append("            // TODO: Implement \(registration.entityID).\(registration.attributeID) compute logic")
                extensionOutput.append("            return .undefined")
                extensionOutput.append("        }")
                extensionOutput.append("")
            }
            
            // Generate location validate registrations
            for registration in discoveredData.dynamicLocationValidate.sorted(by: { $0.entityID < $1.entityID }) {
                extensionOutput.append("        registry.registerLocationValidate(locationID: .\(registration.entityID), attributeID: .\(registration.attributeID)) { location, newValue in")
                extensionOutput.append("            // TODO: Implement \(registration.entityID).\(registration.attributeID) validation logic")
                extensionOutput.append("            return true")
                extensionOutput.append("        }")
                extensionOutput.append("")
            }
            
            extensionOutput.append("        return registry")
            extensionOutput.append("    }")
            extensionOutput.append("")
        }
        
        // Only generate the extension if there's content
        if hasExtensionContent {
            output.append("// MARK: - \(gameBlueprintType) Auto-Generated Extensions")
            output.append("//")
            output.append("// 🚀 Reflection-free GameBlueprint extensions!")
            output.append("// These properties are auto-discovered and wired up at compile time.")
            output.append("")
            output.append("extension \(gameBlueprintType) {")
            output.append(contentsOf: extensionOutput)
            output.append("}")
            output.append("")
        }
    }
    
    // Generate AreaBlueprint Extensions (Even Bigger Innovation!)
    
    for areaBlueprintType in discoveredData.areaBlueprintTypes.sorted() {
        var hasAreaExtensionContent = false
        var areaExtensionOutput: [String] = []
        
        // Generate reflection-free items property
        if !discoveredData.items.isEmpty {
            hasAreaExtensionContent = true
            areaExtensionOutput.append("    static var items: [Item] {")
            areaExtensionOutput.append("        [")
            let sortedItems = discoveredData.items.sorted()
            for itemProperty in sortedItems {
                areaExtensionOutput.append("            \(areaBlueprintType)().\(itemProperty),")
            }
            areaExtensionOutput.append("        ]")
            areaExtensionOutput.append("    }")
            areaExtensionOutput.append("")
        }
        
        // Generate reflection-free locations property
        if !discoveredData.locations.isEmpty {
            hasAreaExtensionContent = true
            areaExtensionOutput.append("    static var locations: [Location] {")
            areaExtensionOutput.append("        [")
            let sortedLocations = discoveredData.locations.sorted()
            for locationProperty in sortedLocations {
                areaExtensionOutput.append("            \(areaBlueprintType)().\(locationProperty),")
            }
            areaExtensionOutput.append("        ]")
            areaExtensionOutput.append("    }")
            areaExtensionOutput.append("")
        }
        
        // Generate reflection-free itemEventHandlers property
        if !discoveredData.itemEventHandlers.isEmpty {
            hasAreaExtensionContent = true
            areaExtensionOutput.append("    static var itemEventHandlers: [ItemID: ItemEventHandler] {")
            areaExtensionOutput.append("        [")
            let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
            for handlerName in sortedItemHandlers {
                areaExtensionOutput.append("            .\(handlerName): \(areaBlueprintType)().\(handlerName)Handler,")
            }
            areaExtensionOutput.append("        ]")
            areaExtensionOutput.append("    }")
            areaExtensionOutput.append("")
        }
        
        // Generate reflection-free locationEventHandlers property
        if !discoveredData.locationEventHandlers.isEmpty {
            hasAreaExtensionContent = true
            areaExtensionOutput.append("    static var locationEventHandlers: [LocationID: LocationEventHandler] {")
            areaExtensionOutput.append("        [")
            let sortedLocationHandlers = discoveredData.locationEventHandlers.sorted()
            for handlerName in sortedLocationHandlers {
                areaExtensionOutput.append("            .\(handlerName): \(areaBlueprintType)().\(handlerName)Handler,")
            }
            areaExtensionOutput.append("        ]")
            areaExtensionOutput.append("    }")
            areaExtensionOutput.append("")
        }
        
        // Only generate the extension if there's content
        if hasAreaExtensionContent {
            output.append("// MARK: - \(areaBlueprintType) Reflection-Free Extensions")
            output.append("//")
            output.append("// 🎉 No more Mirror reflection! These properties are auto-generated")
            output.append("// at compile time, eliminating all runtime reflection overhead.")
            output.append("")
            output.append("extension \(areaBlueprintType) {")
            output.append(contentsOf: areaExtensionOutput)
            output.append("}")
            output.append("")
        }
    }
    
    // Generate Discovery Comments (now less important but still helpful)
    
    if hasEventHandlers && discoveredData.gameBlueprintTypes.isEmpty {
        output.append("// MARK: - Event Handler Discovery")
        output.append("//")
        output.append("// Event handlers were discovered but no GameBlueprint types were found.")
        output.append("// Consider adding a GameBlueprint-conforming type to enable auto-wiring:")
        output.append("")
        
        if !discoveredData.itemEventHandlers.isEmpty {
            output.append("// Item Event Handlers found:")
            let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
            for handlerName in sortedItemHandlers {
                output.append("// - \(handlerName)Handler → ItemID.\(handlerName)")
            }
            output.append("")
        }
        
        if !discoveredData.locationEventHandlers.isEmpty {
            output.append("// Location Event Handlers found:")
            let sortedLocationHandlers = discoveredData.locationEventHandlers.sorted()
            for handlerName in sortedLocationHandlers {
                output.append("// - \(handlerName)Handler → LocationID.\(handlerName)")
            }
            output.append("")
        }
    }
    
    // Generate helpful setup templates and reminders
    
    if hasNewContent && discoveredData.gameBlueprintTypes.isEmpty {
        output.append("// MARK: - Setup Guidance")
        output.append("//")
        output.append("// No GameBlueprint types were discovered. Consider creating one:")
        output.append("//")
        output.append("// struct YourGame: GameBlueprint {")
        output.append("//     let constants = GameConstants(...)")
        output.append("//     var state = GameState(...)")
        output.append("//     // Other properties will be auto-generated!")
        output.append("// }")
        output.append("")
        
        if !discoveredData.globalIDs.isEmpty {
            output.append("// 🏁 Initialize global state in your GameBlueprint:")
            output.append("// var state = GameState(")
            output.append("//     areas: YourArea.self,")
            output.append("//     player: Player(in: .startingLocation),")
            output.append("//     globalState: [")
            let sortedGlobalIDs = discoveredData.globalIDs.sorted()
            for globalID in sortedGlobalIDs {
                output.append("//         .\(globalID): <initial_value>,")
            }
            output.append("//     ]")
            output.append("// )")
            output.append("//")
        }
    }
    
    if !discoveredData.gameBlueprintTypes.isEmpty || !discoveredData.areaBlueprintTypes.isEmpty {
        output.append("// 🎉 CONGRATULATIONS! This plugin has eliminated ALL reflection from your game!")
        output.append("//")
        output.append("// ✅ All ID constants are auto-generated")
        output.append("// ✅ All event handlers are auto-wired") 
        output.append("// ✅ All custom action handlers are auto-registered")
        output.append("// ✅ All time definitions are auto-configured")
        output.append("// ✅ All dynamic attribute handlers are auto-registered")
        output.append("// ✅ AreaBlueprint no longer uses Mirror reflection")
        output.append("// ✅ GameBlueprint properties are fully automated")
        output.append("//")
        output.append("// Your game now builds faster, runs faster, and is more maintainable!")
        output.append("// Just follow naming conventions and the plugin handles the rest.")
        output.append("")
    } else {
        output.append("// 💡 Pro tip: Create GameBlueprint and/or AreaBlueprint types")
        output.append("//    to unlock the plugin's full reflection-elimination capabilities!")
        output.append("")
    }
    
    return output.joined(separator: "\n")
} 
