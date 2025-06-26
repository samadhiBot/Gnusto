import Foundation

/// Handles the "WEAR" command and its synonyms (e.g., "DON"), allowing the player to
/// equip an item that is wearable.
public struct WearActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.put, .on, .directObjects),
    ]

    public let verbs: [Verb] = [.wear, .don]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "WEAR" command.
    ///
    /// This action validates prerequisites and handles wearing wearable items.
    /// Checks that items exist, are held by the player, are wearable, and not already worn.
    /// Supports both single items and ALL commands.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to wear)
        if !command.isAllCommand {
            guard command.directObjects.isNotEmpty else {
                throw ActionResponse.prerequisiteNotMet(
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
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.wear)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Check if player is holding the item
                guard await engine.playerIsHolding(targetItemID) else {
                    if command.isAllCommand {
                        continue  // Skip items not held in ALL commands
                    } else {
                        throw ActionResponse.itemNotHeld(targetItemID)
                    }
                }

                // Check if item is wearable
                guard targetItem.hasFlag(.isWearable) else {
                    if command.isAllCommand {
                        continue  // Skip non-wearable items in ALL commands
                    } else {
                        throw ActionResponse.itemNotWearable(targetItemID)
                    }
                }

                // Check if already worn
                guard !targetItem.hasFlag(.isWorn) else {
                    if command.isAllCommand {
                        continue  // Skip already worn items in ALL commands
                    } else {
                        throw ActionResponse.itemIsAlreadyWorn(targetItemID)
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Set .isWorn flag
                if let wornChange = await engine.setFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
                }

                // Set .isTouched flag if not already set
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
