import Foundation

/// Represents an attribute of a `Location`.
public struct LocationAttribute: Attribute {
    public let id: AttributeID
    public let rawValue: StateValue

    public init(
        id: AttributeID,
        rawValue: StateValue
    ) {
        self.id = id
        self.rawValue = rawValue
    }
}

// MARK: - Value attributes

extension LocationAttribute {
    /// The location's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The location's primary detailed description.
    /// - Returns: A .description attribute.
    static func description(_ description: String) -> LocationAttribute {
        LocationAttribute(
            id: .description,
            rawValue: .string(description)
        )
    }
    
    /// The available exits from a location.
    ///
    /// - Parameter exits: The available exits from a location.
    /// - Returns: A .exits attribute.
    static func exits(_ exits: [Direction: Exit]) -> LocationAttribute {
        LocationAttribute(
            id: .exits,
            rawValue: .exits(exits)
        )
    }

    /// Items that are considered local to a location (e.g. fixed scenery) and always in scope.
    ///
    /// - Parameter localGlobals: Items that are considered local to a location.
    /// - Returns: A .localGlobals attribute.
    static func localGlobals(_ localGlobals: ItemID...) -> LocationAttribute {
        LocationAttribute(
            id: .localGlobals,
            rawValue: .itemIDSet(Set(localGlobals))
        )
    }

    /// The primary name used to refer to the location (ZIL: `DESC`).
    ///
    /// - Parameter name: The primary name used to refer to the location.
    /// - Returns: A .name attribute.
    static func name(_ name: String) -> LocationAttribute {
        LocationAttribute(
            id: .name,
            rawValue: .string(name)
        )
    }
}

// MARK: - Flag attributes

extension LocationAttribute {
    /// Location is inherently lit (e.g., outdoors) (ZIL `RLIGHTBIT`).
    static var inherentlyLit: LocationAttribute {
        LocationAttribute(id: .inherentlyLit, rawValue: true)
    }

    /// Location is considered outdoors.
    static var isOutside: LocationAttribute {
        LocationAttribute(id: .isOutside, rawValue: true)
    }

    /// Location is sacred, thus profanity is discouraged or disallowed here.
    static var isSacred: LocationAttribute {
        LocationAttribute(id: .isSacred, rawValue: true)
    }

    /// Location description has been changed (ZIL `RMUNGBIT`).
    static var isChanged: LocationAttribute {
        LocationAttribute(id: .isChanged, rawValue: true)
    }

    /// Location is land, not water/air (ZIL `RLANDBIT`).
    static var isLand: LocationAttribute {
        LocationAttribute(id: .isLand, rawValue: true)
    }

    /// The player has visited this location previously.
    static var isVisited: LocationAttribute {
        LocationAttribute(id: .isVisited, rawValue: true)
    }

    /// The location contains or is primarily composed of water.
    static var isWater: LocationAttribute {
        LocationAttribute(id: .isWater, rawValue: true)
    }

    /// Magic does not function here.
    static var breaksMagic: LocationAttribute {
        LocationAttribute(id: .breaksMagic, rawValue: true)
    }
}
