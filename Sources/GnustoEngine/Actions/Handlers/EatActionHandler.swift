import Foundation

/// Handles the "EAT" command for consuming food items.
/// This handler manages food consumption with proper container logic and state changes.
public struct EatActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.eat, .consume, .devour]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "EAT" command.
    ///
    /// This action validates prerequisites and handles consuming food either directly
    /// or from containers. Edible items are typically removed after consumption.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject() else {
            // Ensure we have a direct object
            throw ActionResponse.doWhat(context)
        }

        var message = [String]()
        var changes: [StateChange?] = [
            await targetItem.setFlag(.isTouched)
        ]

        if await !targetItem.playerIsHolding {
            message.append(context.msg.taken())
            changes.append(
                targetItem.move(to: .player)
            )
        }

        // Handle direct edible item
        message.append(
            await targetItem.hasFlag(.isEdible)
                ? context.msg.eatEdibleDenied(targetItem.withDefiniteArticle)
                : context.msg.eatInedibleDenied(targetItem.withDefiniteArticle)
        )

        return ActionResult(
            message: message.joined(separator: .linebreak),
            changes: changes
        )
    }
}
