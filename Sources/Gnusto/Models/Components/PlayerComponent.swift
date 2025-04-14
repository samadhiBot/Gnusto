import Foundation

/// Represents a player character.
public struct PlayerComponent: Component {
    public static let type: ComponentType = .player

    /// The player's current score
    public var score: Int

    /// The number of moves the player has taken
    public var moves: Int

    public init(score: Int = 0, moves: Int = 0) {
        self.score = score
        self.moves = moves
    }
}
