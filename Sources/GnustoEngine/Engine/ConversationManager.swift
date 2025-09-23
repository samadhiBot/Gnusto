import Foundation

/// Manages conversation state and question/response interactions as a proper GameEngine subsystem.
///
/// The ConversationManager handles multi-turn conversations where the engine asks questions
/// and waits for specific responses from the player. Unlike the previous implementation,
/// this version stores strongly typed data and integrates cleanly with the engine's
/// command processing pipeline.
///
/// Example usage:
/// ```swift
/// // In an action handler
/// return await engine.conversationManager.askYesNo(
///     question: "Do you mean the red apple?",
///     yesCommand: clarifiedCommand,
///     noMessage: "What did you want to do then?"
/// )
/// ```
public actor ConversationManager {
    /// The currently pending question, if any
    private var pendingQuestion: PendingQuestion?

    // MARK: - Question Types

    /// Represents a pending question that requires player response
    private enum PendingQuestion: Sendable {
        /// A yes/no confirmation question
        case yesNo(YesNoQuestion)

        /// A topic question for character conversations
        case topic(TopicQuestion)

        /// A choice question from multiple options
        case choice(ChoiceQuestion)
    }

    /// A yes/no confirmation question with associated actions
    private struct YesNoQuestion: Sendable {
        let prompt: String
        let yesCommand: Command?
        let noMessage: String?
        let sourceID: ItemID
        let context: ActionContext?
    }

    /// A topic question for character conversations
    private struct TopicQuestion: Sendable {
        let prompt: String
        let characterID: ItemID
        let context: ActionContext
    }

    /// A choice question with multiple options
    private struct ChoiceQuestion: Sendable {
        let prompt: String
        let choices: [String: Command]
        let sourceID: ItemID
        let context: ActionContext?
    }

    // MARK: - Question Management

    /// Asks a yes/no confirmation question with optional command execution
    /// - Parameters:
    ///   - question: The question to ask the player
    ///   - yesCommand: The command to execute if player responds "yes"
    ///   - noMessage: Optional message to show if player responds "no"
    ///   - sourceID: The ID of the item/character asking the question
    ///   - context: The original action context that triggered this question
    /// - Returns: ActionResult with the question prompt
    public func askYesNo(
        question: String,
        yesCommand: Command? = nil,
        noMessage: String? = nil,
        sourceID: ItemID = ItemID("system"),
        context: ActionContext? = nil
    ) async -> ActionResult {
        pendingQuestion = .yesNo(
            YesNoQuestion(
                prompt: question,
                yesCommand: yesCommand,
                noMessage: noMessage,
                sourceID: sourceID,
                context: context
            ))

        return ActionResult(message: question)
    }

    /// Asks a topic question for character conversations
    /// - Parameters:
    ///   - question: The question to ask (e.g., "What do you want to ask about?")
    ///   - characterID: The ID of the character being asked about
    ///   - context: The original action context
    /// - Returns: ActionResult with the question prompt
    public func askForTopic(
        question: String,
        characterID: ItemID,
        context: ActionContext
    ) async -> ActionResult {
        pendingQuestion = .topic(
            TopicQuestion(
                prompt: question,
                characterID: characterID,
                context: context
            ))

        return ActionResult(message: question)
    }

    /// Asks a choice question with multiple options
    /// - Parameters:
    ///   - question: The question to ask
    ///   - choices: Dictionary mapping choice strings to commands
    ///   - sourceID: The ID of the item/character asking the question
    ///   - context: The original action context
    /// - Returns: ActionResult with the question prompt
    public func askChoice(
        question: String,
        choices: [String: Command],
        sourceID: ItemID = ItemID("system"),
        context: ActionContext? = nil
    ) async -> ActionResult {
        pendingQuestion = .choice(
            ChoiceQuestion(
                prompt: question,
                choices: choices,
                sourceID: sourceID,
                context: context
            ))

        return ActionResult(message: question)
    }

    /// Clears any pending question
    public func clearQuestion() {
        pendingQuestion = nil
    }

    // MARK: - State Queries

    /// Checks if there is currently a pending question
    /// - Returns: True if a question is pending
    public var hasPendingQuestion: Bool {
        pendingQuestion != nil
    }

    /// Gets the current question prompt, if any
    /// - Returns: The question prompt or nil if no question is pending
    public var currentQuestionPrompt: String? {
        switch pendingQuestion {
        case .yesNo(let question): question.prompt
        case .topic(let question): question.prompt
        case .choice(let question): question.prompt
        case .none: nil
        }
    }

    // MARK: - Response Processing

    /// Processes player input as a potential response to a pending question.
    ///
    /// - Parameter input: The player's input string.
    /// - Parameter engine: The game engine for accessing game state and context.
    /// - Returns: ActionResult if the input was handled as a question response, nil otherwise.
    public func processResponse(
        _ input: String,
        with engine: GameEngine
    ) async throws -> ActionResult? {
        guard let question = pendingQuestion else { return nil }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let result: ActionResult? =
            switch question {
            case .yesNo(let yesNoQuestion):
                try await processYesNoResponse(
                    trimmedInput,
                    question: yesNoQuestion,
                    with: engine
                )
            case .topic(let topicQuestion):
                try await processTopicResponse(
                    trimmedInput,
                    question: topicQuestion,
                    with: engine
                )
            case .choice(let choiceQuestion):
                try await processChoiceResponse(
                    trimmedInput,
                    question: choiceQuestion,
                    with: engine
                )
            }

        if result != nil { pendingQuestion = nil }

        return result
    }

    // MARK: - Private Response Handlers

    /// Processes a yes/no response
    private func processYesNoResponse(
        _ input: String,
        question: YesNoQuestion,
        with engine: GameEngine
    ) async throws -> ActionResult? {
        // Check for yes responses
        if ["yes", "y", "sure", "ok", "okay", "yep", "yeah", "aye"].contains(input) {
            if let yesCommand = question.yesCommand {
                return try await executeCommand(yesCommand, with: engine)
            } else {
                return ActionResult(message: "Okay.")
            }
        }

        // Check for no responses
        if ["no", "n", "nope", "nah", "never", "negative"].contains(input) {
            let message = question.noMessage ?? "Okay, never mind."
            return ActionResult(message: message)
        }

        // Not a clear yes/no response
        return nil
    }

    /// Processes a topic response
    private func processTopicResponse(
        _ input: String,
        question: TopicQuestion,
        with engine: GameEngine
    ) async throws -> ActionResult? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find the topic as an item in the vocabulary
        var topicItemID: ItemID?
        let lowercasedInput = trimmedInput.lowercased()

        // First, check exact matches
        let vocabulary = engine.vocabulary
        if let itemIDs = vocabulary.items[lowercasedInput],
            let firstItemID = itemIDs.first
        {
            topicItemID = firstItemID
        } else {
            // Try partial matching
            for (itemName, itemIDs) in vocabulary.items {
                if itemName.contains(lowercasedInput) || lowercasedInput.contains(itemName) {
                    if let firstItemID = itemIDs.first {
                        topicItemID = firstItemID
                        break
                    }
                }
            }
        }

        // If we found a topic, create an ASK command
        if let topicItemID {
            do {
                let characterProxy = await engine.item(question.characterID)
                let topicProxy = await engine.item(topicItemID)

                let askCommand = Command(
                    verb: .ask,
                    directObject: .item(characterProxy),
                    indirectObject: .item(topicProxy)
                )

                return try await executeCommand(askCommand, with: engine)
            } catch {
                return ActionResult(message: "I couldn't find that topic.")
            }
        }

        // Topic not found - return nil to let engine process as normal command
        return nil
    }

    /// Processes a choice response
    private func processChoiceResponse(
        _ input: String,
        question: ChoiceQuestion,
        with engine: GameEngine
    ) async throws -> ActionResult? {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for exact match
        if let command = question.choices[trimmedInput] {
            return try await executeCommand(command, with: engine)
        }

        // Check for case-insensitive match
        let lowercasedInput = trimmedInput.lowercased()
        for (choice, command) in question.choices {
            if choice.lowercased() == lowercasedInput {
                return try await executeCommand(command, with: engine)
            }
        }

        // No valid choice found
        return nil
    }

    // MARK: - Command Execution

    /// Executes a command through the engine's normal pipeline
    /// - Parameter command: The command to execute
    /// - Returns: ActionResult from the command execution
    private func executeCommand(
        _ command: Command,
        with engine: GameEngine
    ) async throws -> ActionResult {
        // Find the appropriate handler for the command
        let handler = await engine.findActionHandler(for: command)

        guard let handler else {
            return ActionResult(
                engine.messenger.verbUnknown(command.verbPhrase)
            )
        }

        // Execute the command through the handler
        do {
            let context = ActionContext(command, engine)
            return try await handler.process(context: context)
        } catch {
            if error is ActionResponse {
                throw error
            } else {
                await engine.logError("Error executing clarified command: \(error)")
                return ActionResult(message: "Sorry, I couldn't process that command.")
            }
        }
    }
}

// MARK: - Convenience Methods

extension ConversationManager {
    /// Creates a simple yes/no confirmation for executing a command
    /// - Parameters:
    ///   - question: The confirmation question
    ///   - command: The command to execute if player confirms
    ///   - context: The original action context
    /// - Returns: ActionResult with the question
    public func askToConfirm(
        question: String,
        command: Command,
        context: ActionContext
    ) async -> ActionResult {
        await askYesNo(
            question: question,
            yesCommand: command,
            noMessage: context.msg.conversationNeverMind()
        )
    }

    /// Creates a disambiguation question for ambiguous commands
    /// - Parameters:
    ///   - question: The disambiguation question
    ///   - clarifiedCommand: The command to execute if player confirms
    ///   - context: The original action context
    /// - Returns: ActionResult with the question
    public func askToDisambiguate(
        question: String,
        clarifiedCommand: Command,
        context: ActionContext
    ) async -> ActionResult {
        await askYesNo(
            question: question,
            yesCommand: clarifiedCommand,
            noMessage: context.msg.conversationWhatNext(),
            sourceID: ItemID("parser"),
            context: context
        )
    }
}
