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

    /// Retrieves a copy of a specific location.
    ///
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A copy of the specified location.
    /// - Throws: If the specified location cannot be found.
    public func location(_ id: LocationID?) throws -> Location {
        guard let id else {
            throw ActionResponse.internalEngineError("No location identifier provided.")
        }
        guard let location = gameState.locations[id] else {
            throw ActionResponse.internalEngineError("Location `\(id)` not found.")
        }
        return location
    }

    /// Retrieves a copy of a specific item.
    ///
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: A copy of the specified item.
    /// - Throws: If the specified item cannot be found.
    public func item(_ id: ItemID?) throws -> Item {
        guard let id else {
            throw ActionResponse.internalEngineError("No item identifier provided.")
        }
        guard let item = gameState.items[id] else {
            throw ActionResponse.itemNotAccessible(id)
        }
        return item
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
