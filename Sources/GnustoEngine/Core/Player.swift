/// Represents the state of the player character within the game world.
///
/// The `Player` struct holds information crucial to the player's experience and interaction
/// with the game, such as their current location, inventory capacity, score, and turn count.
/// An instance of `Player` is a key part of the overall `GameState`.
public struct Player: Codable, Hashable, Sendable {
    /// The player's character sheet containing all attributes, properties, and states.
    ///
    /// This comprehensive character sheet includes D&D-style attributes, combat settings,
    /// character states, and all other character-related data. It serves as the single
    /// source of truth for the player's capabilities and current condition.
    var characterSheet: CharacterSheet

    /// The `LocationID` of the location where the player is currently situated.
    var currentLocationID: LocationID

    /// The number of turns that have elapsed since the game began. This typically increments
    /// after each valid player command is processed.
    var moves: Int

    /// The player's current score, which can be modified by game actions and events.
    var score: Int

    /// Initializes a new `Player` state.
    ///
    /// - Parameters:
    ///   - currentLocationID: The `LocationID` where the player starts the game.
    ///   - characterSheet: The player's character sheet containing all attributes and states.
    ///                     Defaults to a human character with neutral alignment.
    public init(
        in currentLocationID: LocationID,
        characterSheet: CharacterSheet = .default
    ) {
        self.characterSheet = characterSheet
        self.currentLocationID = currentLocationID
        self.moves = 0
        self.score = 0
    }
}
