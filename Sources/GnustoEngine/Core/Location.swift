import Foundation

/// Represents a location (room) within the game world.
public struct Location: Codable, Identifiable, Equatable, Sendable {
    /// The unique identifier for this location.
    public let id: LocationID

    /// The display name of the location.
    public var name: String

    /// A dictionary that holds the location's current attributes.
    ///
    /// Some attributes are static under normal circumstances, but any can change when necessary.
    public var attributes: [AttributeID: StateValue]

    // MARK: - Initializer

    public init(
        id: LocationID,
        name: String,
        _ attributes: LocationAttribute...
    ) {
        self.id = id
        self.name = name
        self.attributes = Dictionary(
            uniqueKeysWithValues: attributes.map { ($0.id, $0.rawValue) }
        )
    }

    @available(*, deprecated,
        renamed: "init(id:name:description:exits:_:)",
        message: "Please switch to the new syntax."
    )
    public init(
        id: LocationID,
        name: String,
        description: String? = nil,
        exits: [Direction: Exit] = [:],
        isLit: Bool = false,
        attributes: [AttributeID: StateValue] = [:]
    ) {
        self.id = id
        self.name = name
        self.attributes = attributes
        if let description {
            assert(attributes[.description] == nil, "Long description defined twice.")
            self.attributes[.description] = .string(description)
        }
        if !exits.isEmpty {
            self.attributes[.locationExits] = .locationExits(exits)
        }
        self.attributes[.inherentlyLit] = .bool(
            isLit || (attributes[.inherentlyLit]?.toBool ?? false)
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
}
