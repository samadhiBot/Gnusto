import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct LocationAttributeID: GnustoID {
    public let rawValue: String

    /// Initializes a `AttributeID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Attribute ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

public extension LocationAttributeID {
    /// The available exits from a location.
    static let exits = LocationAttributeID("exits")

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    static let localGlobals = LocationAttributeID("localGlobals")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    static let name = LocationAttributeID("name")
}

// MARK: - Descriptions

public extension LocationAttributeID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    static let firstDescription = LocationAttributeID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    static let description = LocationAttributeID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    static let shortDescription = LocationAttributeID("shortDescription")

//    /// Text that can be read from an item (ZIL `RTEXT/TEXT`).
//    static let readText = LocationAttributeID("readText")
//
//    /// Text that can be read from an item while holding it (ZILF `TEXT-HELD`).
//    static let readWhileHeldText = LocationAttributeID("readWhileHeldText")
}

// MARK: - Location Flags

public extension LocationAttributeID {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    static let inherentlyLit = LocationAttributeID("inherentlyLit")

    /// Location is considered outdoors.
    static let isOutside = LocationAttributeID("isOutside")

    /// Location is sacred, thus profanity is discouraged or disallowed here.
    static let isSacred = LocationAttributeID("isSacred")

    /// RMUNGBIT: Location description has been changed.
    static let isChanged = LocationAttributeID("isChanged")

    /// RLANDBIT: Location is land, not water/air.
    static let isLand = LocationAttributeID("isLand")

    /// Indicates whether an entity is currently considered "lit".
    static let isLit = LocationAttributeID("isLit")

    /// The player has visited this location previously.
    static let isVisited = LocationAttributeID("isVisited")

    /// The location contains or is primarily composed of water.
    static let isWater = LocationAttributeID("locationIsWater")

    /// Magic does not function here.
    static let breaksMagic = LocationAttributeID("breaksMagic")
}
