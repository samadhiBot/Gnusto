/// Context object passed to location event handler functions containing the event, subject location, and engine.
///
/// `LocationEventContext` provides event handlers with structured access to the event being processed,
/// the location it's associated with, and the game engine for accessing other game state. This eliminates
/// the need for event handlers to manually retrieve the subject location.
///
/// Example usage:
/// ```swift
/// static let forestHandler = LocationEventHandler { context in
///     return await context.event.match {
///         beforeTurn(verb: .look) { _ in
///             let timeOfDay = try await context.engine.globalValue(.timeOfDay) ?? "day"
///             if timeOfDay == "night" && !await context.location.isLit {
///                 ActionResult("The forest is too dark to see anything.")
///             } else {
///                 ActionResult("Sunlight filters through the ancient trees.")
///             }
///         }
///         whenAfterTurn { _ in
///             // Trigger forest sounds after any action
///             ActionResult("You hear rustling in the bushes.")
///         }
///     }
/// }
/// ```
public struct LocationEventContext: Sendable {
    /// The event being processed.
    public let event: LocationEvent

    /// The location proxy for the location this event is associated with.
    ///
    /// This is the subject location that the event handler is registered for,
    /// eliminating the need to look it up manually in the handler.
    public let location: LocationProxy

    /// Reference to the game engine for accessing other game state and operations.
    ///
    /// Use this to access items, other locations, player state, or any other
    /// game operations needed for processing the event.
    nonisolated public let engine: GameEngine

    /// Convenience accessor for the game engine's message provider.
    ///
    /// Provides direct access to the messenger for generating localized text
    /// responses within event handlers.
    public var msg: StandardMessenger {
        engine.messenger
    }

    /// Creates a new location event context.
    ///
    /// - Parameters:
    ///   - event: The event being processed
    ///   - location: The location proxy for the subject location
    ///   - engine: The game engine for accessing other state and operations
    public init(
        event: LocationEvent,
        location: LocationProxy,
        engine: GameEngine
    ) {
        self.event = event
        self.location = location
        self.engine = engine
    }
}
