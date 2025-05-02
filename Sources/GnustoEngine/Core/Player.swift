/// Represents the state of the player character.
public struct Player: Codable, Equatable, Sendable {
    /// The maximum weight/size the player can carry.
    public var carryingCapacity: Int = 100 // Example, could be based on SIZE props

    /// The ID of the location the player is currently in.
    public var currentLocationID: LocationID

    /// The player's current health or state (e.g., normal, stunned, dead). We can refine this.
    public var health: Int = 100 // Example

    /// The number of turns the player has taken.
    public var moves: Int = 0

    /// The player's current score.
    public var score: Int = 0
    
    /// <#Description#>
    /// - Parameters:
    ///   - currentLocationID: <#currentLocationID description#>
    ///   - carryingCapacity: <#carryingCapacity description#>
    ///   - health: <#health description#>
    ///   - moves: <#moves description#>
    ///   - score: <#score description#>
    public init(
        in currentLocationID: LocationID,
        carryingCapacity: Int = 100,
        health: Int = 100,
        moves: Int = 0,
        score: Int = 0
    ) {
        self.carryingCapacity = carryingCapacity
        self.currentLocationID = currentLocationID
        self.health = health
        self.moves = moves
        self.score = score
    }

    // --- Computed Properties / Helpers ---

    /// Calculates the total weight/size of items currently held by the player.
    /// - Parameter allItems: The main dictionary of all items in the game state.
    /// - Returns: The sum of sizes of items whose parent is `.player`.
    public func currentInventoryWeight(allItems: [ItemID: Item]) -> Int {
        allItems.values
            .filter { $0.parent == .player }
            .reduce(0) { $0 + $1.size } // Sum the sizes
    }

    // Codable conformance will be synthesized correctly now
}
