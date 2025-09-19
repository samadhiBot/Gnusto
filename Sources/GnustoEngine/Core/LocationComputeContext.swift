/// Context object passed to location compute functions containing the property ID, location,
/// and game state.
///
/// `LocationComputeContext` provides compute functions with structured access to the property being
/// computed, the location it belongs to, and the current game state. This eliminates the need for
/// compute functions to manually retrieve the location and provides convenient access to common
/// operations like message formatting.
///
/// Example usage:
/// ```swift
/// static let enchantedForestComputer = LocationComputer { context in
///     switch context.propertyID {
///     case .description:
///         let timeOfDay = try await context.gameState.value(of: .timeOfDay) ?? "day"
///         let weather = context.location.properties[.weather]?.stringValue ?? "clear"
///         return .string(timeOfDay == "night" ? "Dark woods loom." : "Sunlight filters through trees.")
///     default:
///         return nil
///     }
/// }
/// ```
public struct LocationComputeContext: Sendable {
    /// The property being computed.
    public let propertyID: LocationPropertyID

    /// The location whose property is being computed.
    public let location: LocationProxy

    /// Reference to the game engine for accessing computed values and messaging.
    nonisolated public let engine: GameEngine

    /// Creates a new location compute context.
    ///
    /// - Parameters:
    ///   - propertyID: The property being computed
    ///   - location: The raw location whose property is being computed
    ///   - engine: The game engine for accessing computed values and messaging
    public init(
        propertyID: LocationPropertyID,
        location: Location,
        engine: GameEngine
    ) async {
        self.propertyID = propertyID
        self.location = LocationProxy(location: location, engine: engine)
        self.engine = engine
    }
}

extension LocationComputeContext {
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
    /// responses within compute functions.
    public var msg: StandardMessenger {
        engine.messenger
    }
}
