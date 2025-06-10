import GnustoEngine

/// A faithful recreation of Zork 1: The Great Underground Empire using the Gnusto Interactive Fiction Engine.
///
/// This implementation follows the original ZIL source code to recreate the authentic player experience
/// while utilizing modern Swift architecture and the Gnusto engine's capabilities.
struct Zork1: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Zork I: The Great Underground Empire",
        introduction: """
            ZORK I: The Great Underground Empire
            Copyright (c) 1981, 1982, 1983 Infocom, Inc. All rights reserved.
            ZORK is a registered trademark of Infocom, Inc.
            Revision 88 / Serial number 840726
            """,
        release: "88",
        maximumScore: 350
    )

    var player: Player {
        Player(in: .westOfHouse)
    }
}
