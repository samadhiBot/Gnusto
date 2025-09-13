import Foundation

/// Handles the "DIG" command for digging with or without tools.
/// Implements digging mechanics following ZIL patterns.
public struct DigActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
        .match(.verb, .in, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
        .match(.verb, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [.dig, .excavate]

    public let requiresLight: Bool = true

    public init() {}

    // MARK: - Action Processing Methods

    /// Processes the "DIG" command.
    ///
    /// Handles digging attempts with different scenarios:
    /// - Digging with appropriate tools (shovels, spades)
    /// - Digging with inappropriate tools
    /// - Digging with bare hands
    /// - Digging specific objects vs. general digging
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject(
            universalMessage: { universal in
                guard universal.isDiggable else {
                    throw ActionResponse.cannotDoThat(context)
                }
                return try await diggingMessage(in: context, item: universal.withDefiniteArticle)
            }
        ) else {
            throw ActionResponse.feedback(
                context.msg.dig()
            )
        }

        return try await ActionResult(
            try await diggingMessage(in: context, item: targetItem.withDefiniteArticle),
            targetItem.setFlag(.isTouched)
        )
    }

    private func diggingMessage(
        in context: ActionContext,
        item: String
    ) async throws -> String {
        // Check for digging tool
        if let toolItem = try await context.itemIndirectObject(
//            failureMessage: <#T##String?#>
               failureMessage: context.msg.cannotDoWithThat(context.command, item: item)
           ),
           try await !toolItem.playerIsHolding
        {
            throw ActionResponse.itemNotHeld(toolItem)
        }
        return context.msg.dig()
    }
}
