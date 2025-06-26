import Foundation

/// Handles the "MOVE" command and its synonyms (e.g., "SHIFT", "SLIDE"), allowing the player
/// to move or manipulate objects in the game world. This is typically used for objects that
/// can be moved but not taken, such as moving leaves to reveal something underneath.
public struct MoveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let verbs: [VerbID] = [.move, .shift, .slide]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "MOVE" command.
    ///
    /// This action validates prerequisites and handles moving or manipulating objects.
    /// Unlike TAKE, this doesn't require items to be takable, as MOVE is often used
    /// for manipulating objects that are too large or fixed to pick up.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to move)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var movedItems: [Item] = []
        var lastMovedItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.move)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Check if player can reach the item
                guard await engine.playerCanReach(targetItemID) else {
                    if command.isAllCommand {
                        continue  // Skip unreachable items in ALL commands
                    } else {
                        throw ActionResponse.itemNotAccessible(targetItemID)
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                movedItems.append(targetItem)
                lastMovedItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastMovedItem {
            if movedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: movedItems
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
                if movedItems.isEmpty {
                    engine.messenger.nothingHereToMove()
                } else {
                    engine.messenger.moveMultipleItems(items: movedItems.listWithDefiniteArticles)
                }
            } else if let movedItem = movedItems.first {
                // Check if item has special move behavior
                if movedItem.hasFlag(.isMovable) {
                    engine.messenger.moveSuccess(item: movedItem.withDefiniteArticle)
                } else {
                    // Default behavior: most things can't be meaningfully moved
                    engine.messenger.moveNoEffect(item: movedItem.withDefiniteArticle)
                }
            } else {
                engine.messenger.doWhat(verb: command.verb)
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
