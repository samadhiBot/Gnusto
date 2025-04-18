/// Action handler for the WAIT verb.
struct WaitActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        await engine.output("Time passes.")
        // Waiting usually just consumes a turn, no further state change needed here.
    }
}

/// Action handler for the SCORE verb.
struct ScoreActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        // Use the safe accessor on the engine
        let currentScore = await engine.playerScore()
        let turnCount = await engine.playerMoves()
        await engine.output("Your score is \(currentScore) in \(turnCount) turns.")
    }
}

/// Action handler for the QUIT verb.
struct QuitActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        // TODO: Implement confirmation? ("Are you sure you want to quit?")
        await engine.output("Goodbye!")
        await engine.quitGame() // Signal the engine to stop the game loop
    }
}

/// Action handler for the SMELL verb (default behavior).
struct SmellActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        if command.directObject == nil {
            await engine.output("You smell nothing unusual.")
        } else {
            // If smelling a specific item, give a generic response.
            // Specific items could be handled by onExamineItem or custom ActionHandlers.
            await engine.output("That smells about average.")
        }
    }
}

/// Action handler for the LISTEN verb (default behavior).
struct ListenActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        await engine.output("You hear nothing unusual.")
        // TODO: Could check for specific sounds defined in the room/location?
    }
}

/// Action handler for the TASTE verb (default behavior).
struct TasteActionHandler: ActionHandler {
    func perform(command: Command, engine: GameEngine) async throws {
        guard command.directObject != nil else {
            await engine.output("Taste what?")
            return
        }
        // Generic response. Tasting specific items (like food) would need custom logic.
        await engine.output("That tastes about average.")
    }
}

// TODO: Add handlers for HELP, SAVE, RESTORE, VERBOSE, BRIEF (meta commands)
// TODO: Add basic handlers for DROP, OPEN, CLOSE, READ, WEAR, REMOVE?
