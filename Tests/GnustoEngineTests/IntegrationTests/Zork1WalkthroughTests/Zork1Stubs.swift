import Foundation

enum Moves {
    static let enterKitchen = [
        "north",
        "east",
        "open window",
        "west",
    ]

    static let enterUnderground = enterKitchen + [
        "west",
        "take all",
        "move the rug",
        "open the trap door",
        "down",
        "light the lantern"
    ]
}

enum Playback {
    static let zork1Intro = """
        Zork I: The Great Underground Empire

        ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
        1983 Infocom, Inc. All rights reserved. ZORK is a registered
        trademark of Infocom, Inc. Revision 88 / Serial number 840726

        — West of House —

        You are standing in an open field west of a white house, with a
        boarded front door.

        There is a small mailbox here.
        """

    static let enterKitchen = """
        \(zork1Intro)

        > north
        — North of House —

        You are facing the north side of a white house. There is no
        door here, and all the windows are boarded up. To the north a
        narrow path winds through the trees.

        > east
        — Behind House —

        You are behind the white house. A path leads into the forest to
        the east. In one corner of the house there is a small window
        which is slightly ajar.

        > open window
        With great effort, you open the window far enough to allow
        entry.

        > west
        — Kitchen —

        You are in the kitchen of the white house. A table seems to
        have been used recently for the preparation of food. A passage
        leads to the west and a dark staircase can be seen leading
        upward. A dark chimney leads down and to the east is a small
        window which is open.
        """

    static let enterUnderground = """
        \(enterKitchen)

        > west
        — Living Room —

        You are in the living room. There is a doorway to the east, a
        wooden door with strange gothic lettering to the west, which
        appears to be nailed shut, a trophy case, and a large oriental
        rug in the center of the room.

        A battery-powered brass lantern is on the trophy case.

        Above the trophy case hangs an elvish sword of great antiquity.

        In the trophy case is an ancient parchment which appears to be
        a map.

        > take all
        You take the brass lantern and the sword.

        > move the rug
        With a great effort, the rug is moved to one side of the room,
        revealing the dusty cover of a closed trap door.

        > open the trap door
        The door reluctantly opens to reveal a rickety staircase
        descending into darkness.

        > down
        The trap door crashes shut, and you hear someone barring it.

        You have moved into a dark place.

        It is pitch black. You are likely to be eaten by a grue.

        Your sword is glowing with a faint blue glow.

        > light the lantern
        The brass lantern is now on. You can see your surroundings now.

        — Cellar —

        You are in a dark and damp cellar with a narrow passageway
        leading north, and a crawlway to the south. On the west is the
        bottom of a steep metal ramp which is unclimbable.
        """
}
