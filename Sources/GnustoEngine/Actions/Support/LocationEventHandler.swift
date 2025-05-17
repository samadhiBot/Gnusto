import Foundation

/// Type alias for a closure that handles room-specific actions based on game events.
///
/// - Parameters:
///   - engine: The `GameEngine` instance.
///   - message: The `LocationEvent` indicating the event type.
/// - Returns: An `ActionResult` if the handler handled the action (potentially blocking default
///            behavior), `nil` otherwise. The result can include state changes and a message.
/// - Throws: Allows handlers to throw errors if needed.
public struct LocationEventHandler: Sendable {
    let handle: @Sendable (GameEngine, LocationEvent) async throws -> ActionResult?

    public init(
        _ handler: @Sendable @escaping (GameEngine, LocationEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }
}

/// Represents the different events that can trigger a RoomActionHandler.
public enum LocationEvent: Sendable {
    /// Called before processing the player's command for the turn.
    /// The handler can potentially prevent the default command execution by returning an `ActionResult`.
    case beforeTurn(Command)

    /// Called after processing the player's command for the turn.
    case afterTurn(Command)

    /// Called when the player successfully enters the location.
    case onEnter

    // Future ZIL message types: M-LOOK, M-FLASH, etc.
}
