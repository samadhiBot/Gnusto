import Foundation

/// A container for custom game logic that responds to specific events occurring in relation
/// to an `Item`.
///
/// You define an `ItemEventHandler` by providing a closure that takes the `GameEngine` and
/// an `ItemEvent` as input. This closure can then execute arbitrary game logic and
/// optionally return an `ActionResult` to influence or override the default game flow.
///
/// Item event handlers are typically registered with the `TimeRegistry` to associate
/// them with specific items.
public struct ItemEventHandler: Sendable {
    /// The closure that implements the custom event handling logic.
    /// This is not directly accessed; you provide it during initialization.
    let handle: @Sendable (GameEngine, ItemEvent) async throws -> ActionResult?

    /// Initializes an `ItemEventHandler` with a custom handler closure.
    ///
    /// - Parameter handler: A closure that will be invoked when a relevant `ItemEvent` occurs.
    ///   The closure receives:
    ///   - `engine`: The current `GameEngine` instance, allowing interaction with game state.
    ///   - `event`: The specific `ItemEvent` that triggered this handler.
    ///   It can throw an error if processing fails, and can optionally return an `ActionResult`
    ///   to modify or conclude the current game action (e.g., printing a message, ending the turn).
    ///   If `nil` is returned, the game typically proceeds with its default behavior.
    public init(
        _ handler: @Sendable @escaping (GameEngine, ItemEvent) async throws -> ActionResult?
    ) {
        self.handle = handler
    }
}

/// Represents the specific moments or triggers that can activate an `ItemEventHandler` for an item.
public enum ItemEvent: Sendable {
    /// Triggered before the game engine processes the player's command for the current turn,
    /// specifically in the context of an item that has this event handler.
    ///
    /// The associated `Command` is the one the player has just entered.
    /// Your handler can inspect this command and potentially return an `ActionResult` to
    /// preempt or alter the default command processing for this item.
    case beforeTurn(Command)

    /// Triggered after the game engine has processed the player's command for the current turn,
    /// specifically in the context of an item that has this event handler.
    ///
    /// The associated `Command` is the one the player entered.
    /// This allows the item to react to the outcome of the turn or perform cleanup actions.
    case afterTurn(Command)

    /*
    /// Called when the item is first created or loaded into the game.
    case onInitialize

    /// Called when the item is destroyed or removed from the game.
    case onDestroy
     */
}
