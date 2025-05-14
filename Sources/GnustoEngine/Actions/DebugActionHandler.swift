import Foundation

/// Action handler for the DEBUG verb.
///
/// This verb allows examining the internal state of game objects, locations, or players.
/// It's primarily intended for development and debugging purposes.
public final class DebugActionHandler: ActionHandler {
    public init() {}

    public func validate(context: ActionContext) async throws {
        guard let directObjectID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object to examine.")
        }

        // Order of checks: Player, Item, then Location.
        if directObjectID == .player {
            return // Player is a valid entity.
        }

        if (try? await context.engine.item(directObjectID)) != nil {
            return // Item found.
        }

        if (try? await context.engine.location(LocationID(directObjectID.rawValue))) != nil {
            return // Location found.
        }

        throw ActionResponse.unknownItem(directObjectID)
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectID = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object.")
        }

        let state = context.stateSnapshot

        // Player
        if directObjectID == .player {
            let player = state.player
            var debugInfo = "DEBUG: Player\n"
            debugInfo += "ID:                player\n"
            debugInfo += "Current Location:  \(player.currentLocationID.rawValue)\n"
            debugInfo += "Carrying Capacity: \(player.carryingCapacity)\n"
            debugInfo += "Health:            \(player.health)\n"
            debugInfo += "Moves:             \(player.moves)\n"
            debugInfo += "Score:             \(player.score)\n"
            let inventoryItems = state.items.values.filter { $0.parent == .player }.map { $0.id.rawValue }
            debugInfo += "Inventory (IDs):   \(inventoryItems.isEmpty ? "(empty)" : inventoryItems.joined(separator: ", "))\n"
            return ActionResult(debugInfo)
        }

        // Item
        if let item = state.items[directObjectID] {
            var debugInfo = "DEBUG: Item '\(item.name)' (ID: \(item.id.rawValue))\n"
            debugInfo += "Parent:   \(item.parent)\n"
            debugInfo += "Size:     \(item.size)\n"
            debugInfo += "Capacity: \(item.capacity)\n"
            debugInfo += "Adjectives: \(item.adjectives.isEmpty ? "(none)" : item.adjectives.joined(separator: ", "))\n"
            debugInfo += "Synonyms: \(item.synonyms.isEmpty ? "(none)" : item.synonyms.joined(separator: ", "))\n"
            debugInfo += "Attributes:\n"
            if item.attributes.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                for (key, value) in item.attributes.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(key.rawValue): \(value)\n"
                }
            }
            return ActionResult(debugInfo)
        }

        // Location
        let locationID = LocationID(directObjectID.rawValue)
        if let location = state.locations[locationID] {
            var debugInfo = "DEBUG: Location '\(location.name)' (ID: \(location.id.rawValue))\n"
            debugInfo += "Is Lit:      \(location.isInherentlyLit() ? "Yes (inherently)" : "No (or depends on light source)")\n"
            let localGlobals = location.localGlobals.map { $0.rawValue }
            debugInfo += "Local Globals: \(localGlobals.isEmpty ? "(none)" : localGlobals.joined(separator: ", "))\n"
            debugInfo += "Attributes:\n"
            if location.attributes.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                for (key, value) in location.attributes.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(key.rawValue): \(value)\n"
                }
            }
            debugInfo += "Exits:\n"
            if location.exits.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                for (direction, exit) in location.exits.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(direction.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0)) -> \(exit.destinationID.rawValue)"
                    if let door = exit.doorID {
                        debugInfo += " (Door: \(door.rawValue))\n"
                    } else {
                        debugInfo += "\n"
                    }
                }
            }
            return ActionResult(debugInfo)
        }

        throw ActionResponse.unknownItem(directObjectID)
    }
}
