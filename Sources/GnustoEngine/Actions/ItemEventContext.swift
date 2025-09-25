/// Context object passed to item event handler functions containing the event, subject item, and engine.
///
/// `ItemEventContext` provides event handlers with structured access to the event being processed,
/// the item it's associated with, and the game engine for accessing other game state. This eliminates
/// the need for event handlers to manually retrieve the subject item.
///
/// Example usage:
/// ```swift
/// static let lampHandler = ItemEventHandler(for: .lamp) {
///     before(.turnOn) { context, command in
///         if await context.item.hasFlag(.isBroken) {
///             ActionResult("The lamp is broken and won't turn on.")
///         } else {
///             ActionResult(
///                 "The lamp flickers to life.",
///                 context.item.setFlag(.isOn)
///             )
///         }
///     }
///     }
/// }
/// ```
public struct ItemEventContext: Sendable {
    /// The event being processed.
    public let event: ItemEvent

    /// The item proxy for the item this event is associated with.
    ///
    /// This is the subject item that the event handler is registered for,
    /// eliminating the need to look it up manually in the handler.
    public let item: ItemProxy

    /// Reference to the game engine for accessing other game state and operations.
    ///
    /// Use this to access other items, locations, player state, or any other
    /// game operations needed for processing the event.
    nonisolated public let engine: GameEngine

    /// Creates a new item event context.
    ///
    /// - Parameters:
    ///   - event: The event being processed
    ///   - item: The item proxy for the subject item
    ///   - engine: The game engine for accessing other state and operations
    public init(
        event: ItemEvent,
        item: ItemProxy,
        engine: GameEngine
    ) {
        self.event = event
        self.item = item
        self.engine = engine
    }
}

extension ItemEventContext {
    /// Convenience accessor for getting an item proxy by ID.
    ///
    /// Provides direct access to any item in the game through the engine,
    /// allowing event handlers to easily reference and manipulate other items.
    ///
    /// - Parameter itemID: The unique identifier of the item to retrieve
    /// - Returns: A proxy for the specified item
    public func item(_ itemID: ItemID) async -> ItemProxy {
        await engine.item(itemID)
    }

    /// Convenience accessor for getting a location proxy by ID.
    ///
    /// Provides direct access to any location in the game through the engine,
    /// allowing event handlers to easily reference and manipulate other locations.
    ///
    /// - Parameter locationID: The unique identifier of the location to retrieve
    /// - Returns: A proxy for the specified location
    public func location(_ locationID: LocationID) async -> LocationProxy {
        await engine.location(locationID)
    }

    /// Convenience accessor for the game engine's message provider.
    ///
    /// Provides direct access to the messenger for generating localized text
    /// responses within event handlers.
    public var msg: StandardMessenger {
        engine.messenger
    }

    /// Convenience accessor for the game engine's player.
    ///
    /// Provides direct access to the player proxy for accessing player state
    /// and operations within event handlers.
    public var player: PlayerProxy {
        get async {
            await engine.player
        }
    }
}
