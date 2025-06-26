import Foundation

/// Handles the "GIVE" command and its synonyms (e.g., "DONATE", "OFFER"), allowing the player
/// to give items to other actors.
public struct GiveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject, .to, .indirectObject),
        .match(.verb, .indirectObject, .directObject),
    ]

    public let verbs: [Verb] = [.give, .offer, .donate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "GIVE" command.
    ///
    /// This action validates prerequisites and handles giving items to characters.
    /// Checks that items exist, are held by the player, and the recipient is a character.
    /// Supports both single items and ALL commands.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Get the recipient from indirect object
        guard let indirectObjectRef = command.indirectObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.giveToWhom()
            )
        }
        guard case .item(let recipientID) = indirectObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.give)
            )
        }

        // Validate recipient exists and is a character
        let recipient = try await engine.item(recipientID)
        guard recipient.hasFlag(.isCharacter) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.give)
            )
        }

        // Check if recipient is accessible
        guard await engine.playerCanReach(recipientID) else {
            throw ActionResponse.itemNotAccessible(recipientID)
        }

        // For ALL commands, empty directObjects is valid (means nothing to give)
        if !command.isAllCommand {
            guard command.directObjects.isNotEmpty else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.doWhat(verb: command.verb)
                )
            }
        }

        var allStateChanges: [StateChange] = []
        var givenItems: [Item] = []
        var lastGivenItem: Item?

        // Process each object individually
        for directObjectRef in command.directObjects {
            guard case .item(let targetItemID) = directObjectRef else {
                if command.isAllCommand {
                    continue  // Skip non-items in ALL commands
                } else {
                    throw ActionResponse.prerequisiteNotMet(
                        engine.messenger.thatsNotSomethingYouCan(.give)
                    )
                }
            }

            do {
                let targetItem = try await engine.item(targetItemID)

                // Check if player has this item
                guard targetItem.parent == .player else {
                    if command.isAllCommand {
                        continue  // Skip items not held in ALL commands
                    } else {
                        throw ActionResponse.prerequisiteNotMet(
                            engine.messenger.youDontHaveThat()
                        )
                    }
                }

                // Create state changes for this item
                var itemStateChanges: [StateChange] = []

                // Move item to recipient
                let moveChange = await engine.move(targetItem, to: .item(recipientID))
                itemStateChanges.append(moveChange)

                // Set .isTouched flag if not already set
                if let touchedChange = await engine.setFlag(.isTouched, on: targetItem) {
                    itemStateChanges.append(touchedChange)
                }

                allStateChanges.append(contentsOf: itemStateChanges)
                givenItems.append(targetItem)
                lastGivenItem = targetItem

            } catch {
                // For ALL commands, skip items that cause errors
                if !command.isAllCommand {
                    throw error
                }
            }
        }

        // Mark recipient as touched if any items were given
        if givenItems.isNotEmpty {
            if let recipientTouchedChange = await engine.setFlag(.isTouched, on: recipient) {
                allStateChanges.append(recipientTouchedChange)
            }
        }

        // Update pronouns appropriately for multiple objects
        if let lastItem = lastGivenItem {
            if givenItems.count > 1 {
                // For multiple items, update both "it" and "them"
                let pronounChanges = await engine.updatePronounsForMultipleObjects(
                    lastItem: lastItem,
                    allItems: givenItems
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
            if givenItems.isEmpty {
                if command.isAllCommand {
                    engine.messenger.youHaveNothingToGive()
                } else {
                    engine.messenger.youDontHaveThat()
                }
            } else {
                engine.messenger.itemGivenTo(
                    item: givenItems.listWithDefiniteArticles,
                    recipient: recipient.withDefiniteArticle
                )
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
