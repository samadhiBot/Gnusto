//
//  GameEngine+player.swift
//  Gnusto
//
//  Created by Chris Sessions on 5/8/25.
//


// MARK: - Player State Accessors

extension GameEngine {

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
