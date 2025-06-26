import Foundation

/// Handles the "TAKE" command and its synonyms (e.g., "GET"), allowing the player to pick up
/// an item and add it to their inventory.
public struct TakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.pick, .up, .directObjects),
        .match(.verb, .directObjects, .from, .indirectObject),
    ]

    public let verbs: [Verb] = [.take, .get, .grab, .steal]

    public let actions: [Intent] = [.take]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TAKE" command.
    ///
    /// This action validates prerequisites and moves the specified item(s) to the player's inventory.
    /// Handles both single items and ALL commands with appropriate validation and messaging.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to take)
        if !command.isAllCommand {
            guard command.directObjects.isNotEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var takenItems: [Item] = []
        var lastTakenItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.take)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // If this is a "take X from Y" command, validate the indirect object
                if let indirectObjectRef = command.indirectObject {
                    guard case .item(let containerID) = indirectObjectRef else {
                        throw ActionResponse.prerequisiteNotMet(
                            engine.messenger.thatsNotSomethingYouCan(.take)
                        )
                    }

                    let container = try await engine.item(containerID)

                    // Check if the target item is actually in the specified container
                    guard case .item(let actualParentID) = targetItem.parent,
                        actualParentID == containerID
                    else {
                        throw ActionResponse.prerequisiteNotMet(
                            engine.messenger.takeItemNotInContainer(
                                item: targetItem.withDefiniteArticle,
                                container: container.withDefiniteArticle
                            )
                        )
                    }
                }

                // Check if player already has this item
                if targetItem.parent == .player {
                    if command.isAllCommand {
                        continue  // Skip items already held in ALL commands
                    } else {
                        return ActionResult(
                            engine.messenger.youAlreadyHaveThat()
                        )
                    }
                }

                // Validate this specific item for ALL commands
                if command.isAllCommand {
                    // Check if item is takable
                    guard targetItem.hasFlag(.isTakable) else {
                        continue  // Skip non-takable items in ALL commands
                    }

                    // Check if player can reach the item
                    guard await engine.playerCanReach(targetItemID) else {
                        continue  // Skip unreachable items in ALL commands
                    }

                    // Check capacity
                    guard await engine.playerCanCarry(targetItem) else {
                        if takenItems.isEmpty {
                            return ActionResult(
                                engine.messenger.playerCannotCarryMore()
                            )
                        }
                        break  // Stop processing if capacity is exceeded
                    }
                } else {
                    // For single item commands, perform full validation

                    // Check if item is inside something invalid (non-container/non-surface)
                    if case .item(let parentID) = targetItem.parent {
                        let parentItem = try await engine.item(parentID)

                        // Fail only if the parent is NOT a container and NOT a surface
                        guard parentItem.hasFlag(.isContainer) || parentItem.hasFlag(.isSurface)
                        else {
                            throw ActionResponse.prerequisiteNotMet(
                                engine.messenger.takeItemFromNonContainer(
                                    nonContainer: parentItem.withDefiniteArticle
                                )
                            )
                        }
                    }

                    // Handle specific container closed errors before general unreachability
                    if case .item(let parentID) = targetItem.parent {
                        let container = try await engine.item(parentID)
                        if container.hasFlag(.isContainer) && !container.hasFlag(.isOpen) {
                            if targetItem.hasFlag(.isTouched) || container.hasFlag(.isTransparent) {
                                throw ActionResponse.containerIsClosed(parentID)
                            } else {
                                throw ActionResponse.itemNotAccessible(targetItemID)
                            }
                        }
                    }

                    // Check reachability using ScopeResolver (general check)
                    guard await engine.playerCanReach(targetItemID) else {
                        throw ActionResponse.itemNotAccessible(targetItemID)
                    }

                    // Check if the item is takable
                    guard targetItem.hasFlag(.isTakable) else {
                        throw ActionResponse.itemNotTakable(targetItemID)
                    }

                    // Check capacity
                    guard await engine.playerCanCarry(targetItem) else {
                        throw ActionResponse.playerCannotCarryMore
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Move item to player
                let moveChange = await engine.move(targetItem, to: .player)
                itemStateChanges.append(moveChange)

                // Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                takenItems.append(targetItem)
                lastTakenItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastTakenItem {
            if takenItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: takenItems
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
                if takenItems.isEmpty {
                    engine.messenger.thereIsNothingHereToTake()
                } else {
                    engine.messenger.youTakeMultipleItems(
                        items: takenItems.listWithDefiniteArticles
                    )
                }
            } else {
                engine.messenger.taken()
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
