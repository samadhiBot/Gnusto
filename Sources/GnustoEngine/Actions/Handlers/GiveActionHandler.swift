import Foundation

/// Handles the "GIVE" command and its synonyms (e.g., "DONATE", "OFFER"), allowing the player
/// to give items to other actors.
public struct GiveActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects, .to, .indirectObject),
        .match(.verb, .indirectObject, .directObjects),
    ]

    public let synonyms: [Verb] = [.give, .offer, .donate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "GIVE" command.
    ///
    /// This action validates prerequisites and handles giving items to characters.
    /// Checks that items exist, are held by the player, and the recipient is a character.
    /// Supports both single items and ALL commands.
    public func process(context: ActionContext) async throws -> ActionResult {
        let gifts = try await context.itemDirectObjects()

        // Get the recipient from indirect object
        guard
            let recipient = try await context.itemIndirectObject(
                failureMessage: context.msg.cannotGiveThingsToThat()
            )
        else {
            throw await ActionResponse.feedback(
                context.msg.giveItemToWhom(gifts.listWithDefiniteArticles() ?? "what")
            )
        }

        if gifts.isEmpty {
            throw await ActionResponse.feedback(
                context.command.preposition == .to
                    ? context.msg.giveWhatToRecipient(recipient.withDefiniteArticle)
                    : context.msg.giveWhatToWhom()
            )
        }

        // Validate recipient exists and is a character
        guard await recipient.isCharacter else {
            throw ActionResponse.feedback(
                context.msg.canOnlyDoCharacters(context.command)
            )
        }

        var allStateChanges = [StateChange]()
        var givenItems: [ItemProxy] = []

        // Process each object individually
        for gift in gifts {
            do {
                guard await gift.playerIsHolding else {
                    throw await ActionResponse.feedback(
                        context.msg.youDontHave(gift.withDefiniteArticle)
                    )
                }

                // Move item to recipient
                await allStateChanges.append(
                    gift.move(to: .item(recipient.id)),
                    gift.setFlag(.isTouched)
                )

                givenItems.append(gift)

            } catch {
                // For ALL commands, skip items that cause errors
                if !context.command.isAllCommand {
                    throw error
                }
            }
        }

        // Mark recipient as touched if any items were given
        if givenItems.isNotEmpty {
            await allStateChanges.append(
                recipient.setFlag(.isTouched)
            )
        }

        // Generate appropriate message
        let message =
            if givenItems.isEmpty {
                context.msg.youAreEmptyHanded()
            } else {
                await context.msg.itemGivenTo(
                    givenItems.listWithDefiniteArticles() ?? "",
                    recipient: recipient.withDefiniteArticle
                )
            }

        return ActionResult(
            message: message,
            changes: allStateChanges
        )
    }
}
