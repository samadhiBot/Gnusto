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

    public init() {}

    /// Processes the "PUSH" command.
    ///
    /// This action validates prerequisites and handles pushing objects. Provides feedback
    /// for each item pushed and updates touched flags appropriately.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to push)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.prerequisiteNotMet(
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
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.push)
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
