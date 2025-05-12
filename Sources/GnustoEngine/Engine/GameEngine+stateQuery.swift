// MARK: - State Query Helpers (Public API for Handlers/Hooks)

extension GameEngine {
    /// Checks whether the specified location is currently lit.
    ///
    /// A location is lit if it has the `.inherentlyLit` property, or if the player
    /// (or perhaps an NPC in the same location) is carrying an active light source
    /// (`.lightSource` and `.on` properties).
    ///
    /// - Parameter locationID: The unique identifier of the location to check.
    /// - Returns: `true` if the location is lit, `false` otherwise.
    public func isLocationLit(at locationID: LocationID) async -> Bool {
        await scopeResolver.isLocationLit(locationID: locationID)
    }

    /// Retrieves as copy of a specific location.
    ///
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `Location` struct if the location is found, otherwise `nil`.
    public func location(_ id: LocationID) -> Location? {
        gameState.locations[id]
    }

    /// Retrieves as copy of a specific item.
    ///
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `Item` struct if the item is found, otherwise `nil`.
    public func item(_ id: ItemID) -> Item? {
        gameState.items[id]
    }

    /// Retrieves as copy of all items with a specific parent.
    ///
    /// - Parameter parent: The `ParentEntity` to filter items by.
    /// - Returns: An array of `Item` structs for items with the specified parent.
    public func items(in parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }
}

// MARK: - Player-specific

extension GameEngine {
    /// Returns the player's inventory.
    public var playerInventory: [Item] {
        items(in: .player)
    }

    /// Returns the player's current location.
    public var playerLocation: Location? {
        location(playerLocationID)
    }

    /// Returns the identifier of the player's current location.
    public var playerLocationID: LocationID {
        gameState.player.currentLocationID
    }

    /// Checks whether the player's location is currently lit.
    public func isPlayerLocationLit() async -> Bool {
        await isLocationLit(at: gameState.player.currentLocationID)
    }
}
