import Foundation

/// Handles the "EAT" command for consuming food items.
/// This handler manages food consumption with proper container logic and state changes.
public struct EatActionHandler: ActionHandler {

    /// Validates the "EAT" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate what to eat).
    /// 2. The target item exists and is reachable.
    /// 3. The item or its contents are edible.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Ensure we have a direct object
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.eatWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyEatFood)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // Check if the item is directly edible
        if targetItem.hasFlag(.isEdible) {
            // Direct edible item - check reachability
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
            return
        }

        // If not directly edible, check if it's a container with edible contents
        if targetItem.hasFlag(.isContainer) {
            // Check if container is reachable
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Check if container is open (closed containers can't be eaten from)
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has edible contents
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            guard !edibleContents.isEmpty else {
                let message = context.message(.nothingToEatIn(container: targetItem.name))
                throw ActionResponse.prerequisiteNotMet(message)
            }
            return
        }

        // Item is neither edible nor a container with edibles
        throw ActionResponse.itemNotEdible(targetItemID)
    }

    /// Processes the "EAT" command.
    ///
    /// Handles consuming food either directly or from containers.
    /// Edible items are typically removed after consumption.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "EatActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []
        var message: String

        // Mark item as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }

        // Handle direct edible item
        if targetItem.hasFlag(.isEdible) {
            // Remove the edible item (it's consumed)
            let removeChange = await context.engine.move(targetItem, to: .nowhere)
            stateChanges.append(removeChange)

            message = context.message(.eatSuccess(item: targetItem.name))
        }
        // Handle container with edible contents
        else if targetItem.hasFlag(.isContainer) {
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            if let firstEdible = edibleContents.first {
                // For closed containers, can't eat from them
                if !targetItem.hasFlag(.isOpen) {
                    message = context.message(.cannotEatFromClosed(container: targetItem.name))
                } else {
                    // Remove the first edible item from the container
                    let consumeChange = await context.engine.move(firstEdible, to: .nowhere)
                    stateChanges.append(consumeChange)

                    // Update pronouns to refer to the consumed food
                    if let pronounChange = await context.engine.updatePronouns(to: firstEdible) {
                        stateChanges.append(pronounChange)
                    }

                    message = context.message(
                        .eatFromContainer(food: firstEdible.name, container: targetItem.name)
                    )
                }
            } else {
                message = context.message(.nothingToEatIn(container: targetItem.name))
            }
        } else {
            // This shouldn't happen after validation, but handle it
            message = context.message(.cannotEat(item: targetItem.name))
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the eat/drink action completes.
    ///
    /// Currently no post-processing is needed for consumption.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for eat/drink
    }
}
