import Foundation

// MARK: - Player State Accessors

extension GameEngine {
    /// Checks whether the player can reach an item.
    ///
    /// - Parameter itemID: <#itemID description#>
    /// - Returns: <#description#>
    public func playerCanReach(_ itemID: ItemID) async -> Bool {
        await scopeResolver.itemsReachableByPlayer().contains(itemID)
    }

    /// Returns the player's inventory.
    public var playerInventory: [Item] {
        items(in: .player)
    }

    /// Checks whether the player has an item in their inventory.
    public func playerIsHolding(_ itemID: ItemID) async -> Bool {
        playerInventory.contains { $0.id == itemID }
    }

    /// Returns the player's current location.
    public func playerLocation() throws -> Location {
        try location(playerLocationID)
    }

    /// Checks whether the player's location is currently lit.
    public func playerLocationIsLit() async -> Bool {
        await isLocationLit(at: playerLocationID)
    }

    /// Returns the identifier of the player's current location.
    public var playerLocationID: LocationID {
        gameState.player.currentLocationID
    }

    /// The player's current score.
    public var playerScore: Int {
        gameState.player.score
    }

    /// The number of turns the player has taken.
    public var playerMoves: Int {
        gameState.player.moves
    }

    /// Checks if the player can carry a given item based on their current inventory weight and capacity.
    /// - Parameter item: The item to check.
    /// - Returns: `true` if the player can carry the item, `false` otherwise.
    public func playerCanCarry(_ item: Item) -> Bool {
        let currentWeight = gameState.player.currentInventoryWeight(allItems: gameState.items)
        let capacity = gameState.player.carryingCapacity
        return (currentWeight + item.size) <= capacity
    }
}
