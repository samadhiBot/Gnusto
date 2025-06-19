import GnustoEngine

/// A faithful recreation of _Zork 1: The Great Underground Empire_ using the Gnusto Interactive
/// Fiction Engine.
///
/// This implementation follows the original ZIL source code to recreate the authentic player
/// experience while utilizing modern Swift architecture and the Gnusto engine's capabilities.
struct Zork1: GameBlueprint {
    let storyTitle = "Zork I: The Great Underground Empire"

    let introduction = """
        ZORK I: The Great Underground Empire
        Copyright (c) 1981, 1982, 1983 Infocom, Inc. All rights reserved.
        ZORK is a registered trademark of Infocom, Inc.
        Revision 88 / Serial number 840726
        """

    let release = "88"

    let maximumScore = 350

    var player: Player {
        Player(in: .westOfHouse)
    }

    var messageProvider: MessageProvider {
        ZorkMessageProvider()
    }

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}
