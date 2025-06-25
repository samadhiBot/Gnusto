import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON"), allowing the player to
/// equip an item that is wearable.
public struct WearActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.put, .on, .directObjects),
    ]

    public let verbs: [VerbID] = [.wear, .don]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "WEAR" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to wear).
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
                engine.messenger.thatsNotSomethingYouCan(.wear)
            )
        }

        // 2. Check if the item exists and is held by the player
        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerIsHolding(targetItemID) else {
            throw ActionResponse.itemNotHeld(targetItemID)
        }

        // 3. Check if the (held) item is wearable
        guard targetItem.hasFlag(.isWearable) else {
            throw ActionResponse.itemNotWearable(targetItemID)
        }

        // 4. Check if already worn
        guard !targetItem.hasFlag(.isWorn) else {
            throw ActionResponse.itemIsAlreadyWorn(targetItemID)
        }
    /// Processes the "WEAR" command.
    ///
    /// For each item to be worn:
    /// 1. Checks if the player is holding the item
    /// 2. Checks if the item is wearable and not already worn
    /// 3. Sets the `.isWorn` flag on the item
    /// 4. Updates touched flags and pronouns
    /// 5. Provides appropriate feedback
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
        // For ALL commands, empty directObjects is valid (means nothing to wear)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                return ActionResult(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var wornItems: [Item] = []
        var lastWornItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    return ActionResult(
                        engine.messenger.thatsNotSomethingYouCan(.wear)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if player is holding the item
                    guard await engine.playerIsHolding(targetItemID) else {
                        continue  // Skip items not held in ALL commands
                    }

                    // Check if item is wearable
                    guard targetItem.hasFlag(.isWearable) else {
                        continue  // Skip non-wearable items in ALL commands
                    }

                    // Check if already worn
                    guard !targetItem.hasFlag(.isWorn) else {
                        continue  // Skip already worn items in ALL commands
                    }
                }

                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Set .isWorn flag
                if let wornChange = await engine.setFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
                }

                // Change 2: Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                wornItems.append(targetItem)
                lastWornItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastWornItem {
            if wornItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: wornItems
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
            if wornItems.isEmpty {
                command.isAllCommand
                    ? engine.messenger.nothingHereToWear()
                    : engine.messenger.doWhat(verb: command.verb)
            } else {
                engine.messenger.youPutOn(item: wornItems.listWithDefiniteArticles)
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
