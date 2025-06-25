import Foundation

/// Handles the "PUSH" command and its synonyms (e.g., "PRESS", "SHOVE"), allowing the player
/// to push objects.
public struct PushActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let verbs: [VerbID] = [.push, .shove]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "PUSH" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to push).
    /// 2. The direct object refers to an existing item that the player can reach.
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
                engine.messenger.thatsNotSomethingYouCan(.push)
            )
        }

        // 2. Check if item exists
        _ = try await engine.item(targetItemID)

        // 3. Check reachability
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "PUSH" command.
    ///
    /// For each item to be pushed:
    /// 1. Checks if the player can reach the item
    /// 2. Updates touched flags and pronouns
    /// 3. Provides appropriate feedback (typically "Nothing happens")
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
        // For ALL commands, empty directObjects is valid (means nothing to push)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                return ActionResult(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var pushedItems: [Item] = []
        var lastPushedItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    return ActionResult(
                        engine.messenger.thatsNotSomethingYouCan(.push)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if player can reach the item
                    guard await engine.playerCanReach(targetItemID) else {
                        continue  // Skip unreachable items in ALL commands
                    }
                }

                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Set `.isTouched` flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                pushedItems.append(targetItem)
                lastPushedItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastPushedItem {
            if pushedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: pushedItems
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
            if pushedItems.isEmpty {
                command.isAllCommand
                    ? engine.messenger.nothingHereToPush()
                    : engine.messenger.doWhat(verb: command.verb)
            } else {
                engine.messenger.pushSuccess(items: pushedItems.listWithDefiniteArticles)
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
