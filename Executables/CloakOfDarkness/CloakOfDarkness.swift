import GnustoEngine

/// A Gnusto Engine port of Roger Firth's Cloak of Darkness.
struct CloakOfDarkness: GameBlueprint {
    var constants: GameConstants {
        GameConstants(
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
    }

    var areas: [any AreaBlueprint.Type] {
        [OperaHouse.self]
    }

    var player: Player {
        Player(in: OperaHouse.foyer)
    }

    var globalState: [GlobalID: StateValue] {
        [.barMessageDisturbances: 0]
    }
}

extension GlobalID {
    static let barMessageDisturbances = GlobalID("barMessageDisturbances")
}
