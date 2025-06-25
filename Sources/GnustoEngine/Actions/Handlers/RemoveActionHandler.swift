import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF"), allowing the
/// player to unequip an item they are currently wearing.
public struct RemoveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.take, .off, .directObject),
    ]

    public let verbs: [VerbID] = [.remove, .doff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods
    /// Validates the "REMOVE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to remove).
    /// 2. For single object commands, validates the specific item.
    /// 3. For ALL commands, allows empty directObjects (handled in process method).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
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
                engine.messenger.thatsNotSomethingYouCan(.remove))
        }

        // 2. Check if the item exists and is worn by the player
        let targetItem = try await engine.item(targetItemID)

        // 3. Check if the item is currently worn
        guard targetItem.hasFlag(.isWorn) else {
            throw ActionResponse.itemIsNotWorn(targetItemID)
        }

        // 4. Check if the item is fixed scenery
        guard !targetItem.hasFlag(.omitDescription) else {
            throw ActionResponse.itemNotRemovable(targetItemID)
        }
    /// Processes the "REMOVE" command.
    ///
    /// For each item to be removed:
    /// 1. Checks if the item is currently worn
    /// 2. Checks if the item is removable (not scenery)
    /// 3. Clears the `.isWorn` flag on the item
    /// 4. Updates touched flags and pronouns
    /// 5. Provides appropriate feedback
    ///
    /// After being removed, items remain in the player's inventory.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
        // For ALL commands, empty directObjects is valid (means nothing to remove)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                return ActionResult(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var removedItems: [Item] = []
        var lastRemovedItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    return ActionResult(
                        engine.messenger.thatsNotSomethingYouCan(.remove)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if item is currently worn
                    guard targetItem.hasFlag(.isWorn) else {
                        continue  // Skip items not worn in ALL commands
                    }

                    // Check if item is removable (not scenery)
                    guard !targetItem.hasFlag(.omitDescription) else {
                        continue  // Skip non-removable items in ALL commands
                    }
                }

                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Clear .isWorn flag
                if let wornChange = await engine.clearFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
                }

                // Change 2: Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                removedItems.append(targetItem)
                lastRemovedItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastRemovedItem {
            if removedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: removedItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }

        // Generate appropriate message
        let message =
            if removedItems.isEmpty {
                command.isAllCommand
                    ? engine.messenger.youArentWearingAnything()
                    : engine.messenger.doWhat(verb: command.verb)
            } else {
                engine.messenger.youRemoveMultipleItems(
                    items: removedItems.listWithDefiniteArticles
                )
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
