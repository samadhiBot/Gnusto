import Foundation

/// A utility handler for creating yes/no confirmation dialogs.
///
/// This handler provides a standardized way to ask the player confirmation questions
/// and execute actions based on their response. It's used internally by other action
/// handlers when they need to disambiguate player intent.
///
/// Example usage:
/// ```swift
/// // In another action handler:
/// return try await YesNoQuestionHandler.askConfirmation(
///     question: "Do you mean you want to eat the apple?",
///     yesAction: { engine in
///         // Execute the EAT action
///         let eatHandler = EatActionHandler()
///         return try await eatHandler.process(command: eatCommand, engine: engine)
///     },
///     originalCommand: command,
///     engine: engine
/// )
/// ```
public struct YesNoQuestionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let synonyms: [Verb] = [.yes, .no]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes YES/NO responses when a question is pending.
    ///
    /// This handler is typically not called directly - instead, the ConversationManager
    /// processes yes/no responses and executes appropriate actions.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Check if there's a pending yes/no question
        guard await context.engine.conversationManager.hasPendingQuestion else {
            // No pending question - treat as a general response
            return ActionResult(
                context.verb == .yes ? context.msg.yesWhat()
                                     : context.msg.noWhat()
            )
        }

        // Let the ConversationManager handle the response
        if let response = try await context.engine.conversationManager.processResponse(
            context.verb.rawValue,
            with: context.engine
        ) {
            return response
        }

        // Fallback
        return ActionResult(
            context.msg.responseNotUnderstood()
        )
    }

    // MARK: - Static Utility Methods

    /// Creates a yes/no confirmation dialog with a command to execute on "yes".
    ///
    /// This static method provides a convenient way for other action handlers to
    /// create confirmation dialogs. The question is presented to the player, and
    /// if they respond "yes", the specified command is executed.
    ///
    /// - Parameters:
    ///   - question: The confirmation question to ask the player
    ///   - yesCommand: The command to execute for "yes" responses
    ///   - noMessage: Optional message to show for "no" responses
    ///   - sourceID: The ID of the item/character that initiated the question
    ///   - context: The context that triggered this confirmation
    /// - Returns: An ActionResult that sets up the confirmation dialog
    public static func askConfirmation(
        question: String,
        yesCommand: Command,
        noMessage: String? = nil,
        sourceID: ItemID = "system",
        context: ActionContext
    ) async -> ActionResult {
        await context.engine.conversationManager.askYesNo(
            question: question,
            yesCommand: yesCommand,
            noMessage: noMessage,
            sourceID: sourceID,
            context: context
        )
    }

    /// Creates a simple yes/no confirmation that executes the original command on "yes".
    ///
    /// This is a convenience method for the common case where you want to ask for
    /// confirmation before executing an action, and do nothing on "no".
    ///
    /// - Parameters:
    ///   - question: The confirmation question to ask
    ///   - context: The context that triggered this confirmation
    /// - Returns: An ActionResult that sets up the confirmation dialog
    public static func askToConfirmAction(
        question: String,
        context: ActionContext
    ) async -> ActionResult {
        await context.engine.conversationManager.askToConfirm(
            question: question,
            command: context.command,
            context: context
        )
    }

    /// Creates a disambiguation question for ambiguous commands.
    ///
    /// This method helps when the player uses ambiguous commands that could
    /// refer to multiple actions or objects.
    ///
    /// - Parameters:
    ///   - question: The disambiguation question (e.g., "Do you mean you want to eat the apple?")
    ///   - clarifiedCommand: The command to execute if the player confirms
    ///   - context: The context that triggered this confirmation
    /// - Returns: An ActionResult that sets up the disambiguation dialog
    public static func askToDisambiguate(
        question: String,
        clarifiedCommand: Command,
        context: ActionContext
    ) async -> ActionResult {
        await context.engine.conversationManager.askToDisambiguate(
            question: question,
            clarifiedCommand: clarifiedCommand,
            context: context
        )
    }
}
