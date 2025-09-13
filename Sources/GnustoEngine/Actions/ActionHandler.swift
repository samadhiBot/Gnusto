import Foundation

/// Defines the blueprint for handling a specific game verb (e.g., "take", "open", "go").
///
/// Implement this protocol to create custom logic for how game actions are validated,
/// processed, and how their results are handled. The `GameEngine` uses `ActionHandler`
/// instances (provided via `GameBlueprint.customActionHandlers` or the engine's default
/// handlers) to execute parsed player `Command`s.
///
/// Each `ActionHandler` is completely self-contained, defining both the verb's parsing
/// rules (via `synonyms`, `syntax`, etc.) and its execution logic. This eliminates
/// the need to coordinate changes across multiple files when adding new verbs.
public protocol ActionHandler: Sendable {
    // MARK: - Verb Definition Properties

    /// Syntax patterns that this verb accepts.
    ///
    /// Each `SyntaxRule` defines a valid command structure for this verb, such as:
    /// - `.match(.verb)` for verbs without objects (e.g., "inventory")
    /// - `.match(.verb, .directObject)` for verbs with one object (e.g., "take sword")
    /// - `.match(.verb, .directObject, .with, .indirectObject)` for complex patterns
    /// - `.match(.lift, .up, .directObject)` for specific verb matches
    ///
    /// The parser uses these rules to validate and structure player input.
    var syntax: [SyntaxRule] { get }

    /// All of the verb synonyms that can match `.verb` in the syntax rules to trigger this action handler.
    ///
    /// The parser treats all of the verb synonym as equivalent when matching player input.
    var synonyms: [Verb] { get }

    /// Whether this verb requires light to execute.
    ///
    /// If `true`, the verb will fail with a "room is dark" message when executed in darkness
    /// (except for light-producing verbs like "turn on"). If `false`, the verb can be used
    /// regardless of lighting conditions.
    var requiresLight: Bool { get }

    /// Whether this verb consumes a turn when executed.
    ///
    /// If `true`, executing this command will increment the player's move counter and trigger
    /// timed events (fuses and daemons). If `false`, the command is considered a "meta-command"
    /// that doesn't advance game time.
    ///
    /// Set this to `false` for commands like SAVE, SCORE, BRIEF, VERBOSE, HELP, QUIT, etc.
    /// that provide information or change settings without affecting the game world.
    var consumesTurn: Bool { get }

    // MARK: - Action Processing Methods

    /// Processes the action, performing validation and execution in a single unified step.
    ///
    /// This method should:
    ///   1. Validate all prerequisites (item exists, is accessible, meets requirements)
    ///   2. If validation fails, throw an appropriate `ActionResponse`
    ///   3. If validation passes, execute the action and return an `ActionResult`
    ///
    /// - Parameters:
    ///   - context: The context object containing the parsed command and game engine reference.
    /// - Returns: An `ActionResult` containing the message, state changes, and side effects.
    /// - Throws: `ActionResponse` for expected validation failures, and other errors for
    ///           unexpected issues.
    func process(context: ActionContext) async throws -> ActionResult

    /// Handles any follow-up effects or cleanup after the `process` step has completed
    /// and its `ActionResult` has been initially handled by the engine.
    ///
    /// The `GameEngine` usually applies `StateChange`s and prints the primary message from
    /// the `ActionResult` *before* calling this method. `postProcess` provides an opportunity
    /// for actions that need to occur after these main effects, such as printing additional
    /// messages, triggering sounds, or performing complex state updates that depend on the
    /// just-applied changes. The default implementation of this method does nothing.
    ///
    /// - Parameters:
    ///   - command: The specific parsed `Command` that is currently being executed.
    ///   - engine: A non-isolated reference to the `GameEngine` instance.
    ///   - result: The `ActionResult` that was returned by the `process` step.
    /// - Throws: An `Error` if post-processing encounters a problem. This is generally
    ///           less common than throwing from `validate` or `process`.
    func postProcess(
        command: Command,
        engine: GameEngine,
        result: ActionResult
    ) async throws
}

// MARK: - Default Implementation

extension ActionHandler {
    /// Default implementation for `postProcess`. Does nothing.
    ///
    /// This optional step allows handlers to implement custom logic that should execute
    /// after the `process` method returns its `ActionResult`, and after the `GameEngine`
    /// has applied the primary state changes and printed the main message from that result.
    /// Most handlers may not need to override this.
    public func postProcess(
        command: Command,
        engine: GameEngine,
        result: ActionResult
    ) async throws {
        // Default: Do nothing
    }

    /// Default implementation for `synonyms`. Returns an empty array.
    ///
    /// Override this property to provide the synonyms that can trigger this action handler.
    public var synonyms: [Verb] {
        []
    }

    /// Default implementation for `requiresLight`. Returns `true` for safety.
    ///
    /// Override this property to `false` for verbs that can be used in darkness.
    public var requiresLight: Bool {
        true
    }

    /// Default implementation for `consumesTurn`. Returns `true` by default.
    ///
    /// Override this property to `false` for meta-commands that shouldn't advance game time.
    public var consumesTurn: Bool {
        true
    }
}
