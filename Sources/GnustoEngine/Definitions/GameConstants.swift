/// A protocol defining the core metadata and player-facing constants for an interactive
/// fiction game.
public struct GameConstants: Sendable {
    /// The full title of the game (e.g., "ZORK I: The Great Underground Empire").
    var storyTitle: String

    /// An optional subtitle or headline for the game.
    var headline: String?

    /// The release version string (e.g., "Release 52").
    var release: String

    /// The serial number string (e.g., "871125").
    var serial: String?

    /// The maximum achievable score in the game.
    var maximumScore: Int

    /// The default message shown when the player dies.
    var deathMessage: String

    /// An optional custom opening banner (multi-line), if the game wants to override the default.
    var openingBanner: String?

    public init(
        storyTitle: String,
        headline: String? = nil,
        release: String,
        serial: String? = nil,
        maximumScore: Int,
        deathMessage: String = "You have lost.",
        openingBanner: String? = nil
    ) {
        self.storyTitle = storyTitle
        self.headline = headline
        self.release = release
        self.serial = serial
        self.maximumScore = maximumScore
        self.deathMessage = deathMessage
        self.openingBanner = openingBanner
    }
}
