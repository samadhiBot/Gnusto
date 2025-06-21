import Foundation

/// Handles the "FIND" command.
///
/// The FIND verb allows players to ask about the location of objects.
/// This handler provides different responses based on whether the target
/// object is visible, held by the player, or not present in the current scope.
public struct FindActionHandler: ActionHandler {
    public init() {}

    /// Validates the find command.
    ///
    /// Unlike most commands, FIND is more permissive - it can reference objects
    /// that aren't currently visible, as the purpose is to ask about their location.
    /// We only require that a direct object was specified.
    ///
    /// - Parameter context: The action context containing the command and engine.
    /// - Throws: `ActionError` if no direct object is specified.
    public func validate(context: ActionContext) async throws {
        guard context.command.directObject != nil else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .find)
            )
        }
    }

    /// Processes the "FIND" command.
    ///
    /// This action provides different responses based on the target object's state:
    /// - If the object is held by the player: "You have it."
    /// - If the object is visible in the current location: "It's right here!"
    /// - If the object exists but isn't visible: "You can't see any such thing here."
    /// - If the object doesn't exist: "You can't see any such thing here."
    ///
    /// - Parameter context: The action context for the current action.
    /// - Returns: An `ActionResult` containing the appropriate response message.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetObjectID = context.command.directObject,
            case .item(let itemID) = targetObjectID
        else {
            return ActionResult(
                context.message.unknownEntity()
            )
        }

        // Check if the item exists in the game
        guard let targetItem = try? await context.engine.item(itemID) else {
            return ActionResult(
                context.message.unknownEntity()
            )
        }

        // Check if the player is holding it
        if targetItem.parent == .player {
            return ActionResult(
                context.message.youHaveIt()
            )
        }

        // Check if the item is visible in the current scope
        let currentLocation = await context.engine.playerLocationID
        let scopeResolver = ScopeResolver(engine: context.engine)
        let itemsInScope = await scopeResolver.itemsInScopeFor(locationID: currentLocation)

        if itemsInScope.contains(itemID) {
            return ActionResult(
                context.message.itsRightHere()
            )
        }

        // Item exists but isn't visible
        return ActionResult(
            context.message.unknownEntity()
        )
    }
}
