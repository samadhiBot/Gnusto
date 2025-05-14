import Foundation

/// Action handler for the DEBUG verb.
///
/// This verb allows examining the internal state of game objects, locations, or players.
/// It's primarily intended for development and debugging purposes.
public final class DebugActionHandler: ActionHandler {
    public init() {}

    public func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object to examine.")
        }

        switch directObjectRef {
        case .player:
            return // Player is always a valid entity for DEBUG.
        case .item(let itemID):
            guard (try? await context.engine.item(itemID)) != nil else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
        case .location(let locationID):
            guard (try? await context.engine.location(locationID)) != nil else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
        }
    }

    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            // This should ideally be caught by validate, but as a safeguard:
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object.")
        }

        let state = context.stateSnapshot
        var debugInfo = ""

        switch directObjectRef {
        case .player:
            let player = state.player
            debugInfo = "DEBUG: Player\n"
            debugInfo += "ID:                player\n"
            debugInfo += "Current Location:  \(player.currentLocationID.rawValue)\n"
            debugInfo += "Carrying Capacity: \(player.carryingCapacity)\n"
            debugInfo += "Health:            \(player.health)\n"
            debugInfo += "Moves:             \(player.moves)\n"
            debugInfo += "Score:             \(player.score)\n"
            let inventoryItems = state.items.values.filter { $0.parent == .player }.map { $0.id.rawValue }
            debugInfo += "Inventory (IDs):   \(inventoryItems.isEmpty ? "(empty)" : inventoryItems.joined(separator: ", "))\n"

        case .item(let itemID):
            guard let item = state.items[itemID] else {
                // Should be caught by validate, but good to handle defensively.
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            debugInfo = "DEBUG: Item '\(item.name)' (ID: \(item.id.rawValue))\n"
            debugInfo += "Parent:   \(item.parent)\n"
            debugInfo += "Size:     \(item.size)\n"
            debugInfo += "Capacity: \(item.capacity)\n"
            // Using item.adjectives and item.synonyms directly
            debugInfo += "Adjectives: \(item.adjectives.isEmpty ? "(none)" : item.adjectives.joined(separator: ", "))\n"
            debugInfo += "Synonyms: \(item.synonyms.isEmpty ? "(none)" : item.synonyms.joined(separator: ", "))\n"
            debugInfo += "Attributes:\n"
            if item.attributes.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                // Sort attributes by key for consistent output
                for (key, value) in item.attributes.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(key.rawValue): \(value)\n"
                }
            }

        case .location(let locationID):
            guard let location = state.locations[locationID] else {
                // Should be caught by validate.
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            debugInfo = "DEBUG: Location '\(location.name)' (ID: \(location.id.rawValue))\n"
            // Using location.isInherentlyLit and location.localGlobals directly
            debugInfo += "Is Lit:      \(location.isInherentlyLit() ? "Yes (inherently)" : "No (or depends on light source)")\n"
            let localGlobals = location.localGlobals.map { $0.rawValue }
            debugInfo += "Local Globals: \(localGlobals.isEmpty ? "(none)" : localGlobals.joined(separator: ", "))\n"
            debugInfo += "Attributes:\n"
            if location.attributes.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                // Sort attributes by key for consistent output
                for (key, value) in location.attributes.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(key.rawValue): \(value)\n"
                }
            }
            debugInfo += "Exits:\n"
            if location.exits.isEmpty {
                debugInfo += "  (none)\n"
            } else {
                // Sort exits by direction for consistent output
                for (direction, exit) in location.exits.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    debugInfo += "  - \(direction.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0)) -> \(exit.destinationID.rawValue)"
                    if let door = exit.doorID {
                        debugInfo += " (Door: \(door.rawValue))\n"
                    } else {
                        debugInfo += "\n"
                    }
                }
            }
        }
        return ActionResult(debugInfo)
    }
}
