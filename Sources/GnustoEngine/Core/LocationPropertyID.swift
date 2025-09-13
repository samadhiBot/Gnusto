import Foundation

/// A unique identifier for a standard or dynamic property within the game.
public struct LocationPropertyID: GnustoID {
    public let rawValue: String

    /// Initializes a `PropertyID` with a raw string value.
    /// - Parameter rawValue: The string value for the ID.
    public init(rawValue: String) {
        assert(rawValue.isNotEmpty, "Property ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - General Property IDs

extension LocationPropertyID {
    /// The available exits from a location.
    public static let exits = LocationPropertyID("exits")

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    public static let localGlobals = LocationPropertyID("localGlobals")

    /// The primary noun used to refer to the item (ZIL: `DESC`).
    public static let name = LocationPropertyID("name")
}

// MARK: - Descriptions

extension LocationPropertyID {
    /// The description shown the first time an item is seen (ZIL `FDESC`).
    public static let firstDescription = LocationPropertyID("firstDescription")

    /// The primary, detailed description (ZIL `LDESC`).
    public static let description = LocationPropertyID("description")

    /// The shorter description used in lists or brief mentions (ZIL `SDESC`).
    public static let shortDescription = LocationPropertyID("shortDescription")
}

// MARK: - Location Flags

extension LocationPropertyID {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
    public static let inherentlyLit = LocationPropertyID("inherentlyLit")

    /// Location is considered outdoors.
    public static let isOutside = LocationPropertyID("isOutside")

    /// RMUNGBIT: Location description has been changed.
    public static let isChanged = LocationPropertyID("isChanged")

    /// RLANDBIT: Location is land, not water/air.
    public static let isLand = LocationPropertyID("isLand")

    /// Indicates whether an entity is currently considered "lit".
    public static let isLit = LocationPropertyID("isLit")

    /// The player has visited this location previously.
    public static let isVisited = LocationPropertyID("isVisited")

    /// The location contains or is primarily composed of water.
    public static let isWater = LocationPropertyID("locationIsWater")

    /// NARTICLEBIT: Omit default article ("a", "the").
    public static let omitArticle = LocationPropertyID("omitArticle")
}
