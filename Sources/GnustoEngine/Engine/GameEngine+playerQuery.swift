import Foundation

// MARK: - Player State Accessors

extension GameEngine {
    /// Checks whether the player can currently reach (interact with) a specific item.
    ///
    /// This determination is made by the `ScopeResolver`, considering factors like
    /// whether the item is in the same location, if it's in an open container the player
    /// can access, etc. It does not consider if the item is too heavy to pick up, only
    /// if it's within interaction range.
    ///
    /// - Parameter itemID: The `ItemID` of the item to check.
    /// - Returns: `true` if the player can reach the item, `false` otherwise.
    public func playerCanReach(_ itemID: ItemID) async -> Bool {
        await scopeResolver.itemsReachableByPlayer().contains(itemID)
    }

    /// Returns an array of `Item` snapshots representing all items currently in the
    /// player's inventory.
    public var playerInventory: [Item] {
        items(in: .player)
    }

    /// Checks whether the player is currently holding a specific item in their inventory.
    ///
    /// - Parameter itemID: The `ItemID` of the item to check for.
    /// - Returns: `true` if the item is in the player's inventory, `false` otherwise.
    public func playerIsHolding(_ itemID: ItemID) async -> Bool {
        playerInventory.contains { $0.id == itemID }
    }

    /// Returns an immutable copy (snapshot) of the player's current location.
    ///
    /// - Returns: A `Location` struct for the player's current location.
    /// - Throws: An `ActionResponse.internalEngineError` if the player's location ID
    ///           is invalid or the location cannot be found (which should generally not happen).
    public func playerLocation() throws -> Location {
        try location(playerLocationID)
    }

    /// Checks whether the player's current location is lit.
    ///
    /// See `isLocationLit(at:)` for details on how lighting is determined.
    ///
    /// - Returns: `true` if the player's current location is lit, `false` otherwise.
    public func playerLocationIsLit() async -> Bool {
        await isLocationLit(at: playerLocationID)
    }

    /// Returns the `LocationID` of the player's current location.
    public var playerLocationID: LocationID {
        gameState.player.currentLocationID
    }

    /// The player's current score.
    public var playerScore: Int {
        gameState.player.score
    }

    /// The number of game turns the player has taken so far.
    public var playerMoves: Int {
        gameState.player.moves
    }

    /// Checks if the player can carry a given item based on its size and the player's
    /// current inventory weight and carrying capacity.
    ///
    /// - Parameter item: The `Item` to check.
    /// - Returns: `true` if the player has enough capacity to carry the item, `false` otherwise.
    public func playerCanCarry(_ item: Item) -> Bool {
        let currentWeight = gameState.player.currentInventoryWeight(allItems: gameState.items)
        let capacity = gameState.player.carryingCapacity
        return (currentWeight + item.size) <= capacity
    }
}
