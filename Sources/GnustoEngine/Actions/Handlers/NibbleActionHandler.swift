import Foundation

/// Handles the "NIBBLE" command, which typically means to eat something in small bites.
/// Demonstrates the disambiguation pattern where ambiguous commands trigger yes/no questions
/// to clarify player intent (e.g., "Do you mean you want to eat the apple?").
public struct NibbleActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let synonyms: [Verb] = [.nibble, .bite]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "NIBBLE" command.
    ///
    /// Since "nibble" is conceptually similar to "eat" but less common,
    /// this handler asks for confirmation before proceeding with the eating action.
    /// This demonstrates the ZIL pattern of disambiguation through yes/no questions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object (with automatic reachability checking)
        guard let item = try await context.itemDirectObject() else {
            throw ActionResponse.feedback(
                context.msg.nibbleWhat()
            )
        }

        // Check if the item is something that can be eaten
        guard await item.hasFlag(.isEdible) else {
            throw ActionResponse.feedback(
                context.msg.eatInedibleDenied(await item.withDefiniteArticle)
            )
        }

        // Create the clarified EAT command
        let eatCommand = Command(
            verb: .eat,
            directObject: context.command.directObject
        )

        // Ask for confirmation using the disambiguation pattern
        return await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean you want to eat \(await item.withDefiniteArticle)?",
            clarifiedCommand: eatCommand,
            context: context
        )
    }
}
