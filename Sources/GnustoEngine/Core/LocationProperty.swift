import Foundation

/// Represents a property of a `Location`.
public struct LocationProperty: Property {
    public let id: LocationPropertyID
    public let rawValue: StateValue

    public init(
        id: LocationPropertyID,
        rawValue: StateValue
    ) {
        self.id = id
        self.rawValue = rawValue
    }
}

// MARK: - Value properties

extension LocationProperty {
    /// The location's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The location's primary detailed description.
    /// - Returns: A .description property.
    public static func description(_ description: String) -> LocationProperty {
        LocationProperty(
            id: .description,
            rawValue: .string(description)
        )
    }

    /// The description shown the first time a location is seen (ZIL `FDESC`).
    ///
    /// - Parameter firstDescription: The location's first-time description.
    /// - Returns: A .firstDescription property.
    public static func firstDescription(_ firstDescription: String) -> LocationProperty {
        LocationProperty(
            id: .firstDescription,
            rawValue: .string(firstDescription)
        )
    }

    /// The available exits from a location.
    ///
    /// - Parameter exits: The available exits from a location using variadic DirectionalExit syntax.
    /// - Returns: A .exits property.
    public static func exits(_ exits: Exit...) -> LocationProperty {
        LocationProperty(
            id: .exits,
            rawValue: .exits(Set(exits))
        )
    }

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    ///
    /// - Parameter localGlobals: Items that are considered local to a location.
    /// - Returns: A .localGlobals property.
    public static func localGlobals(_ localGlobals: ItemID...) -> LocationProperty {
        LocationProperty(
            id: .localGlobals,
            rawValue: .itemIDSet(Set(localGlobals))
        )
    }

    /// The primary name used to refer to the location (ZIL: `DESC`).
    ///
    /// - Parameter name: The primary name used to refer to the location.
    /// - Returns: A .name property.
    public static func name(_ name: String) -> LocationProperty {
        LocationProperty(
            id: .name,
            rawValue: .string(name)
        )
    }
}

// MARK: - Flag properties

extension LocationProperty {
    /// Location is inherently lit (e.g., outdoors) (ZIL `RLIGHTBIT`).
    public static var inherentlyLit: LocationProperty {
        LocationProperty(id: .inherentlyLit, rawValue: true)
    }

    /// Location is considered outdoors.
    public static var isOutside: LocationProperty {
        LocationProperty(id: .isOutside, rawValue: true)
    }

    /// Location description has been changed (ZIL `RMUNGBIT`).
    public static var isChanged: LocationProperty {
        LocationProperty(id: .isChanged, rawValue: true)
    }

    /// Location is land, not water/air (ZIL `RLANDBIT`).
    public static var isLand: LocationProperty {
        LocationProperty(id: .isLand, rawValue: true)
    }

    /// The player has visited this location previously.
    public static var isVisited: LocationProperty {
        LocationProperty(id: .isVisited, rawValue: true)
    }

    /// The location contains or is primarily composed of water.
    public static var isWater: LocationProperty {
        LocationProperty(id: .isWater, rawValue: true)
    }

    /// NARTICLEBIT: Suppress default article ("a", "the").
    public static var omitArticle: LocationProperty {
        LocationProperty(id: .omitArticle, rawValue: true)
    }
}
