/// Context object passed to location compute functions containing the property ID, location, and game state.
///
/// `LocationComputeContext` provides compute functions with structured access to the property being
/// computed, the location it belongs to, and the current game state. This eliminates the need for
/// compute functions to manually retrieve the location and provides convenient access to common
/// operations like message formatting.
///
/// The context uses the raw `Location` struct rather than `LocationProxy` to avoid circular dependencies
/// during property resolution.
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

    /// The raw location whose property is being computed.
    ///
    /// This is the underlying `Location` struct rather than a `LocationProxy` to avoid
    /// circular dependencies during property resolution. Use this to access
    /// static properties directly via `location.properties[propertyID]`.
    public let location: Location

    /// Reference to the game state for accessing other values.
    ///
    /// Use this to access items, other locations, global flags, or any other
    /// game state needed for computing the property value.
    nonisolated public let gameState: GameState

    /// Reference to the game engine for accessing computed values and messaging.
    nonisolated public let engine: GameEngine

    /// Convenience accessor for the game engine's message provider.
    ///
    /// Provides direct access to the messenger for generating localized text
    /// responses within compute functions.
    public var msg: StandardMessenger {
        engine.messenger
    }

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
        self.location = location
        self.gameState = await engine.gameState
        self.engine = engine
    }
}
