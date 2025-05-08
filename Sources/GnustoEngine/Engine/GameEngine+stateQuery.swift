// MARK: - State Query Helpers (Public API for Handlers/Hooks)

extension GameEngine {
    /// Retrieves the current state of a specific location.
    /// - Parameter id: The `LocationID` of the location to retrieve.
    /// - Returns: A `Location` struct if the location is found, otherwise `nil`.
    public func location(with id: LocationID) -> Location? {
        gameState.locations[id]
    }

    /// Retrieves the current state of a specific item.
    /// - Parameter id: The `ItemID` of the item to retrieve.
    /// - Returns: An `Item` struct if the item is found, otherwise `nil`.
    public func item(_ id: ItemID) -> Item? {
        gameState.items[id]
    }

    /// Retrieves the current state of all items with a specific parent.
    /// - Parameter parent: The `ParentEntity` to filter items by.
    /// - Returns: An array of `Item` structs for items with the specified parent.
    public func items(in parent: ParentEntity) -> [Item] {
        gameState.items.values
            .filter { $0.parent == parent }
    }
}
