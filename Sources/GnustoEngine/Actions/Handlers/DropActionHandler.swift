import Foundation

/// Handles the "DROP" command and its synonyms (e.g., "PUT DOWN"), allowing the player
/// to remove an item from their inventory and place it in the current location.
public struct DropActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let verbs: [Verb] = [.drop, .discard]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "DROP" command.
    ///
    /// This action validates prerequisites and moves the specified item(s) from the player's
    /// inventory to the current location. Handles both single items and ALL commands.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to drop)
        if !command.isAllCommand {
            guard command.directObjects.isNotEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
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
                    throw ActionResponse.prerequisiteNotMet(
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

                // For ALL commands, validate this specific item
                if command.isAllCommand {
                    // Check if item is droppable (not scenery/fixed)
                    guard !targetItem.hasFlag(.omitDescription) else {
                        continue  // Skip non-droppable items in ALL commands
                    }
                } else {
                    // For single item commands, perform full validation
                    guard !targetItem.hasFlag(.omitDescription) else {
                        throw ActionResponse.itemNotDroppable(targetItemID)
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Move item to current location
                let moveChange = await engine.move(
                    targetItem, to: .location(currentLocationID))
                itemStateChanges.append(moveChange)

                // Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                // Clear .isWorn flag if item was being worn
                if let wornChange = await engine.clearFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
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
}
