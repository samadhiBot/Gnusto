import Foundation

/// Handles the "PULL" command for pulling objects.
/// Implements pulling mechanics following ZIL patterns, as a complement to PUSH.
public struct PullActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let verbs: [VerbID] = [.pull]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "PULL" command.
    ///
    /// This action validates prerequisites and handles pulling objects. Most objects cannot
    /// be pulled effectively, but some specific items may have special pull behavior.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to pull)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var pulledItems: [Item] = []
        var lastPulledItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.pull)
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
                pulledItems.append(targetItem)
                lastPulledItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastPulledItem {
            if pulledItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: pulledItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }

        // Generate appropriate message based on whether items are pullable
//        let message =
//            if pulledItems.isEmpty {
//                command.isAllCommand
//                    ? engine.messenger.nothingHereToPull()
//                    : engine.messenger.doWhat(verb: command.verb)
//            } else if pulledItems.count == 1 {
//                let item = pulledItems[0]
//                if item.hasFlag(.isPullable) {
//                    engine.messenger.pullSuccess(item: item.withDefiniteArticle)
//                } else {
//                    engine.messenger.cannotDoThat(
//                        verb: .pull,
//                        item: item.withDefiniteArticle
//                    )
//                }
//            } else {
//                // Multiple items - provide general response
//                engine.messenger.pullMultipleItems(items: pulledItems.listWithDefiniteArticles)
//            }
        let message = "🤡 `pull` placeholder for \(pulledItems.listWithDefiniteArticles)"

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
