import Foundation

/// Handles the "INSERT <direct object> INTO/IN <indirect object>" command, allowing the player
/// to place an item they are holding into an open container item.
public struct InsertActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.insert, .directObjects),
        .match(.verb, .directObjects, .in, .indirectObject),
        .match(.verb, .directObjects, .inside, .indirectObject),
        .match(.verb, .directObjects, .into, .indirectObject),
    ]

    public let synonyms: [Verb] = [.insert, .put, .place]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "INSERT ... INTO/IN" command.
    ///
    /// This action validates prerequisites and handles placing items into containers.
    /// Supports both single items and ALL commands with comprehensive validation.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get the container from indirect object
        guard let container = try await context.itemIndirectObject() else {
            // If we have a direct object, use it in the error message
            if let item = try await context.itemDirectObjects().first {
                throw await ActionResponse.feedback(
                    context.msg.doWhere(
                        context.command.verb,
                        item: item.withDefiniteArticle
                    )
                )
            } else {
                throw ActionResponse.doWhat(context)
            }
        }

        // Check if target is a container
        guard await container.isContainer else {
            throw ActionResponse.targetIsNotAContainer(container)
        }

        // Check if container is open
        guard await container.isOpen else {
            throw ActionResponse.containerIsClosed(container)
        }

        // For ALL commands, empty directObjects is valid (means nothing to insert)
        let itemsToInsert = try await context.itemDirectObjects()
        var allStateChanges = [StateChange]()
        var insertedItems = [ItemProxy]()

        // Process each object individually
        for itemToInsert in itemsToInsert {
            do {
                // Check if player is holding this item
                guard await itemToInsert.playerIsHolding else {
                    throw ActionResponse.itemNotHeld(itemToInsert)
                }

                // Check if item is scenery (fixed, unmovable items)
                if await itemToInsert.hasFlag(.omitDescription) {
                    throw ActionResponse.cannotDo(context, itemToInsert)
                }

                // Prevent putting item inside itself
                if itemToInsert == container {
                    throw await ActionResponse.feedback(
                        context.msg.cannotPutItemInItself(
                            itemToInsert.withDefiniteArticle
                        )
                    )
                }

                // Recursive check: is the target container inside the item we are inserting?
                var currentParent = await container.parent
                var isCircular = false
                while case .item(let parentProxy) = currentParent {
                    if parentProxy == itemToInsert {
                        isCircular = true
                        break
                    }
                    currentParent = await parentProxy.parent
                }

                if isCircular {
                    throw await ActionResponse.feedback(
                        context.msg.cannotPutContainerInContained(
                            itemToInsert.withDefiniteArticle,
                            child: container.withDefiniteArticle
                        )
                    )
                }

                // Capacity Check
                if await !container.canHold(itemToInsert.id) {
                    if context.command.isAllCommand {
                        continue  // Skip items that won't fit in ALL commands
                    } else {
                        throw await ActionResponse.feedback(
                            context.msg.itemTooLargeForContainer(
                                itemToInsert.withDefiniteArticle,
                                container: container.withDefiniteArticle
                            )
                        )
                    }
                }

                // Create state changes for this item
                var itemStateChanges = [StateChange]()

                // Move item to container
                let moveChange = itemToInsert.move(to: .item(container.id))
                itemStateChanges.append(moveChange)

                // Mark item touched
                if let touchedChange = await itemToInsert.setFlag(.isTouched) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                insertedItems.append(itemToInsert)
            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Mark container touched if any items were inserted
        if insertedItems.isNotEmpty {
            await allStateChanges.append(
                container.setFlag(.isTouched)
            )
        }

        // Generate appropriate message
        let message =
            if insertedItems.isEmpty {
                context.command.isAllCommand
                    ? context.msg.youHaveNothingToPutIn(
                        await container.withDefiniteArticle
                    ) : context.msg.doWhat(context.command)
            } else {
                context.msg.youPutItemInContainer(
                    await insertedItems.listWithDefiniteArticles() ?? "",
                    container: await container.withDefiniteArticle
                )
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
