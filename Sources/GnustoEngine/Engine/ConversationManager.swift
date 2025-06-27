import Foundation

/// Manages conversation state and question/response interactions between the game engine and player.
///
/// The `ConversationManager` provides a centralized system for handling multi-turn conversations,
/// where the engine asks questions and waits for specific types of responses from the player.
/// This enables ZIL-style interactions like:
/// - "ASK TROLL" → "What do you want to ask the troll about?" → "TREASURE"
/// - "NIBBLE APPLE" → "Do you mean you want to eat the apple?" → "YES"
///
/// The manager handles question state, input interpretation, and graceful recovery when
/// players don't directly answer questions.
public struct ConversationManager: Sendable {

    // MARK: - Question Types

    /// The type of question currently being asked to the player.
    public enum QuestionType: String, Codable, Sendable {
        /// Asking for a topic to discuss (e.g., "What do you want to ask about?")
        case topic

        /// Asking for a yes/no confirmation (e.g., "Do you mean...?")
        case yesNo

        /// Asking for a choice from multiple options
        case choice
    }

    /// Context information for a pending question.
    public struct QuestionContext: Sendable {
        /// The type of question being asked
        public let type: QuestionType

        /// The prompt message displayed to the player
        public let prompt: String

        /// The character or item ID that initiated the question
        public let sourceID: ItemID

        /// The original command that triggered the question (stored as raw input)
        public let originalCommandInput: String?

        /// Additional context data specific to the question type
        public let data: [String: String]

        public init(
            type: QuestionType,
            prompt: String,
            sourceID: ItemID,
            originalCommandInput: String? = nil,
            data: [String: String] = [:]
        ) {
            self.type = type
            self.prompt = prompt
            self.sourceID = sourceID
            self.originalCommandInput = originalCommandInput
            self.data = data
        }
    }

    // MARK: - Question Management

    /// Asks a topic question to the player (e.g., "What do you want to ask the troll about?").
    ///
    /// - Parameters:
    ///   - prompt: The question to display to the player
    ///   - characterID: The ID of the character being asked about
    ///   - originalCommand: The command that triggered this question
    ///   - engine: The game engine
    /// - Returns: State changes to set up the question
    public static func askForTopic(
        prompt: String,
        characterID: ItemID,
        originalCommand: Command,
        engine: GameEngine
    ) async -> [StateChange] {
        let context = QuestionContext(
            type: .topic,
            prompt: prompt,
            sourceID: characterID,
            originalCommandInput: originalCommand.rawInput,
            data: ["verb": originalCommand.verb.rawValue]
        )

        return await setQuestionContext(context, engine: engine)
    }

    /// Asks a yes/no confirmation question to the player.
    ///
    /// - Parameters:
    ///   - prompt: The confirmation question to display
    ///   - sourceID: The ID of the item/character that triggered the question
    ///   - originalCommand: The command that triggered this question
    ///   - engine: The game engine
    ///   - data: Additional context data for the confirmation
    /// - Returns: State changes to set up the question
    public static func askYesNo(
        prompt: String,
        sourceID: ItemID,
        originalCommand: Command,
        engine: GameEngine,
        data: [String: String] = [:]
    ) async -> [StateChange] {
        let context = QuestionContext(
            type: .yesNo,
            prompt: prompt,
            sourceID: sourceID,
            originalCommandInput: originalCommand.rawInput,
            data: data
        )

        return await setQuestionContext(context, engine: engine)
    }

    /// Clears any pending question state.
    ///
    /// - Parameter engine: The game engine
    /// - Returns: State changes to clear the question context
    public static func clearQuestion(engine: GameEngine) async -> [StateChange] {
        let gameState = await engine.gameState
        var changes: [StateChange] = []

        // Only create clear changes for globals that actually exist
        if gameState.globalState[.pendingQuestionType] != nil {
            if let change = await engine.clearGlobal(.pendingQuestionType) {
                changes.append(change)
            }
        }
        if gameState.globalState[.pendingQuestionPrompt] != nil {
            if let change = await engine.clearGlobal(.pendingQuestionPrompt) {
                changes.append(change)
            }
        }
        if gameState.globalState[.pendingQuestionSource] != nil {
            if let change = await engine.clearGlobal(.pendingQuestionSource) {
                changes.append(change)
            }
        }
        if gameState.globalState[.pendingQuestionContext] != nil {
            if let change = await engine.clearGlobal(.pendingQuestionContext) {
                changes.append(change)
            }
        }

        return changes
    }

    // MARK: - Question State Queries

    /// Checks if there is currently a pending question.
    ///
    /// - Parameter engine: The game engine
    /// - Returns: True if a question is pending, false otherwise
    public static func hasPendingQuestion(engine: GameEngine) async -> Bool {
        guard let questionTypeValue = await engine.global(.pendingQuestionType) as StateValue?,
            let questionType = questionTypeValue.toString,
            !questionType.isEmpty,
            QuestionType(rawValue: questionType) != nil
        else {
            return false
        }
        return true
    }

    /// Gets the current question context if one exists.
    ///
    /// - Parameter engine: The game engine
    /// - Returns: The current question context, or nil if no question is pending
    public static func getCurrentQuestion(engine: GameEngine) async -> QuestionContext? {
        guard
            let questionTypeString = await engine.global(.pendingQuestionType)?.toString,
            let questionType = QuestionType(rawValue: questionTypeString),
            let prompt = await engine.global(.pendingQuestionPrompt)?.toString,
            let sourceID = await engine.global(.pendingQuestionSource)?.toItemID
        else {
            return nil
        }

        // Try to decode additional data
        var data: [String: String] = [:]

        if let contextString = await engine.global(.pendingQuestionContext)?.toString,
            let contextData = try? JSONDecoder().decode(
                [String: String].self, from: contextString.data(using: .utf8) ?? Data())
        {
            data = contextData
        }

        return QuestionContext(
            type: questionType,
            prompt: prompt,
            sourceID: sourceID,
            originalCommandInput: nil,
            data: data
        )
    }

    // MARK: - Response Processing

    /// Processes player input as a potential response to a pending question.
    ///
    /// - Parameters:
    ///   - input: The player's input string
    ///   - engine: The game engine
    /// - Returns: An ActionResult if the input was handled as a question response, nil otherwise
    public static func processQuestionResponse(
        input: String,
        engine: GameEngine
    ) async -> ActionResult? {
        guard let context = await getCurrentQuestion(engine: engine) else {
            return nil
        }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch context.type {
        case .topic:
            return await processTopicResponse(trimmedInput, context: context, engine: engine)
        case .yesNo:
            return await processYesNoResponse(trimmedInput, context: context, engine: engine)
        case .choice:
            return await processChoiceResponse(trimmedInput, context: context, engine: engine)
        }
    }

    // MARK: - Private Helpers

    /// Sets the question context in global state.
    private static func setQuestionContext(
        _ context: QuestionContext,
        engine: GameEngine
    ) async -> [StateChange] {
        // Encode additional context data as JSON
        let contextData = try? JSONEncoder().encode(context.data)
        let contextString = contextData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        return [
            await engine.setGlobal(.pendingQuestionType, to: context.type.rawValue),
            await engine.setGlobal(.pendingQuestionPrompt, to: context.prompt),
            await engine.setGlobal(.pendingQuestionSource, to: context.sourceID),
            await engine.setGlobal(.pendingQuestionContext, to: contextString),
        ]
    }

    /// Processes a topic response (e.g., "TREASURE" in response to "What do you want to ask about?").
    private static func processTopicResponse(
        _ input: String,
        context: QuestionContext,
        engine: GameEngine
    ) async -> ActionResult? {
        let gameState = await engine.gameState
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find the topic as an item in the current scope or vocabulary
        var topicReference: EntityReference? = nil

        // First, check if the input matches any item names in the vocabulary
        let lowercasedInput = trimmedInput.lowercased()
        if let itemIDs = gameState.vocabulary.items[lowercasedInput],
            let firstItemID = itemIDs.first
        {
            topicReference = .item(firstItemID)
        } else {
            // Try partial matching against item names
            for (itemName, itemIDs) in gameState.vocabulary.items {
                if itemName.contains(lowercasedInput) || lowercasedInput.contains(itemName) {
                    if let firstItemID = itemIDs.first {
                        topicReference = .item(firstItemID)
                        break
                    }
                }
            }
        }

        // If we still don't have a topic, try parsing as a simple command to get object references
        if topicReference == nil {
            let parseResult = engine.parser.parse(
                input: "examine \(trimmedInput)",  // Use examine as a dummy verb to get object parsing
                vocabulary: gameState.vocabulary,
                gameState: gameState
            )

            if case .success(let command) = parseResult,
                let directObject = command.directObject
            {
                topicReference = directObject
            }
        }

        // Clear the question state first
        let clearChanges = await clearQuestion(engine: engine)

        // If we found a topic reference, process the ASK command
        if let topic = topicReference {
            // Create a new ASK command with the character and topic
            let askCommand = Command(
                verb: .ask,
                directObject: .item(context.sourceID),
                indirectObject: topic,
                rawInput: "ask \(context.sourceID) about \(trimmedInput)"
            )

            // Find the ASK action handler and process the command
            let allHandlers = GameEngine.defaultActionHandlers
            if let askHandler = allHandlers.first(where: { $0.verbs.contains(.ask) }) {
                do {
                    let result = try await askHandler.process(command: askCommand, engine: engine)

                    // Combine clear changes with the ask result
                    let combinedChanges = clearChanges + result.changes
                    return ActionResult(
                        message: result.message,
                        changes: combinedChanges,
                        effects: result.effects
                    )
                } catch {
                    // If the ASK handler fails, return an error message
                    return ActionResult(
                        message: "Sorry, I couldn't process that question.",
                        changes: clearChanges
                    )
                }
            }
        }

        // If we can't find the topic, provide a helpful error
        return ActionResult(
            message: "I don't understand what you want to ask \(context.sourceID) about.",
            changes: clearChanges
        )
    }

    /// Processes a yes/no response.
    private static func processYesNoResponse(
        _ input: String,
        context: QuestionContext,
        engine: GameEngine
    ) async -> ActionResult? {
        let clearChanges = await clearQuestion(engine: engine)

        // Check for yes responses
        if ["yes", "y", "sure", "ok", "okay", "yep", "yeah", "aye"].contains(input) {
            // Execute the original action from the context data
            if let originalVerb = context.data["verb"] {
                // Find the verb by looking it up in the engine's vocabulary
                let gameState = await engine.gameState
                guard
                    let verb = gameState.vocabulary.verbs.first(where: {
                        $0.rawValue == originalVerb
                    })
                else {
                    return ActionResult(
                        message: "Sorry, I couldn't find that command.", changes: clearChanges)
                }

                // Try to reconstruct the command from context data
                let directObjectID = context.data["directObjectID"]
                let indirectObjectID = context.data["indirectObjectID"]

                let directObject: EntityReference? = directObjectID.map { .item(ItemID($0)) }
                let indirectObject: EntityReference? = indirectObjectID.map { .item(ItemID($0)) }

                let confirmCommand = Command(
                    verb: verb,
                    directObject: directObject,
                    indirectObject: indirectObject,
                    rawInput: context.originalCommandInput ?? "\(verb.rawValue)"
                )

                // Find and execute the appropriate handler
                let allHandlers = GameEngine.defaultActionHandlers
                if let handler = allHandlers.first(where: { $0.verbs.contains(verb) }) {
                    do {
                        let result = try await handler.process(
                            command: confirmCommand, engine: engine)
                        return ActionResult(
                            message: result.message,
                            changes: clearChanges + result.changes,
                            effects: result.effects
                        )
                    } catch {
                        return ActionResult(
                            message: "Sorry, I couldn't process that action.",
                            changes: clearChanges
                        )
                    }
                }
            }

            // Fallback if we can't execute the original command
            return ActionResult(message: "Okay.", changes: clearChanges)
        }

        // Check for no responses
        if ["no", "n", "nope", "nah", "never", "negative"].contains(input) {
            return ActionResult(message: "Okay, never mind.", changes: clearChanges)
        }

        // If it's not a clear yes/no, treat it as a regular command
        // and clear the question state
        return ActionResult(changes: clearChanges)
    }

    /// Processes a choice response (for future use).
    private static func processChoiceResponse(
        _ input: String,
        context: QuestionContext,
        engine: GameEngine
    ) async -> ActionResult? {
        // Placeholder for choice-based questions
        let clearChanges = await clearQuestion(engine: engine)
        return ActionResult(message: "Choice questions not yet implemented.", changes: clearChanges)
    }
}
