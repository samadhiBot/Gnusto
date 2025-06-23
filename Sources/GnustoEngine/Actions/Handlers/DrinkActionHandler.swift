import Foundation

/// Handles the "DRINK" command for consuming liquids from various sources.
/// Separate from eating, this handles liquid consumption with proper container logic.
public struct DrinkActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .drink

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .from, .indirectObject),
    ]

    public let synonyms: [String] = ["sip", "quaff"]

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
    public func validate(context: ActionContext) async throws {
        // Ensure we have a direct object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .drink)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.canOnlyDrinkLiquids()
            )
        }

        // Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // Check if the item is directly drinkable (either isDrinkable or isEdible for ZIL compatibility)
        if targetItem.hasFlag(.isDrinkable) || targetItem.hasFlag(.isEdible) {
            // Check if item is inside a closed container
            if case .item(let parentID) = targetItem.parent {
                let container = try await context.engine.item(parentID)
                if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                    if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                        throw ActionResponse.containerIsClosed(parentID)
                    } else {
                        throw ActionResponse.itemNotAccessible(targetItemID)
                    }
                }
            }

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

            // Check if container has drinkable contents (either isDrinkable or isEdible for ZIL compatibility)
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter {
                $0.hasFlag(.isDrinkable) || $0.hasFlag(.isEdible)
            }

            guard !drinkableContents.isEmpty else {
                let message = context.message.nothingToDrinkIn(
                    container: targetItem.withDefiniteArticle
                )
                throw ActionResponse.prerequisiteNotMet(message)
            }
            return
        }

        // Item is neither drinkable nor a container with drinkables
        throw ActionResponse.prerequisiteNotMet(
            context.message.cannotDrink(item: targetItem.withDefiniteArticle)
        )
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

        // Handle container first (prioritize over direct drinkable)
        if targetItem.hasFlag(.isContainer) {
            let containerContents = await context.engine.items(in: .item(targetItemID))
            let drinkableContents = containerContents.filter {
                $0.hasFlag(.isDrinkable) || $0.hasFlag(.isEdible)
            }

            if let firstDrinkable = drinkableContents.first {
                // For closed containers, can't drink from them
                if !targetItem.hasFlag(.isOpen) {
                    return ActionResult(
                        message: context.message.cannotDrinkFromClosed(
                            container: targetItem.withDefiniteArticle
                        ),
                        changes: [
                            await context.engine.setFlag(.isTouched, on: targetItem)
                        ]
                    )
                } else {
                    return ActionResult(
                        message: context.message.drinkFromContainer(
                            liquid: firstDrinkable.withDefiniteArticle,
                            container: targetItem.withDefiniteArticle
                        ),
                        changes: [
                            await context.engine.setFlag(.isTouched, on: targetItem),
                            await context.engine.move(firstDrinkable, to: .nowhere),
                            await context.engine.updatePronouns(to: firstDrinkable),
                        ]
                    )
                }
            } else {
                return ActionResult(
                    message: context.message.nothingToDrinkIn(
                        container: targetItem.withDefiniteArticle
                    ),
                    changes: [
                        await context.engine.setFlag(.isTouched, on: targetItem)
                    ]
                )
            }
        }
        // Handle direct drinkable item (either isDrinkable or isEdible for ZIL compatibility)
        else if targetItem.hasFlag(.isDrinkable) || targetItem.hasFlag(.isEdible) {
            return ActionResult(
                message: context.message.drinkSuccess(item: targetItem.withDefiniteArticle),
                changes: [
                    await context.engine.setFlag(.isTouched, on: targetItem),
                    await context.engine.move(targetItem, to: .nowhere),
                ]
            )
        } else {
            // This shouldn't happen after validation, but handle it
            return ActionResult(
                context.message.cannotDrink(item: targetItem.withDefiniteArticle),
                await context.engine.setFlag(.isTouched, on: targetItem)
            )
        }
    }
}
