import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct UndergroundTests {



    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterUnderground,
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
            \(Stub.enterUnderground)

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
            Moves.enterUnderground,
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
            \(Stub.enterUnderground)

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
