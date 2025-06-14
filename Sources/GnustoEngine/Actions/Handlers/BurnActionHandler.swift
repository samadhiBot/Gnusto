import Foundation

/// Handles the "BURN" command.
///
/// The BURN verb allows players to attempt to set fire to objects.
/// This handler checks if the target object is flammable and provides
/// appropriate responses. Most objects cannot be burned, but some specific
/// items (like paper, wood, etc.) may have special burn behavior.
public struct BurnActionHandler: ActionHandler {
    public init() {}

    /// Validates the burn command.
    ///
    /// Ensures that:
    /// - A direct object is specified
    /// - The target object exists and is accessible
    /// - There is sufficient light to see the object
    ///
    /// - Parameter context: The action context containing the command and engine.
    /// - Throws: `ActionError` if validation fails.
    public func validate(context: ActionContext) async throws {
        guard let targetObjectID = context.command.directObject else {
            let message = context.message(.burnWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        guard case .item(let itemID) = targetObjectID else {
            let message = context.message(.canOnlyActOnItems(verb: "burn"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if the item exists and is accessible
        guard (try? await context.engine.item(itemID)) != nil else {
            throw ActionResponse.unknownEntity(targetObjectID)
        }

        guard await context.engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
        }
    }

    /// Processes the "BURN" command.
    ///
    /// This action performs the following:
    /// 1. Retrieves the target item
    /// 2. Checks if the item has the `.isFlammable` property
    /// 3. If flammable, removes the item and provides a burn message
    /// 4. If not flammable, provides an appropriate refusal message
    /// 5. Sets the `.isTouched` flag on the item
    /// 6. Updates pronouns to refer to the item
    ///
    /// - Parameter context: The action context for the current action.
    /// - Returns: An `ActionResult` containing the burn result and any state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetObjectID = context.command.directObject,
            case .item(let itemID) = targetObjectID
        else {
            let message = context.message(.cannotActOnThat(verb: "burn"))
            return ActionResult(message)
        }

        let targetItem = try await context.engine.item(itemID)

        var stateChanges: [StateChange] = []

        // Ensure the item is marked as touched
        if let touchChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchChange)
        }

        // Update pronouns
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        // Check if the item is flammable
        if targetItem.hasFlag(.isFlammable) {
            // Move the item to nowhere (destroy it)
            let destroyChange = await context.engine.move(targetItem, to: .nowhere)
            stateChanges.append(destroyChange)

            let message = context.message(.burnToCatchFire(item: targetItem.name))
            return ActionResult(
                message: message,
                stateChanges: stateChanges
            )
        } else {
            // Most items cannot be burned
            let message =
                if targetItem.name.lowercased().contains("house")
                    || targetItem.name.lowercased().contains("building")
                {
                    context.message(.burnJokingResponse)
                } else {
                    context.message(.burnCannotBurn(item: targetItem.name))
                }

            return ActionResult(
                message: message,
                stateChanges: stateChanges
            )
        }
    }
}
