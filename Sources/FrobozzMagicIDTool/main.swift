import Foundation

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
    }
    
    return DiscoveredGameData(
        locationIDs: locationIDs,
        itemIDs: itemIDs,
        globalIDs: globalIDs,
        fuseIDs: fuseIDs,
        daemonIDs: daemonIDs,
        verbIDs: verbIDs,
        itemEventHandlers: itemEventHandlers,
        locationEventHandlers: locationEventHandlers
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
    
    if !hasNewContent && !hasEventHandlers {
        output.append("// No new ID constants or event handlers need to be generated.")
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
    
    // Generate Event Handler Registry
    
    if hasEventHandlers {
        output.append("// MARK: - Discovered Event Handlers")
        output.append("//")
        output.append("// The following event handlers were discovered and may need to be")
        output.append("// registered in your GameBlueprint's itemEventHandlers and")
        output.append("// locationEventHandlers dictionaries:")
        output.append("")
        
        if !discoveredData.itemEventHandlers.isEmpty {
            output.append("// Item Event Handlers:")
            let sortedItemHandlers = discoveredData.itemEventHandlers.sorted()
            for handlerName in sortedItemHandlers {
                output.append("// - \(handlerName)Handler → ItemID.\(handlerName)")
            }
            output.append("")
        }
        
        if !discoveredData.locationEventHandlers.isEmpty {
            output.append("// Location Event Handlers:")
            let sortedLocationHandlers = discoveredData.locationEventHandlers.sorted()
            for handlerName in sortedLocationHandlers {
                output.append("// - \(handlerName)Handler → LocationID.\(handlerName)")
            }
            output.append("")
        }
        
        output.append("// Example registration in your GameBlueprint:")
        output.append("// var itemEventHandlers: [ItemID: ItemEventHandler] {")
        output.append("//     AreaBlueprint.itemEventHandlers")
        output.append("// }")
        output.append("//")
        output.append("// var locationEventHandlers: [LocationID: LocationEventHandler] {")
        output.append("//     AreaBlueprint.locationEventHandlers") 
        output.append("// }")
        output.append("")
    }
    
    // Generate helpful setup templates and reminders
    
    if hasNewContent || hasEventHandlers {
        output.append("// MARK: - Game Setup Reminders")
        output.append("//")
        output.append("// Don't forget to wire up these patterns in your game setup:")
        output.append("//")
        
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
        
        if !discoveredData.fuseIDs.isEmpty || !discoveredData.daemonIDs.isEmpty {
            output.append("// ⏰ Register time definitions in your GameBlueprint:")
            output.append("// var timeRegistry: TimeRegistry {")
            output.append("//     TimeRegistry(")
            if !discoveredData.fuseIDs.isEmpty {
                output.append("//         fuseDefinitions: [")
                let sortedFuseIDs = discoveredData.fuseIDs.sorted()
                for fuseID in sortedFuseIDs {
                    output.append("//             FuseDefinition(id: .\(fuseID), initialTurns: <turns>) { engine in")
                    output.append("//                 // TODO: Implement \(fuseID) behavior")
                    output.append("//             },")
                }
                output.append("//         ],")
            }
            if !discoveredData.daemonIDs.isEmpty {
                output.append("//         daemonDefinitions: [")
                let sortedDaemonIDs = discoveredData.daemonIDs.sorted()
                for daemonID in sortedDaemonIDs {
                    output.append("//             DaemonDefinition(id: .\(daemonID)) { engine in")
                    output.append("//                 // TODO: Implement \(daemonID) behavior")
                    output.append("//             },")
                }
                output.append("//         ]")
            }
            output.append("//     )")
            output.append("// }")
            output.append("//")
        }
        
        if !discoveredData.verbIDs.isEmpty {
            output.append("// 🎯 Create custom action handlers in your GameBlueprint:")
            output.append("// var customActionHandlers: [VerbID: ActionHandler] {")
            output.append("//     [")
            let sortedVerbIDs = discoveredData.verbIDs.sorted()
            for verbID in sortedVerbIDs {
                output.append("//         .\(verbID): YourCustom\(verbID.capitalized)ActionHandler(),")
            }
            output.append("//     ]")
            output.append("// }")
            output.append("//")
        }
        
        output.append("// 💡 Pro tip: Use the AreaBlueprint pattern to automatically discover")
        output.append("//    event handlers via reflection-based naming conventions!")
        output.append("")
    }
    
    return output.joined(separator: "\n")
} 
