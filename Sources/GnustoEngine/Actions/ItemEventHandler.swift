import Foundation

/// A container for custom game logic that responds to specific events occurring in relation
/// to an `Item`.
///
/// You define an `ItemEventHandler` by providing a closure that takes the `GameEngine` and
/// an `ItemEvent` as input. This closure can then execute arbitrary game logic and
/// optionally return an `ActionResult` to influence or override the default game flow.
///
/// Item event handlers are typically registered with the `GameBlueprint` to associate
/// specific items with custom behaviors triggered by game events.
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

    /// Checks if this event is a beforeTurn event with a command that has the specified intent.
    ///
    /// - Parameters:
    ///   - intent: The Intent to check for in the command's verb.
    ///   - result: The closure to execute if the intent matches.
    /// - Returns: The result of the closure if the intent matches, nil otherwise.
    public func whenBeforeTurn(
        intent: Intent,
        result: () -> ActionResult?
    ) -> ActionResult? {
        if case .beforeTurn(let command) = self, command.hasIntent(intent) {
            result()
        } else {
            nil
        }
    }

    /// Checks if this event is a beforeTurn event with a command that has *any* of the
    /// specified intents.
    ///
    /// - Parameters:
    ///   - intents: The Intents to check for in the command's verb.
    ///   - result: The closure to execute if any intent matches.
    /// - Returns: The result of the closure if any intent matches, nil otherwise.
    public func whenBeforeTurn(
        intents: Intent...,
        result: () -> ActionResult?
    ) -> ActionResult? {
        if case .beforeTurn(let command) = self, command.verb.intents.intersects(intents) {
            result()
        } else {
            nil
        }
    }
}
