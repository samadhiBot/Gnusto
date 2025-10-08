import Foundation

// MARK: - Game Loop

extension GameEngine {
    /// Starts and runs the main game loop.
    ///
    /// This method is the primary entry point for beginning and playing the game.
    /// It performs the following sequence:
    /// 1. Sets up the `IOHandler` (e.g., preparing the console or UI).
    /// 2. Prints the game's title and introduction message.
    /// 3. Marks the player's starting location as visited and describes it.
    /// 4. Enters the main turn-based loop, which continues until `shouldQuit` becomes `true`.
    ///    Each iteration of the loop involves:
    ///    a. Displaying the status line (current location, score, moves) via `showStatus()`.
    ///    b. Processing a single player turn via `processTurn()`.
    /// 5. After the loop terminates (e.g., player quits), performs teardown for the `IOHandler`.
    ///
    /// Game developers typically do not call this method directly after initialization;
    /// it is intended to be the engine's top-level execution flow.
    public func run() async {
        await ioHandler.setup()

        // Game initialization and main loop
        repeat {
            // Print title and introduction (only on first start or restart)
            await ioHandler.print(title, style: .strong)
            await ioHandler.print(introduction)

            do {
                try await printCurrentLocationDescription(forceFullDescription: true)
            } catch {
                logError("\(error)")
            }

            // Main game loop
            while !shouldQuit && !shouldRestart {
                do {
                    try await showStatus()
                    try await processTurn()
                } catch {
                    logError("\(error)")
                }
            }

            // Handle restart if requested
            if shouldRestart {
                await ioHandler.print(
                    messenger.restarting()
                )
                await resetGameState()
                // Continue the outer loop to restart the game
            }

        } while shouldRestart

        await ioHandler.teardown()
    }
}

// MARK: - Internal helpers

extension GameEngine {
    /// Processes a single turn of the game, including player input, parsing, command execution, and clock ticks.
    ///
    /// This method orchestrates the core sequence of events within a single game turn:
    /// 1. Executes `beforeTurn` middleware hooks
    /// 2. Prompts the player for input via the `IOHandler`.
    ///    If input is `nil` (e.g., EOF) or explicitly "quit", `shouldQuit` is set, and the turn ends.
    /// 3. Parses the player's input string into a structured `Command` using the `parser`.
    /// 4. Executes `beforeCommandExecution` middleware hooks (can modify or skip command)
    /// 5. If parsing is successful:
    ///    a. If the command is to quit or `shouldQuit` is set, the turn ends.
    ///    b. Calls `execute(command:)` to process the command through event and action handlers.
    /// 6. Executes `afterCommandExecution` middleware hooks (can add side effects)
    /// 7. Checks for player death
    /// 8. Executes `beforeTimeAdvancement` middleware hooks
    /// 9. Advances game time by calling `tickClock()`, which processes active fuses and daemons.
    /// 10. Executes `afterTurn` middleware hooks
    ///
    /// Errors during turn processing are logged.
    func processTurn(_ testInput: String? = nil) async throws {
        if shouldQuit || shouldRestart { return }

        // BEFORE TURN MIDDLEWARE HOOK
        let beforeTurnResult = try await executeBeforeTurnMiddleware()
        if case .handled(let result) = beforeTurnResult {
            if let result {
                try await processActionResult(result)
            }
            // Middleware handled the entire turn
            return
        }

        // 1. Get Player Input (or enqueued test input)
        let input: String
        if let testInput {
            await ioHandler.print("> \(testInput)", style: .input, newline: true)
            input = testInput
        } else {
            guard let realInput = await ioHandler.readLine(prompt: "> ") else {
                await ioHandler.print("\n\(messenger.goodbye())")
                shouldQuit = true
                return
            }
            input = realInput
        }

        // 2. Check for pending questions first
        if await conversationManager.hasPendingQuestion {
            if let questionResponse = try await conversationManager.processResponse(
                input, with: self
            ) {
                // Question was handled, apply the result
                if let message = questionResponse.message {
                    await ioHandler.print(message)
                }

                // Apply state changes
                try applyActionResultChanges(questionResponse.changes)

                // Process side effects
                for effect in questionResponse.effects {
                    // Handle side effects (placeholder for now)
                    logWarning("Side effect processing not yet implemented: \(effect)")
                }

                // Question was handled, skip normal command processing
                return

            } else {
                // No question response generated - clear the question and continue with normal processing
                await conversationManager.clearQuestion()
            }
        }

        // 3. Check for disambiguation responses when no pending question but recent disambiguation
        if let disambiguationContext = lastDisambiguationContext,
            await tryHandleDisambiguationResponse(
                input: input,
                context: disambiguationContext
            )
        {
            // Disambiguation response was handled, skip normal command processing
            return
        }

        // 4. Parse Input
        let parseResult = try await parser.parse(
            input: input,
            vocabulary: vocabulary,
            engine: self
        )

        // 5. Execute Command or Handle Error
        var shouldConsumeTurn = true  // Default to consuming turn
        var commandResult: ActionResult?

        switch parseResult {
        case .success(let command):
            // Allow quit command to be processed by QuitActionHandler
            // Only exit early if shouldQuit is already set
            if shouldQuit { return }

            // BEFORE COMMAND MIDDLEWARE HOOK
            let middlewareResult = try await executeBeforeCommandMiddleware(command: command)

            switch middlewareResult {
            case .continue(let finalCommand):
                // Execute command normally
                shouldConsumeTurn = try await execute(command: finalCommand)

                // Capture the result for middleware
                // Note: execute() currently returns Bool, not ActionResult
                // The result is processed internally, so we create an empty result
                commandResult = ActionResult(message: nil, changes: [], effects: [])

            case .skip(let result):
                // Middleware handled the command (e.g., combat turn)
                if let result {
                    try await processActionResult(result)
                    commandResult = result
                }
                // Turn is consumed when middleware handles it
                shouldConsumeTurn = true
            }

        case .failure(let error):
            await report(parseError: error, originalInput: input)
            // Parse errors consume turns (traditional IF behavior)
            shouldConsumeTurn = true
            commandResult = ActionResult(message: nil, changes: [], effects: [])  // Empty result for middleware
        }

        // AFTER COMMAND MIDDLEWARE HOOK
        // This is where combat checks for hostiles, achievements track progress, etc.
        if let result = commandResult, shouldConsumeTurn {
            // Get the actual command or create a dummy one for parse errors
            let actualCommand: Command
            if case .success(let cmd) = parseResult {
                actualCommand = cmd
            } else {
                // Parse error - create minimal command for middleware
                actualCommand = Command(
                    verb: .examine,  // Use a valid verb
                    directObject: nil,
                    indirectObject: nil,
                    direction: nil,
                    rawInput: input
                )
            }

            let finalResult = try await executeAfterCommandMiddleware(
                command: actualCommand,
                result: result
            )

            // Process any additional effects from middleware
            // Compare by checking if there are any changes
            if !finalResult.changes.isEmpty || !finalResult.effects.isEmpty {
                try await processActionResult(finalResult)
            }
        }

        // 6. Check for player death
        if await isPlayerDead {
            try await handlePlayerDeath()
            return
        }

        // BEFORE TIME ADVANCEMENT MIDDLEWARE HOOK
        if shouldConsumeTurn && !shouldQuit && !shouldRestart {
            let timeResult = try await executeBeforeTimeAdvancementMiddleware()
            if case .handled(let result) = timeResult {
                if let result {
                    try await processActionResult(result)
                }
                // Skip time advancement
            } else {
                // 7. Timed events happen AFTER the player's action is complete
                try await tickClock()
            }
        }

        // AFTER TURN MIDDLEWARE HOOK
        if !shouldQuit && !shouldRestart {
            try await executeAfterTurnMiddleware()
        }
    }

    /// Displays the status line (e.g., current location, score, and turn count)
    /// to the player via the `IOHandler`.
    /// This is called automatically at the start of each turn before `processTurn()`.
    func showStatus() async throws {
        await ioHandler.showStatusLine(
            roomName: player.location.name,
            score: gameState.player.score,
            turns: gameState.player.moves
        )
    }

    /// Handles the player death sequence with score reporting and restart/restore options.
    ///
    /// This follows traditional IF conventions:
    /// 1. Announces death with final score
    /// 2. Offers restart, restore, or quit options
    /// 3. Processes the player's choice
    func handlePlayerDeath() async throws {
        // Display death message and final score
        await ioHandler.print(
            messenger.youHaveDied()
        )

        // Show final score
        let finalScore = gameState.player.score
        let maxScore = gameBlueprint.maximumScore
        let moves = gameState.player.moves

        await ioHandler.print(
            messenger.youScored(final: finalScore, max: maxScore, moves: moves)
        )

        // Offer options
        repeat {
            await ioHandler.print(
                messenger.endOfGameOptions()
            )

            guard let input = await ioHandler.readLine(prompt: "> ") else {
                shouldQuit = true
                return
            }

            let choice = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            switch choice {
            case "restart", "r":
                await ioHandler.print(
                    messenger.restarting()
                )
                shouldRestart = true
                return

            case "restore":
                try await restoreGame()
                return

            case "quit", "q":
                shouldQuit = true
                return

            default:
                await ioHandler.print(
                    messenger.restartRestoreQuit()
                )
            }
        } while true
    }

    /// Resets the game state back to its initial configuration.
    ///
    /// This method recreates the GameState using the stored initial parameters,
    /// effectively resetting all game progress and returning to the starting state.
    func resetGameState() async {
        // Recreate the initial game state from blueprint (vocabulary remains unchanged)
        let (newGameState, _) = await Self.buildInitialGameState(from: gameBlueprint)
        self.gameState = newGameState

        // Reset engine flags
        self.shouldQuit = false
        self.shouldRestart = false

        // Clear disambiguation context
        self.lastDisambiguationContext = nil
        self.lastDisambiguationOptions = nil

        // Reset the conversation manager
        await conversationManager.clearQuestion()

        // Reset middleware state (clear caches, etc.)
        self.standardCombatSystemCache = [:]
    }
}

// MARK: - ParseResult Extension

extension Result where Success == Command, Failure == ParseError {
    /// Returns the successful command, or nil if the result is a failure.
    var success: Command? {
        if case .success(let command) = self {
            return command
        }
        return nil
    }
}
