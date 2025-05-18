/// Represents the state of the player character within the game world.
///
/// The `Player` struct holds information crucial to the player's experience and interaction
/// with the game, such as their current location, inventory capacity, score, and turn count.
/// An instance of `Player` is a key part of the overall `GameState`.
public struct Player: Codable, Equatable, Sendable {
    /// The maximum total `size` of items the player can carry in their inventory.
    /// If the `currentInventoryWeight` exceeds this, the player might be prevented
    /// from picking up more items. Defaults to `100`.
    public var carryingCapacity: Int = 100 // Example, could be based on SIZE props

    /// The `LocationID` of the location where the player is currently situated.
    public var currentLocationID: LocationID

    /// A representation of the player's current health or well-being.
    /// The meaning and scale (e.g., 0-100) can be game-specific. It might influence
    /// actions or trigger game events (like death) if it reaches certain thresholds.
    /// Defaults to `100`.
    public var health: Int = 100 // Example

    /// The number of turns that have elapsed since the game began. This typically increments
    /// after each valid player command is processed.
    public var moves: Int = 0

    /// The player's current score, which can be modified by game actions and events.
    public var score: Int = 0

    /// Initializes a new `Player` state.
    ///
    /// - Parameters:
    ///   - currentLocationID: The `LocationID` where the player starts the game.
    ///   - carryingCapacity: The maximum total size/weight of items the player can carry.
    ///                       Defaults to `100`.
    ///   - health: The player's starting health. Defaults to `100`.
    ///   - moves: The initial turn count (usually for starting a new game). Defaults to `0`.
    ///   - score: The player's starting score. Defaults to `0`.
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

    /// Calculates the total combined `size` of all items currently in the player's inventory
    /// (i.e., items whose `parent` is `.player`).
    ///
    /// This value can be compared against `carryingCapacity` to determine if the player
    /// can pick up additional items.
    ///
    /// - Parameter allItems: A dictionary of all `Item` instances in the game, keyed by `ItemID`,
    ///                       typically sourced from `GameState.items`. This is needed to access
    ///                       the `size` and `parent` of each item.
    /// - Returns: The sum of sizes of all items currently carried by the player.
    public func currentInventoryWeight(allItems: [ItemID: Item]) -> Int {
        allItems.values
            .filter { $0.parent == .player }
            .reduce(0) { $0 + $1.size } // Sum the sizes
    }

    // Codable conformance will be synthesized correctly now
}
