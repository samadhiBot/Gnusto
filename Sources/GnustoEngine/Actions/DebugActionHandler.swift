import Foundation

/// Action handler for the DEBUG verb.
///
/// This verb allows examining the internal state of game objects, locations, or players.
/// It's primarily intended for development and debugging purposes.
public final class DebugActionHandler: ActionHandler {
    public init() {}

    public func validate(context: ActionContext) async throws {
        guard let directObject = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object to examine.")
        }
        if let _ = try? await context.engine.item(directObject) { return }
        if let _ = try? await context.engine.location(LocationID(directObject.rawValue)) { return }
        if let _ = try? await context.engine.item(directObject) { return }

        throw ActionResponse.unknownItem(directObject)
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObject = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object to examine.")
        }
        let state = context.stateSnapshot
        // Check for item
        if let item = state.items[directObject] {
            var debugInfo = "Debug information for item: \(item.name):\n"
            debugInfo += "ID: \(item.id.rawValue)\n"
            debugInfo += "Type: Item\n"
            debugInfo += "Attributes:\n"
            for (key, value) in item.attributes {
                debugInfo += "  \(key): \(value)\n"
            }
            if item.parent != .nowhere {
                debugInfo += "Parent: \(item.parent)\n"
            }
            return ActionResult(debugInfo)
        }
        // Check for location
        if let location = state.locations[LocationID(directObject.rawValue)] {
            var debugInfo = "Debug information for location: \(location.name):\n"
            debugInfo += "ID: \(location.id.rawValue)\n"
            debugInfo += "Type: Location\n"
            debugInfo += "Attributes:\n"
            for (key, value) in location.attributes {
                debugInfo += "  \(key): \(value)\n"
            }
            debugInfo += "Exits: \(location.exits)\n"
            return ActionResult(debugInfo)
        }
        // Check for player
        if directObject == .player {
            let player = state.player
            var debugInfo = "Debug information for player:\n"
            debugInfo += "ID: player\n"
            debugInfo += "Type: Player\n"
            debugInfo += "Current Location ID: \(player.currentLocationID)\n"
            debugInfo += "Carrying Capacity: \(player.carryingCapacity)\n"
            debugInfo += "Health: \(player.health)\n"
            debugInfo += "Moves: \(player.moves)\n"
            debugInfo += "Score: \(player.score)\n"
            return ActionResult(debugInfo)
        }
        throw ActionResponse.unknownItem(directObject)
    }
}
