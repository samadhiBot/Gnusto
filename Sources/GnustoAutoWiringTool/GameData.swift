import Foundation

/// Holds all discovered game-related information from parsing Swift source code.
struct GameData {
    // ID collections
    var locationIDs: Set<String> = []
    var itemIDs: Set<String> = []
    var globalIDs: Set<String> = []
    var fuseIDs: Set<String> = []
    var daemonIDs: Set<String> = []
    var verbIDs: Set<String> = []

    // Type collections
    var gameBlueprintTypes: Set<String> = []
    var gameAreaTypes: Set<String> = []
    var itemEventHandlers: Set<String> = []
    var locationEventHandlers: Set<String> = []
    var itemComputeHandlers: Set<String> = []
    var locationComputeHandlers: Set<String> = []
    var customActionHandlers: Set<String> = []
    var fuses: Set<String> = []
    var daemons: Set<String> = []

    // Item and location property collections
    var items: Set<String> = []
    var locations: Set<String> = []

    // Mapping collections
    var itemToAreaMap: [String: String] = [:]
    var locationToAreaMap: [String: String] = [:]
    var handlerToAreaMap: [String: String] = [:]
    var propertyIsStatic: [String: Bool] = [:]
}
