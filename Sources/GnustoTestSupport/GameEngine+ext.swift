@testable import GnustoEngine

#if DEBUG

extension GameEngine {
    /// Creates a test instance of `GameEngine` with mock dependencies for unit testing.
    ///
    /// This factory method simplifies test setup by providing sensible defaults for all
    /// dependencies while allowing customization where needed. It automatically creates
    /// a `MockIOHandler` for capturing and verifying game output during tests.
    ///
    /// - Parameters:
    ///   - blueprint: The game blueprint defining the game world and rules. Defaults to `MinimalGame()`.
    ///   - parser: The parser for processing user input. Defaults to `StandardParser()`.
    ///   - ioHandler: Optional custom IO handler. If `nil`, a new `MockIOHandler` is created.
    ///   - filesystemHandler: Handler for filesystem operations. Defaults to `TestFilesystemHandler()`.
    /// - Returns: A tuple containing the configured `GameEngine` and the `MockIOHandler` for output verification.
    public static func test(
        blueprint: GameBlueprint = MinimalGame(),
        parser: Parser = StandardParser(),
        ioHandler: MockIOHandler? = nil,
        filesystemHandler: FilesystemHandler = TestFilesystemHandler()
    ) async -> (GameEngine, MockIOHandler) {
        let game = blueprint
        let inputOutput =
            if let ioHandler {
                ioHandler
            } else {
                await MockIOHandler()
            }
        let engine = await GameEngine(
            blueprint: game,
            parser: parser,
            ioHandler: inputOutput,
            filesystemHandler: filesystemHandler
        )
        return (engine, inputOutput)
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
    public func apply(_ changes: StateChange?...) async throws {
        try applyActionResultChanges(changes)
    }

    /// Executes multiple string commands in sequence.
    ///
    /// This is a convenience method for executing several commands one after another.
    /// Each command is processed independently through the normal game engine pipeline.
    ///
    /// - Parameter inputs: A variadic list of command strings to execute in order.
    /// - Throws: Re-throws any errors from individual command execution.
    @_disfavoredOverload
    public func execute(_ inputs: String...) async throws {
        for input in inputs {
            let commands = input.components(separatedBy: .newlines).filter(\.isNotEmpty)
            for command in commands {
                try await processTurn(command)
            }
        }
    }

    /// Executes a string command multiple times through the game engine's parser and action
    /// handler system.
    ///
    /// Each command is processed independently through the normal game engine pipeline.
    ///
    /// - Parameters:
    ///   - input: The command string to parse and execute (e.g., "go north", "take lamp").
    ///   - times: Number of times to repeat the command execution.
    /// - Throws: Re-throws parsing errors, validation errors, or execution errors from the
    ///           action handler system.
    public func execute(_ input: String, times: Int) async throws {
        for _ in 0..<times {
            try await processTurn(input)
        }
    }

    /// Retrieves the complete history of all `StateChange`s applied to the `gameState`
    /// since the game started, in the order they were applied.
    ///
    /// This can be useful for debugging or advanced game mechanics that need to inspect
    /// past state transitions.
    public var changeHistory: [StateChange] {
        gameState.changeHistory
    }
}

#endif
