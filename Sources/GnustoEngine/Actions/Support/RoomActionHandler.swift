import Foundation

/// Type alias for a closure that handles room-specific actions based on game events.
/// - Parameters:
///   - engine: The `GameEngine` instance.
///   - message: The `RoomActionMessage` indicating the event type.
/// - Returns: `true` if the handler fully handled the action (potentially blocking default behavior), `false` otherwise.
/// - Throws: Allows handlers to throw errors if needed.
public typealias RoomActionHandler = @MainActor @Sendable (GameEngine, RoomActionMessage) async throws -> Bool

/// Represents the different events that can trigger a RoomActionHandler.
public enum RoomActionMessage: Sendable {
    /// Called before processing the player's command for the turn.
    /// The handler can potentially prevent the default command execution by returning `true`.
    case beforeTurn(Command)

    /// Called after processing the player's command for the turn.
    case afterTurn(Command)

    /// Called when the player successfully enters the location.
    case onEnter

    // Future ZIL message types: M-LOOK, M-FLASH, etc.
}
