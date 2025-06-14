import Foundation

/// Handles the "DRINK" command for consuming liquids from various sources.
/// Separate from eating, this handles liquid consumption with proper container logic.
public struct DrinkActionHandler: ActionHandler {
    public init() {}

    /// Validates the "DRINK" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate what to drink).
    /// 2. The target item exists and is reachable.
    /// 3. The item or its contents are drinkable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Ensure we have a direct object
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.drinkWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyDrinkLiquids)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // Check if the item is directly drinkable
        if targetItem.hasFlag(.isDrinkable) {
            // Direct drinkable item - check reachability
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
            return
        }

        // If not directly drinkable, check if it's a container with drinkable contents
        if targetItem.hasFlag(.isContainer) {
            // Check if container is reachable
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Check if container is open (closed containers can't be drunk from)
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has drinkable contents
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter { $0.hasFlag(.isDrinkable) }

            guard !drinkableContents.isEmpty else {
                let message = context.message(.nothingToDrinkIn(container: targetItem.name))
                throw ActionResponse.prerequisiteNotMet(message)
            }
            return
        }

        // Item is neither drinkable nor a container with drinkables
        let message = context.message(.cannotDrink(item: targetItem.name))
        throw ActionResponse.prerequisiteNotMet(message)
    }

    /// Processes the "DRINK" command.
    ///
    /// Handles consuming liquids either directly or from containers.
    /// Drinkable items are typically removed after consumption.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "DrinkActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []
        var message: String

        // Mark item as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }

        // Handle container first (prioritize over direct drinkable)
        if targetItem.hasFlag(.isContainer) {
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter { $0.hasFlag(.isDrinkable) }

            if let firstDrinkable = drinkableContents.first {
                // For closed containers, can't drink from them
                if !targetItem.hasFlag(.isOpen) {
                    message = "You can't drink the \(targetItem.name)."
                } else {
                    // Remove the first drinkable item from the container
                    let consumeChange = await context.engine.move(firstDrinkable, to: .nowhere)
                    stateChanges.append(consumeChange)

                    // Update pronouns to refer to the consumed liquid
                    if let pronounChange = await context.engine.updatePronouns(to: firstDrinkable) {
                        stateChanges.append(pronounChange)
                    }

                    message =
                        "You drink the \(firstDrinkable.name) from the \(targetItem.name). Refreshing!"
                }
            } else {
                message = "There's nothing to drink in the \(targetItem.name)."
            }
        }
        // Handle direct drinkable item
        else if targetItem.hasFlag(.isDrinkable) {
            // Remove the drinkable item (it's consumed)
            let removeChange = await context.engine.move(targetItem, to: .nowhere)
            stateChanges.append(removeChange)

            message = "You drink the \(targetItem.name). It's quite refreshing."
        } else {
            // This shouldn't happen after validation, but handle it
            message = "You can't drink the \(targetItem.name)."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }
}
