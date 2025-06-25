import Foundation

/// Handles the "DRINK" command for consuming liquids from various sources.
/// Separate from eating, this handles liquid consumption with proper container logic.
public struct DrinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .from, .indirectObject),
    ]

    public let verbs: [VerbID] = [.drink, .sip, .quaff, .imbibe]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

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
                engine.messenger.canOnlyDrinkLiquids()
            )
        }

        // Check if item exists
        let targetItem = try await engine.item(targetItemID)

        // Check if the item is directly drinkable (either isDrinkable or isEdible for ZIL compatibility)
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

            // Direct drinkable item - check reachability
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
            return
        }

        // If not directly drinkable, check if it's a container with drinkable contents
        if targetItem.hasFlag(.isContainer) {
            // Check if container is reachable
            guard await engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }

            // Check if container is open (closed containers can't be drunk from)
            guard targetItem.hasFlag(.isOpen) else {
                throw ActionResponse.containerIsClosed(targetItemID)
            }

            // Check if container has drinkable contents (either isDrinkable or isEdible for ZIL compatibility)
            let containerContents = await engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter {
                $0.hasFlag(.isDrinkable) || $0.hasFlag(.isEdible)
            }

            guard !drinkableContents.isEmpty else {
                let message = engine.messenger.nothingToDrinkIn(
                    container: targetItem.withDefiniteArticle
                )
                throw ActionResponse.prerequisiteNotMet(message)
            }
            return
        }

        // Item is neither drinkable nor a container with drinkables
        throw ActionResponse.prerequisiteNotMet(
            engine.messenger.cannotDrink(item: targetItem.withDefiniteArticle)
        )
    /// Processes the "DRINK" command.
    ///
    /// Handles consuming liquids either directly or from containers.
    /// Drinkable items are typically removed after consumption.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "DrinkActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Handle container first (prioritize over direct drinkable)
        if targetItem.hasFlag(.isContainer) {
            let containerContents = await engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter {
                $0.hasFlag(.isDrinkable) || $0.hasFlag(.isEdible)
            }

            if let firstDrinkable = drinkableContents.first {
                // For closed containers, can't drink from them
                if !targetItem.hasFlag(.isOpen) {
                    return ActionResult(
                        engine.messenger.cannotDrinkFromClosed(
                            container: targetItem.withDefiniteArticle
                        ),
                        await engine.setFlag(.isTouched, on: targetItem)
                    )
                } else {
                    return ActionResult(
                        engine.messenger.drinkFromContainer(
                            liquid: firstDrinkable.withDefiniteArticle,
                            container: targetItem.withDefiniteArticle
                        ),
                        await engine.setFlag(.isTouched, on: targetItem),
                        await engine.move(firstDrinkable, to: .nowhere),
                        await engine.updatePronouns(to: firstDrinkable)
                    )
                }
            } else {
                return ActionResult(
                    engine.messenger.nothingToDrinkIn(
                        container: targetItem.withDefiniteArticle
                    ),
                    await engine.setFlag(.isTouched, on: targetItem)
                )
            }
        }

        // This shouldn't happen after validation, but handle it
        guard targetItem.hasFlag(.isDrinkable) || targetItem.hasFlag(.isEdible) else {
            return ActionResult(
                engine.messenger.cannotDrink(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem)
            )
        }

        let drinkSuccess = engine.messenger.drinkSuccess(item: targetItem.withDefiniteArticle)

        let message = if targetItem.shouldTakeFirst {
            """
            \(engine.messenger.taken())
            \(drinkSuccess)
            """
        } else {
            drinkSuccess
        }

        // Handle direct drinkable item (either isDrinkable or isEdible for ZIL compatibility)
        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.move(targetItem, to: .nowhere)
        )
    }
}
