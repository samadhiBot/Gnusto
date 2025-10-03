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

    /// Creates a new `Location` with the given `LocationID` and no initial properties.
    ///
    /// Use this initializer when you want to construct an empty location and add properties
    /// later using the fluent helpers (for example: `.name("...")`, `.description("...")`,
    /// `.north(.otherLocation)`, etc.).
    ///
    /// Example:
    /// ```swift
    /// let livingRoom = Location(.livingRoom)
    ///     .name("Living Room")
    ///     .description("A comfortably furnished living room. There are exits to the north and east.")
    ///     .north(.garden)
    ///     .east(.kitchen)
    ///     .isInherentlyLit
    /// ```
    ///
    /// - Parameter id: The unique `LocationID` for the new location.
    public init(_ id: LocationID) {
        self.id = id
        self.properties = [:]
    }

    /// Returns a live proxy for this location from the given game engine.
    ///
    /// The returned `LocationProxy` provides a convenient, engine-backed view of the
    /// location's runtime state and lets systems query or mutate the location through
    /// the engine's APIs. This method asynchronously requests the proxy from the
    /// `GameEngine` and therefore must be awaited.
    ///
    /// - Parameter engine: The `GameEngine` instance that owns the live location state.
    /// - Returns: An asynchronously retrieved `LocationProxy` representing this location.
    public func proxy(_ engine: GameEngine) async -> LocationProxy {
        await engine.location(id)
    }
}

// MARK: - Value properties

extension Location {
    /// The location's primary, detailed description (ZIL `LDESC`).
    ///
    /// - Parameter description: The location's primary detailed description.
    /// - Returns: A .description property.
    public func description(_ description: String) -> Location {
        assigning(.description, to: .string(description))
    }

    /// The description shown the first time a location is seen (ZIL `FDESC`).
    ///
    /// - Parameter firstDescription: The location's first-time description.
    /// - Returns: A .firstDescription property.
    public func firstDescription(_ firstDescription: String) -> Location {
        assigning(.firstDescription, to: .string(firstDescription))
    }

    /// The available exits from a location.
    ///
    /// - Parameter exits: The available exits from a location using variadic DirectionalExit syntax.
    /// - Returns: A .exits property.
    public func exits(_ exits: Exit...) -> Location {
        assigning(.exits, to: .exits(Set(exits)))
    }

    /// The primary name used to refer to the location (ZIL: `DESC`).
    ///
    /// - Parameter name: The primary name used to refer to the location.
    /// - Returns: A .name property.
    public func name(_ name: String) -> Location {
        assigning(.name, to: .string(name))
    }

    /// Items that are considered local to a location, i.e. fixed scenery, and always in scope.
    ///
    /// - Parameter scenery: Items that are considered local to a location.
    /// - Returns: A .scenery property.
    public func scenery(_ scenery: ItemID...) -> Location {
        assigning(.scenery, to: .itemIDSet(Set(scenery)))
    }
}

// MARK: - Flag properties

extension Location {
    /// Location is inherently lit (e.g., outdoors) (ZIL `RLIGHTBIT`).
    public var inherentlyLit: Location {
        assigning(.inherentlyLit, to: true)
    }

    /// Location is considered outdoors.
    public var isOutside: Location {
        assigning(.isOutside, to: true)
    }

    /// Location description has been changed (ZIL `RMUNGBIT`).
    public var isChanged: Location {
        assigning(.isChanged, to: true)
    }

    /// Location is land, not water/air (ZIL `RLANDBIT`).
    public var isLand: Location {
        assigning(.isLand, to: true)
    }

    /// The player has visited this location previously.
    public var isVisited: Location {
        assigning(.isVisited, to: true)
    }

    /// The location contains or is primarily composed of water.
    public var isWater: Location {
        assigning(.isWater, to: true)
    }

    /// Suppress default article ("a", "the") (ZIL `NARTICLEBIT`).
    public var omitArticle: Location {
        assigning(.omitArticle, to: true)
    }
}

// MARK: - Exits

extension Location {

    // MARK: - Cardinal Directions

    /// Creates an exit leading north to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northward movement.
    public func north(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .north,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading south to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southward movement.
    public func south(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .south,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading east to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for eastward movement.
    public func east(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .east,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading west to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for westward movement.
    public func west(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .west,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Intermediate Directions

    /// Creates an exit leading northeast to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northeastward movement.
    public func northeast(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .northeast,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading northwest to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northwestward movement.
    public func northwest(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .northwest,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading southeast to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southeastward movement.
    public func southeast(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .southeast,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading southwest to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southwestward movement.
    public func southwest(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .southwest,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Vertical Directions

    /// Creates an exit leading up to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for upward movement.
    public func up(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .up,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading down to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for downward movement.
    public func down(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .down,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Inside/Outside Directions

    /// Creates an exit leading inside to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for movement inside.
    public func inside(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .inside,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading outside to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for movement outside.
    public func outside(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Location {
        assigning(
            direction: .outside,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Blocked Exits

    /// Creates a permanently blocked exit leading north.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for northward movement.
    public func north(blocked: String) -> Location {
        assigning(
            direction: .north,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading south.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for southward movement.
    public func south(blocked: String) -> Location {
        assigning(
            direction: .south,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading east.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for eastward movement.
    public func east(blocked: String) -> Location {
        assigning(
            direction: .east,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading west.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for westward movement.
    public func west(blocked: String) -> Location {
        assigning(
            direction: .west,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading up.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for upward movement.
    public func up(blocked: String) -> Location {
        assigning(
            direction: .up,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading down.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for downward movement.
    public func down(blocked: String) -> Location {
        assigning(
            direction: .down,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading inside.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for movement inside.
    public func inside(blocked: String) -> Location {
        assigning(
            direction: .inside,
            blockedMessage: blocked
        )
    }

    /// Creates a permanently blocked exit leading outside.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for movement outside.
    public func outside(blocked: String) -> Location {
        assigning(
            direction: .outside,
            blockedMessage: blocked
        )
    }
}

// MARK: - Private assigners

extension Location {
    /// Returns a copy of this `Location` with the given property assigned to the
    /// provided `StateValue`.
    ///
    /// This helper performs a value-type update: it creates a modified copy of the receiver,
    /// updates (or inserts) the specified property in the `properties` dictionary, and returns
    /// the new `Location`. It is used throughout the fluent API (for example, `name(_:)`,
    /// `description(_:)`, and the directional exit helpers) to produce updated `Location`
    /// instances.
    ///
    /// - Parameters:
    ///   - id: The `LocationPropertyID` key identifying which property to set.
    ///   - rawValue: The `StateValue` to assign for the property.
    /// - Returns: A new `Location` with the updated property.
    public func assigning(
        _ id: LocationPropertyID,
        to rawValue: StateValue
    ) -> Location {
        var modified = self
        modified.properties[id] = rawValue
        return modified
    }

    /// Returns a copy of this `Location` with a directional exit assigned.
    ///
    /// This helper creates a new `Exit` instance with the specified direction, destination,
    /// optional blocked message, and optional door/barrier item. It then inserts this exit
    /// into the location's `.exits` property, which is a set of all exits for the location.
    /// If the location already has exits defined, the new exit is added to the set; otherwise,
    /// a new set containing just this exit is created.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit (e.g., `.north`, `.east`, `.up`).
    ///   - destinationID: The `LocationID` of the destination location, or `nil` for blocked exits.
    ///   - blockedMessage: An optional custom message shown when the exit is blocked.
    ///   - doorID: An optional `ItemID` for a door or barrier controlling access to the exit.
    /// - Returns: A new `Location` with the updated exit set.
    public func assigning(
        direction: Direction,
        destinationID: LocationID? = nil,
        blockedMessage: String? = nil,
        doorID: ItemID? = nil
    ) -> Location {
        var modified = self
        let exit = Exit(
            direction: direction,
            destinationID: destinationID,
            blockedMessage: blockedMessage,
            doorID: doorID
        )
        if case .exits(var modifiedExits) = properties[.exits] {
            modifiedExits.insert(exit)
            modified.properties[.exits] = .exits(modifiedExits)
        } else {
            modified.properties[.exits] = .exits([exit])
        }
        return modified
    }
}
