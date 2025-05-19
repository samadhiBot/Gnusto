// MARK: - State Query Helpers (Public API for Handlers/Hooks)

extension GameEngine {
    /// Checks whether the specified location is currently lit.
    ///
    /// A location is considered lit if it has the `.inherentlyLit` attribute set to `true`,
    /// or if an item with the `.lightSource` attribute set to `true` and also having its
    /// `.on` attribute `true` is present in the location (including being held by the player).
    /// This check is performed by the engine's `ScopeResolver`.
    ///
    /// - Parameter locationID: The `LocationID` of the location to check.
    /// - Returns: `true` if the location is determined to be lit, `false` otherwise.
    public func isLocationLit(at locationID: LocationID) async -> Bool {
        await scopeResolver.isLocationLit(locationID: locationID)
    }

    /// Retrieves an immutable copy (snapshot) of a specific location from the current game state.
    ///
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `Location` struct representing a snapshot of the specified location.
    /// - Throws: An `ActionResponse.internalEngineError` if no `id` is provided or if the
    ///           specified `LocationID` does not exist in the `gameState`.
    public func location(_ id: LocationID?) throws -> Location {
        guard let id else {
            throw ActionResponse.internalEngineError("No location identifier provided.")
        }
        guard let location = gameState.locations[id] else {
            throw ActionResponse.internalEngineError("Location `\(id)` not found.")
        }
        return location
    }

    /// Retrieves an immutable copy (snapshot) of a specific item from the current game state.
    ///
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `Item` struct representing a snapshot of the specified item.
    /// - Throws: An `ActionResponse.internalEngineError` if no `id` is provided, or
    ///           `ActionResponse.itemNotAccessible` if the `ItemID` does not exist.
    public func item(_ id: ItemID?) throws -> Item {
        guard let id else {
            throw ActionResponse.internalEngineError("No item identifier provided.")
        }
        guard let item = gameState.items[id] else {
            throw ActionResponse.itemNotAccessible(id)
        }
        return item
    }

    /// Retrieves immutable copies (snapshots) of all items currently located within the
    /// specified parent entity (e.g., a location, the player, or a container item).
    ///
    /// - Parameter parent: The `ParentEntity` whose contents are to be retrieved.
    /// - Returns: An array of `Item` structs. The array will be empty if the parent
    ///            contains no items or if the parent entity itself is invalid.
    public func items(in parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }
}
