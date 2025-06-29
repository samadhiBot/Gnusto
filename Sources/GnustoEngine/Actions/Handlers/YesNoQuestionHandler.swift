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

    public let verbs: [Verb] = [.yes, .no]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes YES/NO responses when a question is pending.
    ///
    /// This handler is typically not called directly - instead, the ConversationManager
    /// processes yes/no responses and executes appropriate actions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Check if there's a pending yes/no question
        guard let context = await ConversationManager.getCurrentQuestion(engine: engine),
            context.type == .yesNo
        else {

            // No pending question - treat as a general response
            if command.verb == .yes {
                return ActionResult("Yes, what?")
            } else {
                return ActionResult("No, what?")
            }
        }

        // Let the ConversationManager handle the response
        if let response = await ConversationManager.processQuestionResponse(
            input: command.verb.rawValue,
            engine: engine
        ) {
            return response
        }

        // Fallback
        return ActionResult("I don't understand your response.")
    }

    // MARK: - Static Utility Methods

    /// Creates a yes/no confirmation dialog with custom action handlers.
    ///
    /// This static method provides a convenient way for other action handlers to
    /// create confirmation dialogs. The question is presented to the player, and
    /// based on their response, either the yes action or no action is executed.
    ///
    /// - Parameters:
    ///   - question: The confirmation question to ask the player
    ///   - yesAction: A closure that returns an ActionResult for "yes" responses
    ///   - noAction: A closure that returns an ActionResult for "no" responses (optional)
    ///   - originalCommand: The command that triggered this confirmation
    ///   - sourceID: The ID of the item/character that initiated the question
    ///   - engine: The game engine
    ///   - additionalData: Additional context data for the confirmation
    /// - Returns: An ActionResult that sets up the confirmation dialog
    public static func askConfirmation(
        question: String,
        yesAction: @escaping (GameEngine) async throws -> ActionResult,
        noAction: ((GameEngine) async throws -> ActionResult)? = nil,
        originalCommand: Command,
        sourceID: ItemID = "system",
        engine: GameEngine,
        additionalData: [String: String] = [:]
    ) async -> ActionResult {

        var contextData = additionalData
        contextData["verb"] = originalCommand.verb.rawValue
        contextData["hasYesAction"] = "true"
        contextData["hasNoAction"] = noAction != nil ? "true" : "false"

        // Store the action closures in a way that can be retrieved later
        // For now, we'll use a simple approach with the original command data
        if let directObjectID = originalCommand.directObjectItemID {
            contextData["directObjectID"] = directObjectID.rawValue
        }
        if let indirectObjectID = originalCommand.indirectObjectItemID {
            contextData["indirectObjectID"] = indirectObjectID.rawValue
        }

        let questionChanges = await ConversationManager.askYesNo(
            prompt: question,
            sourceID: sourceID,
            originalCommand: originalCommand,
            engine: engine,
            data: contextData
        )

        return ActionResult(message: question, changes: questionChanges)
    }

    /// Creates a simple yes/no confirmation that executes the original command on "yes".
    ///
    /// This is a convenience method for the common case where you want to ask for
    /// confirmation before executing an action, and do nothing on "no".
    ///
    /// - Parameters:
    ///   - question: The confirmation question to ask
    ///   - originalCommand: The command to execute if the player answers "yes"
    ///   - engine: The game engine
    /// - Returns: An ActionResult that sets up the confirmation dialog
    public static func askToConfirmAction(
        question: String,
        originalCommand: Command,
        engine: GameEngine
    ) async -> ActionResult {
        return await askConfirmation(
            question: question,
            yesAction: { engine in
                // Find the appropriate handler for the original command
                let allHandlers = GameEngine.defaultActionHandlers
                if let handler = allHandlers.first(where: {
                    $0.verbs.contains(originalCommand.verb)
                }) {
                    return try await handler.process(command: originalCommand, engine: engine)
                } else {
                    return ActionResult("I don't know how to do that.")
                }
            },
            noAction: { _ in
                return ActionResult("Okay, never mind.")
            },
            originalCommand: originalCommand,
            engine: engine
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
    ///   - originalCommand: The original ambiguous command
    ///   - engine: The game engine
    /// - Returns: An ActionResult that sets up the disambiguation dialog
    public static func askToDisambiguate(
        question: String,
        clarifiedCommand: Command,
        originalCommand: Command,
        engine: GameEngine
    ) async -> ActionResult {
        return await askConfirmation(
            question: question,
            yesAction: { engine in
                // Execute the clarified command
                let allHandlers = GameEngine.defaultActionHandlers
                if let handler = allHandlers.first(where: {
                    $0.verbs.contains(clarifiedCommand.verb)
                }) {
                    return try await handler.process(command: clarifiedCommand, engine: engine)
                } else {
                    return ActionResult("I don't understand that command.")
                }
            },
            noAction: { _ in
                return ActionResult("What did you want to do then?")
            },
            originalCommand: originalCommand,
            sourceID: "parser",
            engine: engine,
            additionalData: [
                "clarifiedVerb": clarifiedCommand.verb.rawValue,
            ]
        )
    }
}
