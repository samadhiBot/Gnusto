import Foundation

/// Handles the "EAT" command for consuming food items.
/// This handler manages food consumption with proper container logic and state changes.
public struct EatActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.eat, .consume, .devour]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates the "EAT" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate what to eat).
    /// 2. The target item exists and is reachable.
    /// 3. The item or its contents are edible.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Ensure we have a direct object
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyEatFood()
            )
        }

        // Check if item exists
        let targetItem = try await engine.item(targetItemID)

        // Check if the item is directly edible
        if targetItem.hasFlag(.isEdible) {
            // Direct edible item - check reachability
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
            return
        }

        // If not directly edible, check if it's a container with edible contents
        if targetItem.hasFlag(.isContainer) {
            // Check if container is reachable
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Check if container is open (closed containers can't be eaten from)
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has edible contents
            let containerContents = await engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            guard !edibleContents.isEmpty else {
                let message = engine.messenger.nothingToEatIn(
                    container: targetItem.withDefiniteArticle
                )
                throw ActionResponse.prerequisiteNotMet(message)
            }
            return
        }

        // Item is neither edible nor a container with edibles
        throw ActionResponse.itemNotEdible(targetItemID)
    /// Processes the "EAT" command.
    ///
    /// Handles consuming food either directly or from containers.
    /// Edible items are typically removed after consumption.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate message and state changes.
        guard
            let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "EatActionHandler: directObject was not an item in process."
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Handle direct edible item
        if targetItem.hasFlag(.isEdible) {
            return ActionResult(
                engine.messenger.eatSuccess(
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        }
        // Handle container with edible contents
        else if targetItem.hasFlag(.isContainer) {
            let containerContents = await engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            if let firstEdible = edibleContents.first {
                // For closed containers, can't eat from them
                if !targetItem.hasFlag(.isOpen) {
                    return ActionResult(
                        engine.messenger.cannotEatFromClosed(
                            container: targetItem.withDefiniteArticle
                        ),
                        await engine.setFlag(.isTouched, on: targetItem)
                    )
                } else {
                    return ActionResult(
                        engine.messenger.eatFromContainer(
                            food: firstEdible.withDefiniteArticle,
                            container: targetItem.withDefiniteArticle
                        ),
                        await engine.setFlag(.isTouched, on: targetItem),
                        await engine.move(firstEdible, to: .nowhere)
                    )
                }
            } else {
                return ActionResult(
                    engine.messenger.nothingToEatIn(container: targetItem.withDefiniteArticle),
                    await engine.setFlag(.isTouched, on: targetItem)
                )
            }
        } else {
            // This shouldn't happen after validation, but handle it
            return ActionResult(
                engine.messenger.cannotDoThat(
                    verb: .eat,
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem)
            )
        }
    }
}
