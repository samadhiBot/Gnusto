import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct ForestTests {
    @Test("Forest exploration and grating discovery")
    func testForestExploration() async throws {
        let mockIO = await MockIOHandler(
            "north",
            "north",
            "examine path",
            "north",
            "examine trees",
            "east",
            "north",
            "examine grating",
            "move leaves",
            "examine grating"
        )
        let engine = await GameEngine(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            Zork I: The Great Underground Empire
            
            ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
            1983 Infocom, Inc. All rights reserved. ZORK is a registered
            trademark of Infocom, Inc. Revision 88 / Serial number 840726
            
            — West of House —
            
            You are standing in an open field west of a white house, with a
            boarded front door.
            
            You can see a front door, a small mailbox, and a white house
            here.
            
            > north
            — North of House —
            
            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.
            
            > north
            — Forest Path —
            
            This is a path winding through a dimly lit forest. The path
            heads north-south here. One particularly large tree with some
            low branches stands at the edge of the path.
            
            You can see a tree here.
            
            > examine path
            [ should be able to examine surroundings ]
            
            > north
            — Forest —
            
            This is a forest, with trees in all directions. To the east,
            there appears to be sunlight.
            
            > examine trees
            [ should see trees ]
            
            > east
            > north
            > examine grating
            You can’t see any ‘grating’ here.
            
            > move leaves
            [ need to implement move ]
            
            > examine grating
            [ grating should be revealed now ]
            
            >
            Goodbye!
            """)

    }
}
