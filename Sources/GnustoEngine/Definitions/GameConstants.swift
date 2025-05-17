/// Defines the core metadata constants for an interactive fiction game.
public struct GameConstants: Sendable {
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    let storyTitle: String

    /// Any headline, subtitle or introductory text to display at the start of the game.
    let introduction: String

    /// The release version string (e.g., "Release 42").
    let release: String

    /// The maximum achievable score in the game.
    let maximumScore: Int

    /// The default message shown when the player dies.
    let deathMessage: String

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
