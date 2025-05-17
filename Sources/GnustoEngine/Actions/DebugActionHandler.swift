import CustomDump
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
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object.")
        }

        var target = ""

        switch directObjectRef {
        case .player:
            customDump(context.stateSnapshot.player, to: &target)
            return ActionResult(target)

        case .item(let itemID):
            guard let item = context.stateSnapshot.items[itemID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(item, to: &target)
            return ActionResult(target)

        case .location(let locationID):
            guard let location = context.stateSnapshot.locations[locationID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(location, to: &target)
            return ActionResult(target)
        }
    }
}
