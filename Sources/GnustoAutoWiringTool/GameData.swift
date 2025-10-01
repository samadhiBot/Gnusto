import Foundation

/// Represents a source location for tracking where IDs are defined
struct SourceLocation {
    let fileName: String
    let lineNumber: Int
}

/// Data structure that holds all discovered game patterns from scanning Swift source files.
struct GameData {
    // Core ID sets with source locations
    var locationIDs: [String: SourceLocation] = [:]
    var itemIDs: [String: SourceLocation] = [:]
    var globalIDs: [String: SourceLocation] = [:]
    var fuseIDs: [String: SourceLocation] = [:]
    var daemonIDs: [String: SourceLocation] = [:]
    var verbIDs: [String: SourceLocation] = [:]

    // Type collections
    var combatMessengers: Set<String> = []
    var combatSystems: Set<String> = []
    var customActionHandlers: Set<String> = []
    var daemons: Set<String> = []
    var fuses: Set<String> = []
    var gameAreaTypes: Set<String> = []
    var gameBlueprintTypes: Set<String> = []
    var itemComputeHandlers: Set<String> = []
    var itemEventHandlers: Set<String> = []
    var locationComputeHandlers: Set<String> = []
    var locationEventHandlers: Set<String> = []

    // Item and location property collections
    var items: Set<String> = []
    var locations: Set<String> = []

    // Mapping collections
    var handlerToAreaMap: [String: String] = [:]
    var itemToAreaMap: [String: String] = [:]
    var locationToAreaMap: [String: String] = [:]
    var propertyIsStatic: [String: Bool] = [:]
}
