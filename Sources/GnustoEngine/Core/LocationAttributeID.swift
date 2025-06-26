import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct LocationAttributeID: GnustoID {
    public let rawValue: String

    /// Initializes a `AttributeID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Attribute ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

extension LocationAttributeID {
    /// The available exits from a location.
    public static let exits = LocationAttributeID("exits")

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    public static let localGlobals = LocationAttributeID("localGlobals")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public static let name = LocationAttributeID("name")
}

// MARK: - Descriptions

extension LocationAttributeID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    public static let firstDescription = LocationAttributeID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    public static let description = LocationAttributeID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    public static let shortDescription = LocationAttributeID("shortDescription")
}

// MARK: - Location Flags

extension LocationAttributeID {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    public static let inherentlyLit = LocationAttributeID("inherentlyLit")

    /// Location is considered outdoors.
    public static let isOutside = LocationAttributeID("isOutside")

    /// Location is sacred, thus profanity is discouraged or disallowed here.
    public static let isSacred = LocationAttributeID("isSacred")

    /// RMUNGBIT: Location description has been changed.
    public static let isChanged = LocationAttributeID("isChanged")

    /// RLANDBIT: Location is land, not water/air.
    public static let isLand = LocationAttributeID("isLand")

    /// Indicates whether an entity is currently considered "lit".
    public static let isLit = LocationAttributeID("isLit")

    /// The player has visited this location previously.
    public static let isVisited = LocationAttributeID("isVisited")

    /// The location contains or is primarily composed of water.
    public static let isWater = LocationAttributeID("locationIsWater")

    /// Magic does not function here.
    public static let breaksMagic = LocationAttributeID("breaksMagic")
}
