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
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .eat)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.canOnlyEatFood()
            )
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
                let message = context.message.nothingToEatIn(
                    container: targetItem.withDefiniteArticle
                )
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
        guard
            let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "EatActionHandler: directObject was not an item in process."
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Handle direct edible item
        if targetItem.hasFlag(.isEdible) {
            return ActionResult(
                message: context.message.eatSuccess(
                    item: targetItem.withDefiniteArticle
                ),
                changes: [
                    await context.engine.setFlag(.isTouched, on: targetItem),
                    await context.engine.move(targetItem, to: .nowhere),
                ]
            )
        }
        // Handle container with edible contents
        else if targetItem.hasFlag(.isContainer) {
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            if let firstEdible = edibleContents.first {
                // For closed containers, can't eat from them
                if !targetItem.hasFlag(.isOpen) {
                    return ActionResult(
                        context.message.cannotEatFromClosed(
                            container: targetItem.withDefiniteArticle
                        ),
                        await context.engine.setFlag(.isTouched, on: targetItem)
                    )
                } else {
                    return ActionResult(
                        message: context.message.eatFromContainer(
                            food: firstEdible.withDefiniteArticle,
                            container: targetItem.withDefiniteArticle
                        ),
                        changes: [
                            await context.engine.setFlag(.isTouched, on: targetItem),
                            await context.engine.move(firstEdible, to: .nowhere),
                            await context.engine.updatePronouns(to: firstEdible),
                        ]
                    )
                }
            } else {
                return ActionResult(
                    context.message.nothingToEatIn(container: targetItem.withDefiniteArticle),
                    await context.engine.setFlag(.isTouched, on: targetItem)
                )
            }
        } else {
            // This shouldn't happen after validation, but handle it
            return ActionResult(
                context.message.cannotEat(item: targetItem.withDefiniteArticle),
                await context.engine.setFlag(.isTouched, on: targetItem)
            )
        }
    }
}
