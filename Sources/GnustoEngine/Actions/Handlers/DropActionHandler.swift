import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN"), allowing the player
/// to remove an item from their inventory and place it in the current location.
public struct DropActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let verbs: [VerbID] = [.drop, .discard]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "DROP" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to drop).
    /// 2. The direct object refers to an existing item.
    /// 3. The player is currently holding the item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet` (for missing object or wrong item type),
    ///           `itemNotHeld` (if the player isn't holding the item).
    ///           Can also throw errors from `engine.item()`.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // For ALL commands, allow empty directObjects (handled in process method)
        if command.isAllCommand {
            return
        }

        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        // For single object commands, validate the single object
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.drop)
            )
        }

        // 2. Check if item exists and is held by player
        let targetItem = try await engine.item(targetItemID)
        guard targetItem.parent == .player else {
            throw ActionResponse.itemNotHeld(targetItemID)
        }

        // 3. Check if item is droppable (not scenery/fixed)
        guard !targetItem.hasFlag(.omitDescription) else {
            throw ActionResponse.itemNotDroppable(targetItemID)
        }

        // 3. Check if item is droppable (not scenery/fixed)
        guard !targetItem.hasFlag(.omitDescription) else {
            throw ActionResponse.itemNotDroppable(targetItemID)
        }
    /// Processes the "DROP" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item(s).
    /// 2. Checks if the player is actually holding the item. If not, a message like
    ///    "You aren't holding that." is returned.
    /// 3. If the player is holding the item:
    ///    a. Creates a `StateChange` to move the item to the current location.
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the dropped item.
    ///    d. Returns a confirmation message, typically "Dropped."
    ///
    /// For ALL commands, processes each object individually and provides consolidated feedback.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: `ActionResponse.internalEngineError` if direct object is not an item (should be
    ///           caught by validate), or errors from `engine.item()`.
        // For ALL commands, empty directObjects is valid (means nothing to drop)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.internalEngineError(
                    engine.messenger.internalEngineError()
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var droppedItems: [Item] = []
        var lastDroppedItem: Item?

        // Get current location for dropping items
        let currentLocationID = await engine.playerLocationID

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.internalEngineError(
                        engine.messenger.thatsNotSomethingYouCan(.drop)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Check if player is actually holding this item
                guard targetItem.parent == .player else {
                    if command.isAllCommand {
                        continue  // Skip items not held in ALL commands
                    } else {
                        return ActionResult(
                            engine.messenger.youArentHoldingThat()
                        )
                    }
                }

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if item is droppable (not scenery/fixed)
                    guard !targetItem.hasFlag(.omitDescription) else {
                        continue  // Skip non-droppable items in ALL commands
                    }
                }

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if item is droppable (not scenery/fixed)
                    guard !targetItem.hasFlag(.omitDescription) else {
                        continue  // Skip non-droppable items in ALL commands
                    }
                }

                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Move item to current location
                let moveChange = await engine.move(
                    targetItem, to: .location(currentLocationID))
                itemStateChanges.append(moveChange)

                // Change 2: Set `.isTouched` flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                droppedItems.append(targetItem)
                lastDroppedItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastDroppedItem {
            if droppedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: droppedItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }

        // Clear .isWorn flag for all dropped items (after pronoun update to match expected order)
        for droppedItem in droppedItems {
            if let wornChange = await engine.clearFlag(.isWorn, on: droppedItem) {
                allStateChanges.append(wornChange)
            }
        }

        // Generate appropriate message
        let message =
            if command.isAllCommand {
                if droppedItems.isEmpty {
                    "You have nothing to drop."
                } else {
                    engine.messenger.youDropMultipleItems(
                        items: droppedItems.listWithDefiniteArticles
                    )
                }
            } else {
                engine.messenger.dropped()
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }

    // Rely on default postProcess.
}
