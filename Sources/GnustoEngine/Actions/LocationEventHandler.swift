import Foundation

/// A container for custom game logic that responds to specific events occurring in relation
/// to a `Location`.
///
/// You define a `LocationEventHandler` by providing a closure that takes the `GameEngine`
/// and a `LocationEvent` as input. This closure can then execute arbitrary game logic
/// and optionally return an `ActionResult` to influence or override the default game flow.
///
/// Location event handlers are typically registered with the `TimeRegistry` to associate
/// them with specific locations.
public struct LocationEventHandler: Sendable {
    /// The closure that implements the custom event handling logic.
    /// This is not directly accessed; you provide it during initialization.
    let handle: @Sendable (GameEngine, LocationEvent) async throws -> ActionResult?

    /// Initializes a `LocationEventHandler` with a custom handler closure.
    ///
    /// - Parameter handler: A closure that will be invoked when a relevant `LocationEvent` occurs.
    ///   The closure receives:
    ///   - `engine`: The current `GameEngine` instance, allowing interaction with game state.
    ///   - `event`: The specific `LocationEvent` that triggered this handler.
    ///   It can throw an error if processing fails, and can optionally return an `ActionResult`
    ///   to modify or conclude the current game action (e.g., printing a message, ending the turn).
    ///   If `nil` is returned, the game typically proceeds with its default behavior.
    public init(
        _ handler: @Sendable @escaping (GameEngine, LocationEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }
}

/// Represents the specific moments or triggers that can activate a `LocationEventHandler`.
///
/// Note: The ZIL concept of "Room Actions" (often triggered by messages like `M-LOOK`,
/// `M-FLASH`) is analogous to `LocationEventHandler` in Gnusto. Some event types here
/// directly map to those concepts, while others provide more general hooks.
public enum LocationEvent: Sendable {
    /// Triggered before the game engine processes the player's command for the current turn,
    /// while the player is in a location that has this event handler.
    ///
    /// The associated `Command` is the one the player has just entered.
    /// Your handler can inspect this command and potentially return an `ActionResult` to
    /// preempt or alter the default command processing.
    case beforeTurn(Command)

    /// Triggered after the game engine has processed the player's command for the current turn,
    /// while the player is in a location that has this event handler.
    ///
    /// The associated `Command` is the one the player entered.
    /// This allows the location to react to the outcome of the turn or perform cleanup actions.
    case afterTurn(Command)

    /// Triggered when the player successfully enters the location that has this event handler.
    /// This typically occurs after any "look" action or movement that results in the player
    /// arriving in this location.
    case onEnter

    // Future ZIL message types: M-LOOK, M-FLASH, etc.
}
