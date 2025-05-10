import Foundation

/// Represents a location (room) within the game world.
public struct Location: Codable, Identifiable, Equatable, Sendable {
    /// The unique identifier for this location.
    public let id: LocationID

    /// A dictionary that holds all of the location's mutable attributes.
    public var attributes: [AttributeID: StateValue]

    // MARK: - Initializer

    /// Creates a new `Location` instance.
    ///
    /// - Parameters:
    ///   - id: The location's unique identifier.
    ///   - attributes: All of the location's attributes.
    public init(
        id: LocationID,
        _ attributes: LocationAttribute...
    ) {
        self.id = id
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    // MARK: - Convenience Accessors

    /// Defines the connections (exits) from this location to others.
    public var exits: [Direction: Exit] {
        attributes[.locationExits]?.toLocationExits ?? [:]
    }

    /// Checks if a flag is set in the location's `attributes`.
    ///
    /// - Parameter id: The `AttributeID` of the flag to check.
    /// - Returns: `true` if the flag is set to `true`, or `false` otherwise.
    public func hasFlag(_ id: AttributeID) -> Bool {
        attributes[id] == true
    }

    /// Checks whether the location is inherently lit, such as a location lit by sunlight.
    ///
    /// - Returns: Whether the location is inherently lit.
    public func isInherentlyLit() -> Bool {
        attributes[.inherentlyLit]?.toBool ?? false
    }

    /// <#Description#>
    public var localGlobals: Set<ItemID> {
        attributes[.localGlobals]?.toItemIDs ?? []
    }

    /// The display name of the location.
    public var name: String {
        attributes[.name]?.toString ?? id.rawValue
    }
}
