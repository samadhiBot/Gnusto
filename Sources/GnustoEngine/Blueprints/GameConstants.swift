/// A structure holding essential, game-wide constant values that define fundamental
/// aspects of the interactive fiction game, such as its title, introduction, and scoring.
///
/// Game developers provide these constants when creating a `GameBlueprint`.
/// The `GameEngine` then makes these constants available throughout the game, for example,
/// to display the title and introduction at the start, or to check against the maximum score.
public struct GameConstants: Sendable {
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    /// This is typically displayed by the `GameEngine` when the game starts.
    public let storyTitle: String

    /// An introductory text, often including a brief premise, version information, or byline.
    /// This is displayed by the `GameEngine` after the `storyTitle` when the game starts.
    public let introduction: String

    /// A version or release identifier for the game (e.g., "Release 1 / Serial number 880720").
    /// This can be part of the `introduction` or used separately as needed.
    public let release: String

    /// The maximum achievable score in the game. This is used by score-reporting actions
    /// and can be used by the game to determine if the player has "won".
    public let maximumScore: Int

    /// The default message displayed to the player when their character dies or the game
    /// ends in a non-winning state for which no specific message is provided.
    public let deathMessage: String

    /// Initializes a new set of game constants.
    ///
    /// - Parameters:
    ///   - storyTitle: The full title of the game.
    ///   - introduction: The introductory text, premise, or byline.
    ///   - release: A version or release identifier.
    ///   - maximumScore: The maximum achievable score.
    ///   - deathMessage: The default message for game over. Defaults to "You have lost.".
    public init(
        storyTitle: String,
        introduction: String,
        release: String,
        maximumScore: Int,
        deathMessage: String = "You have lost."
    ) {
        self.storyTitle = storyTitle
        self.introduction = introduction
        self.release = release
        self.maximumScore = maximumScore
        self.deathMessage = deathMessage
    }
}
