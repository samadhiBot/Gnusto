import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Cloak of Darkness",
        introduction: """
            A basic IF demonstration.

            Hurrying through the rainswept November night, you're glad to see the
            bright lights of the Opera House. It's surprising that there aren't more
            people about but, hey, what do you expect in a cheap demo game...?
            """,
        release: "0.0.3",
        maximumScore: 2
    )

    let player = Player(in: .foyer)
}
