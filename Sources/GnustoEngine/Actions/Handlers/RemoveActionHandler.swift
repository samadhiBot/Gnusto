import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF"), allowing the
/// player to unequip an item they are currently wearing.
public struct RemoveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.take, .off, .directObject),
    ]

    public let verbs: [Verb] = [.remove, .doff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "REMOVE" command.
    ///
    /// This action validates prerequisites and handles removing worn items.
    /// Checks that items exist, are currently worn, and are removable.
    /// Supports both single items and ALL commands.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to remove)
        if !command.isAllCommand {
            guard command.directObjects.isNotEmpty else {
                throw ActionResponse.prerequisiteNotMet(
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
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.remove)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Check if item is currently worn
                guard targetItem.hasFlag(.isWorn) else {
                    if command.isAllCommand {
                        continue  // Skip items not worn in ALL commands
                    } else {
                        throw ActionResponse.itemIsNotWorn(targetItemID)
                    }
                }

                // Check if item is removable (not fixed scenery)
                guard !targetItem.hasFlag(.omitDescription) else {
                    if command.isAllCommand {
                        continue  // Skip non-removable items in ALL commands
                    } else {
                        throw ActionResponse.itemNotRemovable(targetItemID)
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Clear .isWorn flag
                if let wornChange = await engine.clearFlag(.isWorn, on: targetItem) {
                    itemStateChanges.append(wornChange)
                }

                // Set .isTouched flag if not already set
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
