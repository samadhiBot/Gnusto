import Foundation

/// Handles the "EXAMINE" command and its synonyms (e.g., "LOOK AT", "DESCRIBE"), providing
/// a detailed description of a specified item or the player.
public struct ExamineActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.verb, .on, .directObjects),
        .match(.look, .at, .directObjects),
        .match(.look, .through, .directObject),
    ]

    public let synonyms: [Verb] = [.examine, .x, .inspect, .describe, .look, .l]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EXAMINE" command.
    ///
    /// This action validates prerequisites and provides detailed descriptions of the specified
    /// item(s) or the player. Handles both single items and ALL commands with appropriate
    /// validation and messaging.
    public func process(context: ActionContext) async throws -> ActionResult {
        // For ALL commands, empty directObjects is valid (means nothing to examine)
        guard context.command.directObjects.isNotEmpty || context.command.isAllCommand else {
            throw ActionResponse.doWhat(context)
        }

        var allStateChanges = [StateChange]()
        var messages = [String]()
        var examinedItems: [ItemProxy] = []

        func addMessage(_ name: String, _ description: String) {
            messages.append(
                context.command.directObjects.count > 1
                    ? "\(name.capitalizedFirst): \(description)" : description
            )
        }

        // Process each object individually
        for directObjectRef in context.command.directObjects {
            switch directObjectRef {
            case .item(let item):
                // Check if player can reach the item
                guard await item.playerCanReach else {
                    if context.command.isAllCommand { continue }

                    // For single item commands, perform full validation
                    throw ActionResponse.itemNotAccessible(item)
                }

                await addMessage(
                    item.name,
                    examineItem(item)
                )
                await allStateChanges.appendIfPresent(
                    item.setFlag(.isTouched)
                )
                examinedItems.append(item)

            case .location(let location):
                await addMessage(
                    location.name,
                    location.description,
                )

            case .player:
                let healthRatio =
                    await Double(context.player.health) / Double(context.player.maxHealth)
                addMessage(
                    context.msg.you(),
                    context.msg.examineYourself(healthRatio: healthRatio)
                )

            case .universal(let universal):
                addMessage(
                    universal.withDefiniteArticle,
                    context.msg.nothingSpecialAbout(universal.withDefiniteArticle)
                )
            }
        }

        // Generate appropriate message
        let finalMessage =
            switch messages.count {
            case 0: context.msg.nothingHereToDo(context.command)
            case 1: messages[0]
            default: "- \(messages.sorted().joined(separator: "\n- "))"
            }

        return ActionResult(
            message: finalMessage,
            changes: allStateChanges
        )
    }
}

extension ExamineActionHandler {
    func examineItem(_ targetItem: ItemProxy) async -> String {
        var messages = [String]()

        // Check if item has an explicit description (not just the default "nothing special" message)
        let hasExplicitDescription = await targetItem.property(.description) != nil

        // For containers and surfaces without explicit descriptions, skip the default message
        let isContainer = await targetItem.isContainer
        let isSurface = await targetItem.hasFlag(.isSurface)
        let isContainerOrSurface = isContainer || isSurface

        if hasExplicitDescription || !isContainerOrSurface {
            messages.append(await targetItem.description)
        }

        if await targetItem.hasFlag(.isSurface) {
            await messages.appendIfPresent(
                describeSurface(item: targetItem)
            )
        } else if await targetItem.isContainer {
            await messages.appendIfPresent(
                describeContainer(item: targetItem)
            )
        } else if await targetItem.isDoor {
            await messages.append(
                describeDoor(item: targetItem)
            )
        }

        return messages.joined(separator: " ")
    }

    private func describeContainer(item: ItemProxy) async -> String? {
        var messages = [String]()
        let isOpen = await item.hasFlag(.isOpen)
        let isTransparent = await item.hasFlag(.isTransparent)
        let msg = item.engine.messenger

        // Only show closed status for non-transparent containers
        if !isOpen && !isTransparent {
            await messages.append(
                msg.containerIsClosed(item.withDefiniteArticle)
            )
        }

        guard isOpen || isTransparent else {
            return messages[0]
        }

        let itemsInside = await item.contents

        if itemsInside.isEmpty {
            await messages.append(
                msg.containerIsEmpty(item.withDefiniteArticle)
            )
        } else {
            await messages.append(
                msg.containerContents(
                    item.withDefiniteArticle,
                    contents: itemsInside.listWithIndefiniteArticles() ?? ""
                )
            )
        }

        return messages.joined(separator: " ")
    }

    private func describeDoor(item: ItemProxy) async -> String {
        let msg = item.engine.messenger

        return if await item.hasFlag(.isOpen) {
            await msg.doorIsOpen(item.withDefiniteArticle)
        } else if await item.hasFlag(.isLocked) {
            await msg.doorIsLocked(item.withDefiniteArticle)
        } else {
            await msg.doorIsClosed(item.withDefiniteArticle)
        }
    }

    private func describeSurface(item: ItemProxy) async -> String? {
        let itemsOnSurface = await item.contents
        var itemsToDescribe = [ItemProxy]()
        var messages = [String]()

        for surfaceItem in itemsOnSurface.sorted() {
            if let firstDescription = await surfaceItem.firstDescription {
                messages.append(firstDescription)

                // If this item is a container with contents, also describe its contents
                // But only if the container is open or transparent
                if await surfaceItem.isContainer {
                    let isOpen = await surfaceItem.hasFlag(.isOpen)
                    let isTransparent = await surfaceItem.hasFlag(.isTransparent)

                    if isOpen || isTransparent {
                        if let containerDescription = await describeContainer(item: surfaceItem)
                        {
                            messages.append(containerDescription)
                        }
                    }
                }
            } else {
                itemsToDescribe.append(surfaceItem)
            }
        }

        if itemsToDescribe.isNotEmpty {
            await messages.append(
                item.engine.messenger.surfaceContents(
                    item.withDefiniteArticle,
                    contents: itemsToDescribe.listWithIndefiniteArticles() ?? ""
                )
            )
        }

        return messages.isEmpty ? nil : messages.joined(separator: " ")
    }
}
