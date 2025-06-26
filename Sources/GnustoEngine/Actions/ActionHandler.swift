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
///
/// The handling of an action can be implemented using either:
///
/// **Modern Approach (Recommended):**
/// - **`process(context:)`**: Unified method that validates prerequisites and executes the action
///   in a single step. This eliminates duplication and is simpler to implement and maintain.
/// - **`postProcess(context:result:)`**: Optional cleanup after the main action completes.
///
/// **Legacy Approach (Deprecated):**
/// - **`validate(context:)`** → **`process(context:)`** → **`postProcess(context:result:)`**
///   The original three-phase approach is still supported for backward compatibility but creates
///   unnecessary duplication and complexity.
///
/// Handlers should be `Sendable` as they are used by the `GameEngine` actor.
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

    /// All words that can match `.verb` in the syntax rules to trigger this action handler.
    ///
    /// The parser treats all of the verb synonym as equivalent when matching player input.
    var verbs: [Verb] { get }

    /// The conceptual actions that this handler represents.
    ///
    /// This allows game logic to check for conceptual actions (like `.lightSource` or `.drop`)
    /// without worrying about the specific verbs used. For example, both "TURN ON LAMP" and
    /// "LIGHT LAMP" might represent the `.lightSource` action.
    ///
    /// A single action handler may represent multiple conceptual actions. For example,
    /// a TurnActionHandler might handle both `.turn` (for "TURN WHEEL") and `.lightSource`
    /// (for "TURN ON LAMP") depending on the syntax pattern used.
    var actions: [Intent] { get }

    /// Whether this verb requires light to execute.
    ///
    /// If `true`, the verb will fail with a "room is dark" message when executed in darkness
    /// (except for light-producing verbs like "turn on"). If `false`, the verb can be used
    /// regardless of lighting conditions.
    var requiresLight: Bool { get }

    // MARK: - Action Processing Methods

    /// Processes the action, performing validation and execution in a single unified step.
    ///
    /// This method should:
    ///   1. Validate all prerequisites (item exists, is accessible, meets requirements)
    ///   2. If validation fails, throw an appropriate `ActionResponse`
    ///   3. If validation passes, execute the action and return an `ActionResult`
    ///
    /// - Parameters:
    ///   - command: The specific parsed `Command` that is currently being executed.
    ///   - engine: A non-isolated reference to the `GameEngine` instance.
    /// - Returns: An `ActionResult` containing the message, state changes, and side effects.
    /// - Throws: `ActionResponse` for expected validation failures, and other errors for
    ///           unexpected issues.
    func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult

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

    /// Default implementation for `verbs`. Returns an empty array.
    ///
    /// Override this property to provide the verbs that can trigger this action handler.
    public var verbs: [Verb] {
        []
    }

    /// Default implementation for `actions`. Returns an empty array.
    ///
    /// Override this property to provide the conceptual actions this handler represents.
    public var actions: [Intent] {
        []
    }

    /// Default implementation for `requiresLight`. Returns `true` for safety.
    ///
    /// Override this property to `false` for verbs that can be used in darkness.
    public var requiresLight: Bool {
        true
    }
}
