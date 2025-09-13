import Foundation

// MARK: - Game Loop

extension GameEngine {
    /// Processes a single turn of the game, including player input, parsing, command execution, and clock ticks.
    ///
    /// This method orchestrates the core sequence of events within a single game turn:
    /// 1. Prompts the player for input via the `IOHandler`.
    ///    If input is `nil` (e.g., EOF) or explicitly "quit", `shouldQuit` is set, and the turn ends.
    /// 2. Parses the player's input string into a structured `Command` using the `parser`.
    /// 3. If parsing is successful:
    ///    a. If the command is to quit or `shouldQuit` is set, the turn ends.
    ///    b. Calls `execute(command:)` to process the command through event and action handlers.
    ///    c. If the command was a movement command (`.go`) to an unvisited room, or a command
    ///       that changed the light state (e.g., `.turnOn`, `.turnOff` a light source), it then
    ///       calls `describeCurrentLocation()`.
    /// 4. Advances game time by calling `tickClock()`, which processes active fuses and daemons.
    ///    If `tickClock()` sets `shouldQuit` (e.g., a fuse ends the game), the turn ends.
    /// 5. If parsing fails, reports the `ParseError` to the player via `report(parseError:)`.
    ///
    /// Errors during turn processing are logged.
    func processTurn(_ testInput: String? = nil) async throws {
        if shouldQuit || shouldRestart { return }

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
                for change in questionResponse.changes {
                    try gameState.apply(change)
                }

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
            await tryHandleDisambiguationResponse(input: input, context: disambiguationContext)
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
        switch parseResult {
        case .success(let command):
            // Allow quit command to be processed by QuitActionHandler
            // Only exit early if shouldQuit is already set
            if shouldQuit { return }
            shouldConsumeTurn = try await execute(command: command)

            // When in combat mode, get and process the enemy response
            if isInCombat {
                let combatResult = try await getCombatResult(for: command)
                try await processActionResult(combatResult)
            }

        case .failure(let error):
            await report(parseError: error, originalInput: input)
            // Parse errors consume turns (traditional IF behavior)
            shouldConsumeTurn = true
        }

        // 6. Check for hostile characters after player's action (if turn was consumed)
        if shouldConsumeTurn && !shouldQuit && !shouldRestart && !isInCombat {
            let currentLocation = try await player.location
            let locationItems = try await currentLocation.items

            for creature in locationItems where (try? await creature.isHostileEnemy) == true {
                // Hostile character present - initiate combat
                try await processActionResult(
                    enemyAttacks(
                        enemy: creature,
                        playerWeapon: player.preferredWeapon
                    )
                )
                // Combat mode is now active, break out of loop
                break
            }
        }

        // 7. Check for player death
        if await isPlayerDead {
            try await handlePlayerDeath()
            return
        }

        // 8. Timed events happen AFTER the player's action is complete (or failed).
        if !shouldQuit && !shouldRestart && shouldConsumeTurn {
            do {
                // Only process timed events if the command consumed a turn.
                try await tickClock()
            } catch {
                logError("Error processing timed events: \(error)")
            }
        }
    }

    func processCombatTurn(
        with input: String,
        state combatState: CombatState,
        messageQueue messages: [String]
    ) async throws {
        // Parse the player's combat command
        let parseResult = try await parser.parse(
            input: input,
            vocabulary: vocabulary,
            engine: self
        )

        switch parseResult {
        case .success(let command):
            if shouldQuit { return }

            // Process the complete combat turn (player action + enemy response)
            try await processActionResult(
                getCombatResult(for: command)
            )

        case .failure(let error):
            // Parse errors consume turns (traditional IF behavior)
            // In combat, the CombatSystem handles turn advancement internally
            await report(parseError: error, originalInput: input)
        }

        // Check for player death after combat turn
        if await isPlayerDead {
            try await handlePlayerDeath()
            return
        }

        // Process timed events (daemons/fuses continue even during combat)
        if !shouldQuit && !shouldRestart {
            do {
                try await tickClock()
            } catch {
                logError("Error processing timed events during combat: \(error)")
            }
        }

        return
    }

    /// Displays the status line (e.g., current location, score, and turn count)
    /// to the player via the `IOHandler`.
    /// This is called automatically at the start of each turn before `processTurn()`.
    func showStatus() async throws {
        try await ioHandler.showStatusLine(
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
    private func handlePlayerDeath() async throws {
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

    /// Signals the engine to stop the main game loop and end the game after the
    /// current turn has been fully processed.
    ///
    /// This is the standard way to programmatically quit the game from within an
    /// action handler or game hook.
    public func requestQuit() {
        self.shouldQuit = true
    }

    /// Signals the engine to restart the game after the current turn has been
    /// fully processed.
    ///
    /// This resets the game state back to its initial configuration and starts
    /// the game from the beginning. This is the standard way to programmatically
    /// restart the game from within an action handler or game hook.
    public func requestRestart() {
        self.shouldRestart = true
    }

    /// Resets the game state back to its initial configuration.
    ///
    /// This private method recreates the GameState using the stored initial parameters,
    /// effectively resetting all game progress and returning to the starting state.
    private func resetGameState() async {
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
    }

}
