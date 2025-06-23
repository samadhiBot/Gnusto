import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET"), allowing the player to pick up
/// an item and add it to their inventory.
public struct TakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .take

    public let syntax: [SyntaxRule] = [
        SyntaxRule(
            pattern: [.verb, .directObject],
            directObjectConditions: .allowsMultiple
        ),
        SyntaxRule(
            pattern: [.verb, .directObject, .from, .indirectObject],
            directObjectConditions: .allowsMultiple
        )
    ]

    public let synonyms: [String] = ["get", "grab", "pick"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "TAKE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to take).
    /// 2. The direct object refers to an existing item.
    /// 3. If the item is inside another item, that parent item must be a container or surface.
    ///    It prevents taking items from non-container/non-surface parents.
    /// 4. If the item is inside a container, and that container is closed and not transparent,
    ///    and the target item hasn't been touched (implying player knows it's there), an error
    ///    for a closed container or general inaccessibility is thrown.
    /// 5. The player can reach the item (general reachability check).
    /// 6. The item has the `.isTakable` flag set.
    /// 7. The player has enough carrying capacity for the item.
    ///
    /// Note: It explicitly *does not* throw an error if the player already has the item;
    /// this case is handled gracefully in the `process` method with a specific message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `prerequisiteNotMet`, `unknownEntity`, `itemNotAccessible`, `itemNotTakable`,
    ///           `containerIsClosed`, or `playerCannotCarryMore`.
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
        // For ALL commands, allow empty directObjects (handled in process method)
        if context.command.isAllCommand {
            return
        }

        // 1. Ensure we have at least one direct object for non-ALL commands
        guard !context.command.directObjects.isEmpty else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .take)
            )
        }

        // For single object commands, validate the single object
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .take)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.thatsNotSomethingYouCan(.take)
            )
        }

        // 2. Check if item exists
        let targetItem = try await context.engine.item(targetItemID)

        // 3. If this is a "take X from Y" command, validate the indirect object
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let containerID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.thatsNotSomethingYouCan(.take)
                )
            }

            let container = try await context.engine.item(containerID)

            // Check if the target item is actually in the specified container
            guard case .item(let actualParentID) = targetItem.parent,
                actualParentID == containerID
            else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.takeItemNotInContainer(
                        item: targetItem.withDefiniteArticle,
                        container: container.withDefiniteArticle
                    )
                )
            }
        }

        // 4. Check if player already has the item
        if targetItem.parent == .player {
            // Can't throw error here, need to report specific message.
            // Let process handle returning a specific ActionResult for this.
            // This validation passes if already held, process generates the message.
            return
        }

        // 5. Check if item is inside something invalid (non-container/non-surface)
        if case .item(let parentID) = targetItem.parent {
            let parentItem = try await context.engine.item(parentID)

            // Fail only if the parent is NOT a container and NOT a surface.
            // We allow taking from *closed* containers here; reachability handles closed state later.
            guard parentItem.hasFlag(.isContainer) || parentItem.hasFlag(.isSurface) else {
                // Custom message similar to Zork's, using the plain name.
                throw ActionResponse.prerequisiteNotMet(
                    context.message.takeItemFromNonContainer(
                        nonContainer: parentItem.withDefiniteArticle
                    )
                )
            }
        }

        // 6. Handle specific container closed errors before general unreachability
        if case .item(let parentID) = targetItem.parent {
            let container = try await context.engine.item(parentID)
            if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                    throw ActionResponse.containerIsClosed(parentID)
                } else {
                    throw ActionResponse.itemNotAccessible(targetItemID)
                }
            }
        }

        // 7. Check reachability using ScopeResolver (general check)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 8. Check if the item is takable
        guard targetItem.hasFlag(.isTakable) else {
            throw ActionResponse.itemNotTakable(targetItemID)
        }

        // 9. Check capacity
        guard await context.engine.playerCanCarry(targetItem) else {
            throw ActionResponse.playerCannotCarryMore
        }
    }

    /// Processes the "TAKE" command.
    ///
    /// Assuming basic validation has passed, this action performs the following:
    /// 1. Retrieves the target item(s).
    /// 2. For each item, checks if the player already has it. If so, a message "You already have that."
    ///    is returned.
    /// 3. If the player does not have the item:
    ///    a. Creates a `StateChange` to move the item to the player's inventory (`.player` parent).
    ///    b. Ensures the `.isTouched` flag is set on the item.
    ///    c. Updates pronouns to refer to the taken item.
    ///    d. Returns a confirmation message, typically "Taken."
    ///
    /// For ALL commands, processes each object individually and provides consolidated feedback.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a message and any relevant `StateChange`s.
    /// - Throws: `ActionResponse.internalEngineError` if direct object is not an item (should be
    ///           caught by validate), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to take)
        if !context.command.isAllCommand {
            guard !context.command.directObjects.isEmpty else {
                throw ActionResponse.internalEngineError(
                    context.message.internalEngineError()
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var messages: [String] = []
        var takenItems: [Item] = []
        var lastTakenItem: Item?

        // Process each object individually
        for directObjectRef in context.command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if context.command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.internalEngineError(
                        context.message.internalEngineError()
                    )
                }
            }

            do {
                let targetItem = try await context.engine.item(targetItemID)

                // Check if player already has this item
                if targetItem.parent == .player {
                    if context.command.isAllCommand {
                        continue  // Skip items already held in ALL commands
                    } else {
                        return ActionResult(
                            context.message.youAlreadyHaveThat()
                        )
                    }
                }

                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if item is takable
                    guard targetItem.hasFlag(.isTakable) else {
                        continue  // Skip non-takable items in ALL commands
                    }

                    // Check if player can reach the item
                    guard await context.engine.playerCanReach(targetItemID) else {
                        continue  // Skip unreachable items in ALL commands
                    }

                    // Check capacity
                    guard await context.engine.playerCanCarry(targetItem) else {
                        if takenItems.isEmpty {
                            messages.append(
                                context.message.playerCannotCarryMore()
                            )
                        }
                        break  // Stop processing if capacity is exceeded
                    }
                }

                // --- Calculate State Changes for this item ---
                var itemStateChanges: [StateChange] = []

                // Change 1: Parent
                let moveChange = await context.engine.move(targetItem, to: .player)
                itemStateChanges.append(moveChange)

                // Change 2: Set `.isTouched` flag if not already set
                if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                takenItems.append(targetItem)
                lastTakenItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastTakenItem {
            if takenItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await context.engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: takenItems
                )
                allStateChanges.append(contentsOf: pronounChanges)
            } else {
                // For single item, use the original method
                if let pronounChange = await context.engine.updatePronouns(to: lastItem) {
                    allStateChanges.append(pronounChange)
                }
            }
        }

        // Generate appropriate message
        let message =
            if context.command.isAllCommand {
                if takenItems.isEmpty {
                    context.message.thereIsNothingHereToTake()
                } else {
                    context.message.youTakeMultipleItems(
                        items: takenItems.listWithDefiniteArticles
                    )
                }
            } else {
                context.message.taken()
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
