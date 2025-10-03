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

    public let synonyms: [Verb] = [.take, .get, .grab, .steal]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TAKE" command.
    ///
    /// This action validates prerequisites and moves the specified item(s) to the player's inventory.
    /// Handles both single items and ALL commands with appropriate validation and messaging.
    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Get items based on command type
        let items: [ItemProxy]
        if context.command.isAllCommand {
            let allLocationItems = await context.player.location.items

            // Collect all accessible items: direct location items + items on surfaces
            var accessibleItems: [ItemProxy] = []

            for locationItem in allLocationItems {
                // Add items directly in location
                accessibleItems.append(locationItem)

                // If this item is a surface, add items on it
                if await locationItem.hasFlag(.isSurface) {
                    let itemsOnSurface = await locationItem.contents
                    accessibleItems.append(contentsOf: itemsOnSurface)
                }
            }

            let filteredItems = await accessibleItems.asyncFilter { item in
                // Must be takable
                await item.isTakable
            }
            items = filteredItems
        } else {
            items = try await context.itemDirectObjects()
        }

        // For single item commands, ensure we have at least one direct object
        guard items.isNotEmpty else {
            throw ActionResponse.doWhat(context)
        }

        var allStateChanges = [StateChange]()
        var takenItems = [ItemProxy]()
        var cumulativeSize = 0  // Track total size of items being taken in this command

        // Process each item individually
        for item in items.sorted() {
            do {
                if let container = try await context.itemIndirectObject(),
                    await item.parent != .item(container)
                {
                    throw ActionResponse.feedback(
                        context.msg.takeItemNotInContainer(
                            await item.withDefiniteArticle,
                            container: await container.withDefiniteArticle
                        )
                    )
                }

                // Check if player already has this item
                if await item.playerIsHolding {
                    throw ActionResponse.feedback(
                        context.msg.youAlreadyHaveThat()
                    )
                }

                // Validate this specific item for ALL commands
                if context.command.isAllCommand {
                    // Check if item is takable
                    guard await item.hasFlag(.isTakable) else {
                        continue  // Skip non-takable items in ALL commands
                    }

                    // Check if player can reach the item
                    guard await item.playerCanReach else {
                        continue  // Skip unreachable items in ALL commands
                    }

                    // Check capacity considering cumulative size of items being taken
                    var currentLoad = 0
                    for inventoryItem in await context.player.completeInventory {
                        currentLoad += await inventoryItem.size
                    }
                    let itemSize = await item.size
                    let playerCapacity = await context.player.carryingCapacity
                    let totalWithThisItem = currentLoad + cumulativeSize + itemSize

                    guard totalWithThisItem <= playerCapacity else {
                        if takenItems.isEmpty {
                            throw ActionResponse.feedback(
                                context.msg.playerCannotCarryMore()
                            )
                        }
                        continue  // Skip this item if capacity would be exceeded, but continue with other items
                    }

                    // Add this item's size to the cumulative total
                    cumulativeSize += itemSize

                } else {  // For single item commands, perform full validation

                    // Check if item is inside something invalid (non-container/non-surface)
                    let itemParent = await item.parent

                    if case .item(let container) = itemParent,
                        await container.hasFlags(all: .isContainer, none: .isOpen)
                    {
                        if await item.hasFlags(any: .isTouched, .isTransparent) {
                            throw ActionResponse.containerIsClosed(container)
                        } else {
                            throw ActionResponse.itemNotAccessible(item)
                        }
                    }

                    // Check reachability using ScopeResolver (general check)
                    guard await item.playerCanReach else {
                        throw ActionResponse.itemNotAccessible(item)
                    }

                    // Check if the item is takable
                    guard await item.hasFlag(.isTakable) else {
                        throw ActionResponse.cannotDo(context, item)
                    }

                    // Check capacity
                    guard await item.playerCanCarry else {
                        throw ActionResponse.playerCannotCarryMore
                    }
                }

                // Create state changes for this item
                var itemStateChanges = [StateChange]()

                // Move item to player
                let moveChange = item.move(to: .player)
                itemStateChanges.append(moveChange)

                // Set .isTouched flag if not already set
                await itemStateChanges.appendIfPresent(
                    item.setFlag(.isTouched)
                )

                allStateChanges.append(contentsOf: itemStateChanges)
                takenItems.append(item)

            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Generate appropriate message
        let message =
            if context.command.isAllCommand {
                if takenItems.isEmpty {
                    context.msg.nothingToTakeHere()
                } else {
                    await context.msg.youDoMultipleItems(
                        context.command,
                        items: takenItems
                    )
                }
            } else if takenItems.count > 1 {
                await context.msg.youDoMultipleItems(
                    context.command,
                    items: takenItems
                )
            } else {
                context.msg.taken()
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
