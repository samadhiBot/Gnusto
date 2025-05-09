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
    /// The item's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The item's primary detailed description.
    /// - Returns: A .longDescription attribute.
    static func longDescription(_ description: String) -> LocationAttribute {
        LocationAttribute(
            id: .longDescription,
            rawValue: .string(description)
        )
    }
}

// MARK: - Flag attributes

extension LocationAttribute {
    /// RLIGHTBIT: Location is inherently lit (e.g., outdoors).
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

    /// RMUNGBIT: Location description has been changed.
    static var isChanged: LocationAttribute {
        LocationAttribute(id: .isChanged, rawValue: true)
    }

    /// RLANDBIT: Location is land, not water/air.
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
