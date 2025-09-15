import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
public struct CloakOfDarkness: GameBlueprint {
    public let title = "Cloak of Darkness"

    public let abbreviatedTitle = "Cloak"

    public let introduction = """
        A basic IF demonstration.

        Hurrying through the rainswept November night, you're glad to see the
        bright lights of the Opera House. It's surprising that there aren't more
        people about but, hey, what do you expect in a cheap demo game...?
        """

    public let release = "0.0.3"

    public let maximumScore = 2

    public let player = Player(in: .foyer)

    // Declaring messenger and randomNumberGenerator allows you to inject
    // a deterministic random number generator for use in tests.
    public let messenger: StandardMessenger
    public let randomNumberGenerator: any RandomNumberGenerator & Sendable

    public init(
        rng: RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        self.randomNumberGenerator = rng
        self.messenger = StandardMessenger(randomNumberGenerator: rng)
    }

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}
