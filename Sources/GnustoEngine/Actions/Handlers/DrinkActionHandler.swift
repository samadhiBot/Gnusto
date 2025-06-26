import Foundation

/// Handles the "DRINK" command for consuming liquids from various sources.
/// Separate from eating, this handles liquid consumption with proper container logic.
public struct DrinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .from, .indirectObject),
    ]

    public let verbs: [Verb] = [.drink, .sip, .quaff, .imbibe]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DRINK" command.
    ///
    /// This action validates prerequisites and handles consuming liquids either directly
    /// or from containers. Drinkable items are typically removed after consumption.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Ensure we have a direct object
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyDrinkLiquids()
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Handle "drink X from Y" syntax
//        if let indirectObjectRef = command.indirectObject {
//            guard case .item(let containerID) = indirectObjectRef else {
//                throw ActionResponse.prerequisiteNotMet(
//                    engine.messenger.cannotDoThat(verb: "drink")
//                )
//            }
//
//            let container = try await engine.item(containerID)
//
//            // Verify the liquid is actually in the specified container
//            guard case .item(let actualParentID) = targetItem.parent,
//                actualParentID == containerID
//            else {
//                throw ActionResponse.prerequisiteNotMet(
//                    engine.messenger.liquidNotInContainer(
//                        liquid: targetItem.withDefiniteArticle,
//                        container: container.withDefiniteArticle
//                    )
//                )
//            }
//        }

        // Handle direct drinkable item
        if targetItem.hasFlag(.isDrinkable) || targetItem.hasFlag(.isEdible) {
            // Check if item is inside a closed container
            if case .item(let parentID) = targetItem.parent {
                let container = try await engine.item(parentID)
                if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                    if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                        throw ActionResponse.containerIsClosed(parentID)
                    } else {
                        throw ActionResponse.itemNotAccessible(targetItemID)
                    }
                }
            }

            let drinkSuccess = engine.messenger.drinkSuccess(item: targetItem.withDefiniteArticle)

            let message =
                if targetItem.shouldTakeFirst {
                    """
                    \(engine.messenger.taken())
                    \(drinkSuccess)
                    """
                } else {
                    drinkSuccess
                }

            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        }
        // Handle container with drinkable contents
        else if targetItem.hasFlag(.isContainer) {
            // Check if container is open
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has drinkable contents
            let containerContents = await engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter {
                $0.hasFlag(.isDrinkable) || $0.hasFlag(.isEdible)
            }

            guard let firstDrinkable = drinkableContents.first else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.nothingToDrinkIn(
                        container: targetItem.withDefiniteArticle
                    )
                )
            }

            return ActionResult(
                engine.messenger.drinkFromContainer(
                    liquid: firstDrinkable.withDefiniteArticle,
                    container: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: firstDrinkable),
                await engine.move(firstDrinkable, to: .nowhere)
            )
        } else {
            // Item is neither drinkable nor a container with drinkables
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDrink(item: targetItem.withDefiniteArticle)
            )
        }
    }
}
