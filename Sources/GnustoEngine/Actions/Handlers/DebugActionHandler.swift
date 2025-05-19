import CustomDump
import Foundation

/// Handles the "DEBUG" command, providing a way for game developers to inspect the
/// internal state of game entities during development and testing.
///
/// The DEBUG command requires a direct object (e.g., "DEBUG LANTERN", "DEBUG SELF",
/// "DEBUG WEST_OF_HOUSE"). It outputs a detailed, developer-friendly representation
/// of the specified item, location, or the player object using the `swift-custom-dump` library.
///
/// > Note: This handler is a development tool, and is only available in DEBUG game builds.
public struct DebugActionHandler: ActionHandler {
    public init() {}

    /// Validates the "DEBUG" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified.
    /// 2. The direct object refers to an existing entity (item, location, or player).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if no direct object is provided,
    ///           or `ActionResponse.unknownEntity` if the direct object does not exist.
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

    /// Processes the "DEBUG" command.
    ///
    /// Assuming validation has passed, this action retrieves the specified entity
    /// (item, location, or player) from the `GameState` snapshot and uses `customDump`
    /// to generate a string representation of its properties and values.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the detailed dump of the target entity.
    /// - Throws: `ActionResponse.prerequisiteNotMet` if no direct object is provided (though
    ///           this should ideally be caught by `validate`), or `ActionResponse.unknownEntity`
    ///           if the entity does not exist in the snapshot.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("DEBUG requires a direct object.")
        }

        var target = ""

        switch directObjectRef {
        case .player:
            customDump(context.stateSnapshot.player, to: &target)

        case .item(let itemID):
            guard let item = context.stateSnapshot.items[itemID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(item, to: &target)

        case .location(let locationID):
            guard let location = context.stateSnapshot.locations[locationID] else {
                throw ActionResponse.unknownEntity(directObjectRef)
            }
            customDump(location, to: &target)
        }
        return ActionResult("""
            ```
            \(target)
            ```
            """)
    }
}
