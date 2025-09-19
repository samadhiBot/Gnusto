import Foundation

/// Handles the "KICK" command for kicking objects.
/// Implements kicking mechanics following ZIL patterns for physical interactions.
public struct KickActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.kick]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KICK" command.
    ///
    /// This action validates prerequisites and handles kicking attempts on different types
    /// of objects. Generally provides humorous or dismissive responses following ZIL traditions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Kick requires a direct object (what to kick)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Determine appropriate response based on object type
        let message =
            if await item.isCharacter {
                // Kicking characters is generally not advisable
                await context.msg.kickCharacter(item.withDefiniteArticle)
            } else if await item.playerIsHolding {
                // Generic kicking response for objects
                await context.msg.kickHeldObject(item.withDefiniteArticle)
            } else if await item.hasFlag(.isTakable) {
                // Generic kicking response for objects
                await context.msg.kickSmallObject(item.withDefiniteArticle)
            } else {
                // Generic kicking response for objects
                await context.msg.kickLargeObject(item.withDefiniteArticle)
            }

        var changes = await [
            item.setFlag(.isTouched)
        ]

        if await item.playerIsHolding {
            let locationID = await context.player.location.id
            changes.append(
                item.move(to: .location(locationID))
            )
        }

        return ActionResult(message: message, changes: changes)
    }
}
