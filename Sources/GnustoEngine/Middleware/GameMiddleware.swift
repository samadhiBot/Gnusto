import Foundation

/// A middleware component that can intercept and influence game loop execution.
///
/// Middleware operates in a pipeline pattern, where each middleware can:
/// - Observe game state at strategic points in the game loop
/// - Modify or transform command processing results
/// - Short-circuit execution (e.g., take over turn processing entirely)
/// - Persist its own state across save/restore operations
///
/// Middleware is executed in priority order (highest first) and can be configured
/// in the game's blueprint.
///
/// ## Example: Custom Dialogue Middleware
///
/// ```swift
/// struct DialogueMiddleware: GameMiddleware {
///     let priority = 50
///     let stateKey = "dialogue"
///
///     func afterCommandExecution(
///         command: Command,
///         result: ActionResult,
///         context: MiddlewareContext
///     ) async throws -> ActionResult {
///         // Check if player talked to an NPC, trigger dialogue tree
///         if command.hasIntent(.talk), let npc = command.directObject?.itemProxy {
///             return result.appending(startDialogue(with: npc))
///         }
///         return result
///     }
/// }
/// ```
public protocol GameMiddleware: Sendable {
    /// A unique identifier for this middleware, used for state persistence.
    ///
    /// This key is used to store and retrieve middleware-specific state
    /// in the game's save files. It should be unique across all middleware
    /// in your game.
    var stateKey: String { get }

    /// The execution priority of this middleware (higher values run first).
    ///
    /// Use this to control middleware ordering. For example:
    /// - Combat middleware: 100 (needs to intercept turns early)
    /// - Dialogue middleware: 50
    /// - Achievement tracking: 10 (should observe final results)
    ///
    /// Default is 0.
    var priority: Int { get }

    /// Called at the start of each turn, before input is read from the player.
    ///
    /// Use this hook to:
    /// - Display status information (e.g., "You are poisoned!")
    /// - Check for automatic events (e.g., combat continues automatically)
    /// - Short-circuit the entire turn (e.g., player is stunned, skip input)
    ///
    /// - Parameter context: Access to the game engine and current state
    /// - Returns: `.continue` to proceed normally, or `.handled` to skip normal turn processing
    func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult

    /// Called after parsing succeeds, before command execution begins.
    ///
    /// Use this hook to:
    /// - Modify the parsed command (e.g., auto-target nearest enemy)
    /// - Validate command legality (e.g., "You can't move during combat")
    /// - Short-circuit execution (e.g., handle the entire combat turn)
    ///
    /// - Parameters:
    ///   - command: The parsed command about to be executed
    ///   - context: Access to the game engine and current state
    /// - Returns: `.continue` with possibly modified command, or `.skip` to prevent execution
    func beforeCommandExecution(
        command: Command,
        context: MiddlewareContext
    ) async throws -> CommandMiddlewareResult

    /// Called after command execution completes, with the action result.
    ///
    /// Use this hook to:
    /// - Add side effects (e.g., check for hostiles after player moves)
    /// - Modify the result (e.g., add achievement notifications)
    /// - Trigger follow-up events (e.g., enemy responds to attack)
    ///
    /// Middleware can append to or replace the result. The modified result
    /// is passed to the next middleware in the chain.
    ///
    /// - Parameters:
    ///   - command: The command that was executed
    ///   - result: The result of command execution
    ///   - context: Access to the game engine and current state
    /// - Returns: The possibly modified action result
    func afterCommandExecution(
        command: Command,
        result: ActionResult,
        context: MiddlewareContext
    ) async throws -> ActionResult

    /// Called before time advancement (fuses and daemons), after command execution.
    ///
    /// Use this hook to:
    /// - Add custom time-based events
    /// - Prevent time advancement (e.g., during cutscenes)
    /// - Display warnings about upcoming events
    ///
    /// - Parameter context: Access to the game engine and current state
    /// - Returns: `.continue` to allow time advancement, or `.handled` to skip it
    func beforeTimeAdvancement(context: MiddlewareContext) async throws -> MiddlewareResult

    /// Called at the end of each turn, after all other processing completes.
    ///
    /// Use this hook to:
    /// - Update internal middleware state
    /// - Log analytics or debug information
    /// - Trigger end-of-turn effects
    ///
    /// This hook cannot prevent further processing, as the turn is already complete.
    ///
    /// - Parameter context: Access to the game engine and current state
    func afterTurn(context: MiddlewareContext) async throws

    /// Saves the current state of this middleware for game persistence.
    ///
    /// Called when the player saves their game. Return any state that needs
    /// to be preserved, or `nil` if this middleware has no state to save.
    ///
    /// The returned data must be `Codable` for serialization.
    ///
    /// - Parameter context: Access to the game engine and current state
    /// - Returns: Serializable state data, or `nil` if no state to save
    func saveState(context: MiddlewareContext) async throws -> (any Codable & Sendable)?

    /// Restores previously saved middleware state.
    ///
    /// Called when the player restores a saved game. The state data will be
    /// the same type that was returned from `saveState()`.
    ///
    /// - Parameters:
    ///   - state: The previously saved state data
    ///   - context: Access to the game engine and current state
    func restoreState(_ state: any Codable & Sendable, context: MiddlewareContext) async throws
}

// MARK: - Default Implementations

/// Default implementations make all methods optional.
/// Middleware only needs to implement the hooks it actually uses.
extension GameMiddleware {
    public var priority: Int { 0 }

    public func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
        .continue
    }

    public func beforeCommandExecution(
        command: Command,
        context: MiddlewareContext
    ) async throws -> CommandMiddlewareResult {
        .continue(command)
    }

    public func afterCommandExecution(
        command: Command,
        result: ActionResult,
        context: MiddlewareContext
    ) async throws -> ActionResult {
        result
    }

    public func beforeTimeAdvancement(context: MiddlewareContext) async throws -> MiddlewareResult {
        .continue
    }

    public func afterTurn(context: MiddlewareContext) async throws {
        // No-op by default
    }

    public func saveState(context: MiddlewareContext) async throws -> (any Codable & Sendable)? {
        nil
    }

    public func restoreState(_ state: any Codable & Sendable, context: MiddlewareContext)
        async throws
    {
        // No-op by default
    }
}

// MARK: - Context

/// Context passed to middleware hooks with access to game engine and state.
public struct MiddlewareContext: Sendable {
    /// The game engine instance.
    public let engine: GameEngine

    public init(engine: GameEngine) {
        self.engine = engine
    }
}

// MARK: - Results

/// Result from middleware indicating whether to continue normal processing.
public enum MiddlewareResult: Sendable {
    /// Continue with normal processing through the game loop.
    case `continue`

    /// Middleware has handled everything for this phase.
    /// Skip remaining middleware and normal processing.
    ///
    /// The optional `ActionResult` can provide messages, state changes,
    /// or side effects to be processed.
    case handled(ActionResult? = nil)
}

/// Result from command middleware that can modify or skip command execution.
public enum CommandMiddlewareResult: Sendable {
    /// Continue command execution with this (possibly modified) command.
    ///
    /// Middleware can modify the command before passing it along.
    /// For example, auto-targeting the nearest enemy.
    case `continue`(Command)

    /// Skip command execution entirely.
    ///
    /// The optional `ActionResult` can provide messages, state changes,
    /// or side effects to be processed instead of the command.
    case skip(ActionResult? = nil)
}
