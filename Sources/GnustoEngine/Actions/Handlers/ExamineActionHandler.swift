import Foundation

/// Handles the "EXAMINE" command and its synonyms (e.g., "LOOK AT", "DESCRIBE"), providing
/// a detailed description of a specified item or the player.
public struct ExamineActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects),
        .match(.look, .at, .directObjects),
    ]

    public let verbs: [VerbID] = [.examine, "x", .inspect]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EXAMINE" command.
    ///
    /// This action validates prerequisites and provides detailed descriptions of the specified
    /// item(s) or the player. Handles both single items and ALL commands with appropriate
    /// validation and messaging.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Check for EXAMINE IN/ON preposition variants - delegate to look-inside behavior
        if command.preposition == "in" || command.preposition == "on" {
            let lookInsideHandler = LookInsideActionHandler()
            return try await lookInsideHandler.process(command: command, engine: engine)
        }

        // For ALL commands, empty directObjects is valid (means nothing to examine)
        if !command.isAllCommand {
            guard !command.directObjects.isEmpty else {
                throw ActionResponse.custom(engine.messenger.doWhat(verb: command.verb))
            }
        }

        var allStateChanges: [StateChange] = []
        var messages: [String] = []
        var examinedItems: [Item] = []

        // Process each object individually
//        for directObjectRef in command.directObjects {
//            switch directObjectRef {
//            case .item(let targetItemID):
//                do {
//                    let targetItem = try await engine.item(targetItemID)
//
//                    // Validate this specific item for ALL commands
//                    if command.isAllCommand {
//                        // Check if player can reach the item
//                        guard await engine.playerCanReach(targetItemID) else {
//                            continue  // Skip unreachable items in ALL commands
//                        }
//                    } else {
//                        // For single item commands, perform full validation
//                        guard await engine.playerCanReach(targetItemID) else {
//                            throw ActionResponse.itemNotAccessible(targetItemID)
//                        }
//                    }
//
//                    var itemStateChanges: [StateChange] = []
//
//                    // Special case: examining 'self' as an item should not record any state changes
//                    if targetItem.id != "self" {
//                        // Mark as touched
//                        if let update = await engine.setFlag(.isTouched, on: targetItem) {
//                            itemStateChanges.append(update)
//                        }
//                        // Note: Pronoun updates are handled after processing all items
//                    }
//
//                    // Determine message
//                    var itemMessages = [String]()
//
//                    // Priority 1: Readable Text (Check dynamic value)
//                    if targetItem.hasFlag(.isReadable),
//                        let readText: String = try? await engine.attribute(
//                            .readText, of: targetItem.id),
//                        !readText.isEmpty
//                    {
//                        itemMessages.append(readText)
//                    }
//
//                    // Smart handling for items that are both containers and surfaces
//                    if targetItem.hasFlag(.isContainer) && targetItem.hasFlag(.isSurface) {
//                        // Check if surface items have meaningful firstDescriptions
//                        let contents = await engine.items(in: .item(targetItem.id))
//                        let hasFirstDescriptions = contents.contains { item in
//                            if let firstDescription = item.attributes[.firstDescription],
//                                case .string(let description) = firstDescription,
//                                !description.isEmpty
//                            {
//                                return true
//                            }
//                            return false
//                        }
//
//                        if hasFirstDescriptions {
//                            // Prefer surface description when items have first descriptions
//                            let surfaceDescription = try await describeSurface(
//                                targetItem: targetItem,
//                                engine: engine
//                            )
//                            itemMessages.append(surfaceDescription)
//                        } else {
//                            // Use container description when no meaningful surface descriptions
//                            let containerDescription = try await describeContainerOrDoor(
//                                targetItem: targetItem,
//                                engine: engine
//                            )
//                            itemMessages.append(containerDescription)
//                        }
//                    }
//                    // Priority 2: Container/Door Description
//                    else if targetItem.hasFlag(.isContainer) || targetItem.hasFlag(.isDoor) {
//                        let containerDescription = try await describeContainerOrDoor(
//                            targetItem: targetItem,
//                            engine: engine
//                        )
//                        itemMessages.append(containerDescription)
//                    }
//                    // Priority 3: Surface Description
//                    else if targetItem.hasFlag(.isSurface) {
//                        let surfaceDescription = try await describeSurface(
//                            targetItem: targetItem,
//                            engine: engine
//                        )
//                        itemMessages.append(surfaceDescription)
//                    }
//                    // Priority 4: Standard Description
//                    else {
//                        let standardDescription = await engine.longDescription(of: targetItem.id)
//                        itemMessages.append(standardDescription)
//                    }
//
//                    allStateChanges.append(contentsOf: itemStateChanges)
//                    messages.append(contentsOf: itemMessages)
//                    examinedItems.append(targetItem)
//
//                } catch {
//                    // For ALL commands, skip items that cause errors
//                    if !command.isAllCommand {
//                        throw error
//                    }
//                }
//
//            case .player:
//                // Handle examining self
//                messages.append(engine.messenger.lookAtSelf())
//
//            default:
//                if command.isAllCommand {
//                    continue  // Skip non-items/non-player in ALL commands
//                } else {
//                    throw ActionResponse.prerequisiteNotMet(
//                        engine.messenger.thatsNotSomethingYouCan(.examine)
//                    )
//                }
//            }
//        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = examinedItems.last {
            if examinedItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: examinedItems
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
//        let finalMessage: String
//        if command.isAllCommand {
//            if messages.isEmpty {
//                finalMessage = engine.messenger.nothingSpecialToExamine()
//            } else {
//                finalMessage = messages.joined(separator: "\n\n")
//            }
//        } else {
//            finalMessage = messages.joined(separator: "\n\n")
//        }

        return ActionResult(
            message: "🤡 finalMessage",
            changes: allStateChanges
        )
    }

    // MARK: - Helper Methods

//    /// Describes a container or door, including its contents if applicable.
//    ///
//    /// - Parameters:
//    ///   - targetItem: The container or door item to describe.
//    ///   - engine: The game engine instance.
//    /// - Returns: A description string for the container or door.
//    private func describeContainerOrDoor(
//        targetItem: Item,
//        engine: GameEngine
//    ) async throws -> String {
//        var description = await engine.longDescription(of: targetItem.id)
//
//        // Add container-specific information
//        if targetItem.hasFlag(.isContainer) {
//            let isOpen = try await engine.hasFlag(.isOpen, on: targetItem.id)
//            let itemsInside = await engine.items(in: .item(targetItem.id))
//
//            if isOpen {
//                if itemsInside.isEmpty {
//                    description +=
//                        " "
//                        + engine.messenger.containerIsEmpty(
//                            container: targetItem.withDefiniteArticle
//                        )
//                } else {
//                    let itemList = itemsInside.sorted().listWithIndefiniteArticles
//                    description +=
//                        " "
//                        + engine.messenger.containerContains(
//                            container: targetItem.withDefiniteArticle,
//                            contents: itemList
//                        )
//                }
//            } else {
//                description +=
//                    " "
//                    + engine.messenger.containerIsClosed(
//                        container: targetItem.withDefiniteArticle
//                    )
//            }
//        }
//
//        // Add door-specific information
//        if targetItem.hasFlag(.isDoor) {
//            let isOpen = try await engine.hasFlag(.isOpen, on: targetItem.id)
//            if isOpen {
//                description +=
//                    " "
//                    + engine.messenger.doorIsOpen(
//                        door: targetItem.withDefiniteArticle
//                    )
//            } else {
//                description +=
//                    " "
//                    + engine.messenger.doorIsClosed(
//                        door: targetItem.withDefiniteArticle
//                    )
//            }
//        }
//
//        return description
//    }
//
//    /// Describes a surface, including items placed on it.
//    ///
//    /// - Parameters:
//    ///   - targetItem: The surface item to describe.
//    ///   - engine: The game engine instance.
//    /// - Returns: A description string for the surface.
//    private func describeSurface(targetItem: Item, engine: GameEngine) async throws -> String {
//        var description = await engine.longDescription(of: targetItem.id)
//
//        // Add surface-specific information
//        let itemsOnSurface = await engine.items(in: .item(targetItem.id))
//
//        if itemsOnSurface.isEmpty {
//            description +=
//                " "
//                + engine.messenger.surfaceIsEmpty(
//                    surface: targetItem.withDefiniteArticle
//                )
//        } else {
//            // Check for items with firstDescription
//            var surfaceDescriptions: [String] = []
//            var regularItems: [Item] = []
//
//            for item in itemsOnSurface.sorted() {
//                if let firstDescription = item.attributes[.firstDescription],
//                    case .string(let description) = firstDescription,
//                    !description.isEmpty
//                {
//                    surfaceDescriptions.append(description)
//                } else {
//                    regularItems.append(item)
//                }
//            }
//
//            // Add first descriptions
//            if !surfaceDescriptions.isEmpty {
//                description += " " + surfaceDescriptions.joined(separator: " ")
//            }
//
//            // Add regular item list if there are items without first descriptions
//            if !regularItems.isEmpty {
//                let itemList = regularItems.listWithIndefiniteArticles
//                description +=
//                    " "
//                    + engine.messenger.surfaceContains(
//                        surface: targetItem.withDefiniteArticle,
//                        contents: itemList
//                    )
//            }
//        }
//
//        return description
//    }
}
