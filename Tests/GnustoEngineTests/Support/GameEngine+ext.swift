@testable import GnustoEngine

extension GameEngine {
    static func test(
        blueprint: GameBlueprint = MinimalGame(),
        vocabulary: Vocabulary? = nil,
        pronouns: [String: Set<EntityReference>] = [:],
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        globalState: [GlobalID: StateValue] = [:],
        parser: Parser = StandardParser(),
        ioHandler: MockIOHandler? = nil
    ) async -> (GameEngine, MockIOHandler) {
        let mockIOHandler = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: blueprint,
            vocabulary: vocabulary,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            globalState: globalState,
            parser: parser,
            ioHandler: ioHandler ?? mockIOHandler,
            randomNumberGenerator: SeededGenerator()
        )
        return (engine, ioHandler ?? mockIOHandler)
    }

    /// Applies a `StateChange` directly to the game state.
    ///
    /// > Important: **Internal/Test Use Only**: This method is provided for internal engine
    ///   operations and testing scenarios where direct state manipulation is necessary. Game
    ///   developers should use the action handler system (`ActionResult.changes`) rather
    ///   than calling this method directly.
    ///
    /// This method bypasses the normal action handler pipeline, including:
    /// - Before/after turn event handlers
    /// - Action validation
    /// - Side effect processing
    ///
    /// Use this method only when:
    /// - Setting up test scenarios that require specific game states
    /// - Internal engine operations that need direct state access
    /// - Implementing low-level engine functionality
    ///
    /// - Parameter change: The `StateChange` to apply to the game state.
    /// - Throws: Re-throws any errors from `GameState.apply()`, including validation failures.
    func apply(_ changes: StateChange?...) async throws {
        for change in changes.compactMap(\.self) {
            try await applyWithDynamicValidation(change)
        }
    }

    /// Executes multiple string commands in sequence.
    ///
    /// This is a convenience method for executing several commands one after another.
    /// Each command is processed independently through the normal game engine pipeline.
    ///
    /// - Parameter input: A variadic list of command strings to execute in order.
    /// - Throws: Re-throws any errors from individual command execution.
    @_disfavoredOverload
    func execute(_ input: String...) async throws {
        for command in input {
            try await execute(command)
        }
    }

    /// Executes a string command through the game engine's parser and action handler system.
    ///
    /// This method processes user input by:
    /// 1. Checking for pending conversation questions and handling responses
    /// 2. Parsing the input string into a structured command
    /// 3. Executing the parsed command through the action handler system
    /// 4. Processing any resulting state changes and side effects
    ///
    /// The command execution includes full game engine processing with before/after
    /// turn handlers, action validation, and side effect processing.
    ///
    /// - Parameters:
    ///   - input: The command string to parse and execute (e.g., "go north", "take lamp").
    ///   - times: Number of times to repeat the command execution (default: 1).
    /// - Throws: Re-throws parsing errors, validation errors, or execution errors from the action handler system.
    func execute(_ input: String, times: Int = 1) async throws {
        for _ in 0..<times {
            // Record the command prompt for output transcript
            await ioHandler.print("> \(input)", style: .input, newline: true)

            // Check for pending questions first
            if await ConversationManager.hasPendingQuestion(engine: self) {
                if let questionResponse = await ConversationManager.processQuestionResponse(
                    input: input,
                    engine: self
                ) {
                    // Question was handled, apply the result
                    if let message = questionResponse.message {
                        await ioHandler.print(message)
                    }

                    // Apply state changes
                    for change in questionResponse.changes {
                        do {
                            try await applyWithDynamicValidation(change)
                        } catch {
                            logError("Error applying question response state change: \(error)")
                        }
                    }

                    // Process side effects
                    for effect in questionResponse.effects {
                        // Handle side effects (placeholder for now)
                        logWarning("Side effect processing not yet implemented: \(effect)")
                    }

                    // Question was handled, skip normal command processing
                    continue
                } else {
                    // No question response generated - clear the question and continue with normal processing
                    let clearChanges = await ConversationManager.clearQuestion(engine: self)
                    for change in clearChanges {
                        do {
                            try await applyWithDynamicValidation(change)
                        } catch {
                            logError("Error clearing question state: \(error)")
                        }
                    }
                    // Continue to normal command processing below
                }
            }

            // Parse and execute normal commands
            let parseResult = parser.parse(
                input: input,
                vocabulary: gameState.vocabulary,
                gameState: gameState
            )

            switch parseResult {
            case .success(let command):
                // Allow quit command to be processed by QuitActionHandler
                if shouldQuit { return }

                await execute(command: command)

            case .failure(let error):
                await report(parseError: error)
            }
        }
    }

    /// Retrieves the complete history of all `StateChange`s applied to the `gameState`
    /// since the game started or the state was last loaded.
    ///
    /// This can be useful for debugging or advanced game mechanics that need to inspect
    /// past state transitions.
    ///
    /// - Returns: An array of `StateChange` objects, in the order they were applied.
    func changeHistory() -> [StateChange] {
        gameState.changeHistory
    }
}
