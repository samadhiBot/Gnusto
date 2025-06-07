import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct UndergroundTests {
    let enterUndergroundSteps = [
        "north",
        "east",
        "open window",
        "west",
        "west",
        "take lamp",
        "turn on lamp",
        "open trap door",
        "move the rug",
        "open the trap door",
        "down",
    ]

    let enterUndergroundPlayback = """
        Zork I: The Great Underground Empire

        ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
        1983 Infocom, Inc. All rights reserved. ZORK is a registered
        trademark of Infocom, Inc. Revision 88 / Serial number 840726

        — West of House —

        You are standing in an open field west of a white house, with a
        boarded front door.

        There is a small mailbox here.

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

        > west
        — Living Room —

        You are in the living room. There is a doorway to the east, a
        wooden door with strange gothic lettering to the west, which
        appears to be nailed shut, a trophy case, and a large oriental
        rug in the center of the room.

        There are a brass lantern and a sword here.

        > take lamp
        Taken.

        > turn on lamp
        The brass lantern is now on.

        > open trap door
        You can’t see any such thing.

        > move the rug
        With a great effort, the rug is moved to one side of the room, revealing the dusty cover of a closed trap door.

        > open the trap door
        The door reluctantly opens to reveal a rickety staircase descending into darkness.

        > down
        — Cellar —

        You are in a dark and damp cellar with a narrow passageway
        leading north, and a crawlway to the south. On the west is the
        bottom of a steep metal ramp which is unclimbable.
        """

    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        let mockIO = await MockIOHandler(
            enterUndergroundSteps,
            "look",
            "north"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(enterUndergroundPlayback)

            > look
            — Cellar —

            You are in a dark and damp cellar with a narrow passageway
            leading north, and a crawlway to the south. On the west is the
            bottom of a steep metal ramp which is unclimbable.

            > north
            — Troll Room —

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            >
            Goodbye!
            """)
    }

    @Test("Basic underground exploration")
    func testUndergroundExploration() async throws {
        let mockIO = await MockIOHandler(
            enterUndergroundSteps,
            "north",
            "east",
            "east",
            "look",
            "west",
            "west",
            "south",
            "south",
            "east",
            "look"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(enterUndergroundPlayback)

            > north
            — Troll Room —

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            > east
            — East-West Passage —

            This is a narrow east-west passageway. There is a narrow
            stairway leading down at the north end of the room.

            > east
            — Round Room —

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > look
            — Round Room —

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > west
            — East-West Passage —
            
            > west
            — Troll Room —
            
            > south
            — Cellar —
            
            > south
            — East of Chasm —

            You are on the east edge of a chasm, the bottom of which cannot
            be seen. A narrow passage goes north, and the path you are on
            continues to the east.

            > east
            — Gallery —

            This is an art gallery. Most of the paintings have been stolen
            by vandals with exceptional taste. The vandals left through
            either the north or west exits.

            > look
            — Gallery —

            This is an art gallery. Most of the paintings have been stolen
            by vandals with exceptional taste. The vandals left through
            either the north or west exits.

            >
            Goodbye!
            """)
    }
}
