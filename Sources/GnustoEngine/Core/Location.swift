import Foundation

/// Represents a location (room) within the game world.
public struct Location: Codable, Identifiable, Equatable, Sendable {
    /// The unique identifier for this location.
    public let id: LocationID

    /// The display name of the location.
    public var name: String

    /// Defines the connections (exits) from this location to others.
    public var exits: [Direction: Exit]

    /// A dictionary that holds the location's current attributes.
    ///
    /// Some attributes are static under normal circumstances, but any can change when necessary.
    public var attributes: [PropertyID: StateValue]

    // MARK: - Initializer

    public init(
        id: LocationID,
        name: String,
        exits: [Direction: Exit] = [:],
        isLit: Bool = false,
        attributes: [PropertyID: StateValue] = [:]
    ) {
        self.id = id
        self.name = name
        self.exits = exits
        var initial = attributes
        initial[.inherentlyLit] = .bool(isLit)
        self.attributes = initial
    }

    // MARK: - Convenience Accessors

    /// Checks if a boolean flag is set in the location's `attributes`.
    /// - Parameter id: The `PropertyID` of the flag to check.
    /// - Returns: `true` if the flag exists and is set to `true`, `false` otherwise.
    public func hasFlag(_ id: PropertyID) -> Bool {
        attributes[id] == .bool(true)
    }
}
