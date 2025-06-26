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

    public init() {}

    /// Processes the "EAT" command.
    ///
    /// This action validates prerequisites and handles consuming food either directly
    /// or from containers. Edible items are typically removed after consumption.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
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

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Handle direct edible item
        if targetItem.hasFlag(.isEdible) {
            return ActionResult(
                engine.messenger.eatSuccess(
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        }
        // Handle container with edible contents
        else if targetItem.hasFlag(.isContainer) {
            // Check if container is open (closed containers can't be eaten from)
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has edible contents
            let containerContents = await engine.items(in: .item(targetItemID))
            let edibleContents = containerContents.filter { $0.hasFlag(.isEdible) }

            guard let firstEdible = edibleContents.first else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.nothingToEatIn(
                        container: targetItem.withDefiniteArticle
                    )
                )
            }

            return ActionResult(
                engine.messenger.eatFromContainer(
                    food: firstEdible.withDefiniteArticle,
                    container: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(firstEdible, to: .nowhere)
            )
        } else {
            // Item is neither edible nor a container with edibles
            throw ActionResponse.itemNotEdible(targetItemID)
        }
    }
}
