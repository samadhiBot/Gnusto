import Foundation

/// Handles the "INSERT <direct object> INTO/IN <indirect object>" command, allowing the player
/// to place an item they are holding into an open container item.
public struct InsertActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects, .in, .indirectObject),
        .match(.verb, .directObjects, .inside, .indirectObject),
        .match(.verb, .directObjects, .into, .indirectObject),
    ]

    public let verbs: [Verb] = [.insert, .put, .place]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "INSERT ... INTO/IN" command.
    ///
    /// This action validates prerequisites and handles placing items into containers.
    /// Supports both single items and ALL commands with comprehensive validation.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Get the container from indirect object
        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let containerID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.insert)
            )
        }

        // Validate container exists and is accessible
        let container = try await engine.item(containerID)
        guard await engine.playerCanReach(containerID) else {
            throw ActionResponse.itemNotAccessible(containerID)
        }

        // Check if target is a container
        guard container.hasFlag(.isContainer) else {
            throw ActionResponse.targetIsNotAContainer(containerID)
        }

        // Check if container is open
        guard try await engine.hasFlag(.isOpen, on: containerID) else {
            throw ActionResponse.containerIsClosed(containerID)
        }

        // For ALL commands, empty directObjects is valid (means nothing to insert)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var insertedItems: [Item] = []
        var lastInsertedItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let itemToInsertID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.insert)
                    )
                }
            }

            do {
                let itemToInsert = try await engine.item(itemToInsertID)

                // Check if player is holding this item
                guard itemToInsert.parent == .player else {
                    if command.isAllCommand {
                        continue  // Skip items not held in ALL commands
                    } else {
                        throw ActionResponse.itemNotHeld(itemToInsertID)
                    }
                }

                // Check if item is scenery (fixed, unmovable items)
                if itemToInsert.hasFlag(.omitDescription) {
                    if command.isAllCommand {
                        continue  // Skip scenery items in ALL commands
                    } else {
                        throw ActionResponse.targetIsNotAContainer(itemToInsertID)
                    }
                }

                // Prevent putting item inside itself
                if itemToInsertID == containerID {
                    if command.isAllCommand {
                        continue  // Skip self-insertion in ALL commands
                    } else {
                        throw ActionResponse.prerequisiteNotMet(
                            engine.messenger.cannotPutItemInItself(
                                item: itemToInsert.withDefiniteArticle)
                        )
                    }
                }

                // Recursive check: is the target container inside the item we are inserting?
                var currentParent = container.parent
                var isCircular = false
                while case .item(let parentItemID) = currentParent {
                    if parentItemID == itemToInsertID {
                        isCircular = true
                        break
                    }
                    let parentItem = try await engine.item(parentItemID)
                    currentParent = parentItem.parent
                }
                if isCircular {
                    if command.isAllCommand {
                        continue  // Skip circular placement in ALL commands
                    } else {
                        throw ActionResponse.prerequisiteNotMet(
                            engine.messenger.cannotPutContainerInContained(
                                parent: itemToInsert.withDefiniteArticle,
                                child: container.withDefiniteArticle
                            )
                        )
                    }
                }

                // Capacity Check
                if container.capacity >= 0 {
                    let itemsInside = await engine.items(in: .item(containerID))
                    let currentLoad = itemsInside.reduce(0) { $0 + $1.size }
                    let itemSize = itemToInsert.size
                    if currentLoad + itemSize > container.capacity {
                        if command.isAllCommand {
                            continue  // Skip items that won't fit in ALL commands
                        } else {
                            throw ActionResponse.itemTooLargeForContainer(
                                item: itemToInsertID,
                                container: containerID
                            )
                        }
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Move item to container
                let moveChange = await engine.move(itemToInsert, to: .item(containerID))
                itemStateChanges.append(moveChange)

                // Mark item touched
                if let touchedChange = await engine.setFlag(.isTouched, on: itemToInsert) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                insertedItems.append(itemToInsert)
                lastInsertedItem = itemToInsert

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Mark container touched if any items were inserted
        if !insertedItems.isEmpty {
            if let containerTouchedChange = await engine.setFlag(.isTouched, on: container) {
                allStateChanges.append(containerTouchedChange)
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastInsertedItem {
            if insertedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: insertedItems
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
            if insertedItems.isEmpty {
                command.isAllCommand
                    ? engine.messenger.youHaveNothingToPutIn(
                        container: container.withDefiniteArticle
                    ) : engine.messenger.doWhat(verb: command.verb)
            } else {
                engine.messenger.youPutItemInContainer(
                    item: insertedItems.listWithDefiniteArticles,
                    container: container.withDefiniteArticle
                )
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
