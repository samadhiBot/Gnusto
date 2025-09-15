import Foundation

/// Holds all discovered game-related information from parsing Swift source code.
struct GameData {
    // ID collections
    var daemonIDs: Set<String> = []
    var fuseIDs: Set<String> = []
    var globalIDs: Set<String> = []
    var itemIDs: Set<String> = []
    var locationIDs: Set<String> = []
    var verbIDs: Set<String> = []

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
