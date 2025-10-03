import Foundation

/// Handles the "REMOVE" command and its synonyms (e.g., "DOFF", "TAKE OFF"), allowing the
/// player to unequip an item they are currently wearing.
public struct RemoveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.take, .off, .directObject),
    ]

    public let synonyms: [Verb] = [.remove, .doff]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "REMOVE" command.
    ///
    /// This action validates prerequisites and handles removing worn items.
    /// Checks that items exist, are currently worn, and are removable.
    /// Supports both single items and ALL commands.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to remove)
        guard context.command.directObjects.isNotEmpty || context.command.isAllCommand else {
            throw ActionResponse.doWhat(context)
        }

        var allStateChanges = [StateChange]()
        var removedItems: [ItemProxy] = []

        // Process each object individually
        for directObjectRef in context.command.directObjects {
            do {
                switch directObjectRef {
                case .item(let item):
                    // Check if player can reach the item
                    guard await item.playerCanReach else {
                        throw ActionResponse.itemNotAccessible(item)
                    }

                    // If item is not held, hand off to TakeActionHandler
                    guard await context.player.isHolding(item.id) else {
                        let takeHandler = TakeActionHandler()
                        return try await takeHandler.process(context: context)
                    }

                    // Check if item is currently worn
                    guard await item.hasFlag(.isWorn) else {
                        throw await ActionResponse.feedback(
                            context.msg.itemIsNotWorn(item.withDefiniteArticle)
                        )
                    }

                    // Check if item is removable (not fixed scenery)
                    guard !(await item.hasFlag(.omitDescription)) else {
                        throw ActionResponse.cannotDo(context, item)
                    }

                    // Create state changes for this item
                    await allStateChanges.appendIfPresent(
                        item.clearFlag(.isWorn)
                    )
                    await allStateChanges.appendIfPresent(
                        item.setFlag(.isTouched)
                    )

                    removedItems.append(item)

                case .player, .location, .universal:
                    throw ActionResponse.feedback(
                        context.msg.thatsNotSomethingYouCan(context.command)
                    )
                }
            } catch {
                if context.command.isAllCommand { continue }
                throw error
            }
        }

        // Generate appropriate message
        let message: String
        if removedItems.isEmpty {
            message = context.msg.removeAll()
        } else {
            message = await context.msg.youDoMultipleItems(
                context.command,
                items: removedItems
            )
        }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
