import Foundation

/// Represents a distinct place or room within the game world that the player can visit.
///
/// Each `Location` has a unique `id` (`LocationID`) and a collection of `properties` that
/// define its current state and characteristics (e.g., its name, description, exits to
/// other locations, and whether it's lit).
///
/// Game developers define locations by providing a `LocationID` and a list of initial
/// `LocationProperty`s. Common properties (like `name`, `description`, `exits`)
/// have convenience computed properties for easy access. The raw state of all properties
/// is stored in the `properties` dictionary using `PropertyID` as keys.
///
/// Locations are a fundamental part of the `GameState` and form the map through which
/// the player navigates.
public struct Location: Codable, Identifiable, Hashable, Sendable {
    /// The location's unique `LocationID`, serving as its primary key within the game.
    public let id: LocationID

    /// A dictionary holding the current state of all properties for this location.
    ///
    /// Each key is a `LocationPropertyID` (e.g., `.name`, `.description`, `.exits`) and the value
    /// is a `StateValue` wrapper containing the actual typed data for that property. Game logic
    /// typically interacts with these properties via convenience accessors on `Location` (for
    /// reading) or through `GameEngine` methods (for modifications).
    public var properties: [LocationPropertyID: StateValue]

    /// Creates a new `Location` instance with a given ID and initial properties.
    ///
    /// The `properties` parameter takes a variadic list of `LocationProperty` instances.
    /// `LocationProperty` is a helper enum that encapsulates both the `PropertyID` (the key)
    /// and the initial `StateValue` for a property.
    ///
    /// Example:
    /// ```swift
    /// let livingRoom = Location(
    ///     id: "livingRoom",
    ///     .name("Living Room"),
    ///     .description("A comfortably furnished living room. There are exits to the north and east."),
    ///     .exits(
    ///         .north(.garden),
    ///         .east(.kitchen)
    ///     ),
    ///     .isInherentlyLit // e.g., if lit by default
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - id: The location's unique `LocationID`.
    ///   - properties: A variadic list of `LocationProperty`s defining the location's initial state.
    public init(
        id: LocationID,
        _ properties: LocationProperty...
    ) {
        self.id = id
        self.properties = Dictionary(
            uniqueKeysWithValues: properties.map { ($0.id, $0.rawValue) }
        )
    }

    public func proxy(_ engine: GameEngine) async throws -> LocationProxy {
        try await engine.location(id)
    }
}
