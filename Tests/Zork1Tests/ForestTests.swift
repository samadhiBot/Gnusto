import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct ForestTests {
    @Test("Forest exploration and grating discovery")
    func testForestExploration() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            """
            north
            north
            examine tree
            north
            examine trees
            examine grating
            move leaves
            look
            examine grating
            """
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            Zork I: The Great Underground Empire

            ZORK I: The Great Underground Empire Copyright (c) 1981, 1982,
            1983 Infocom, Inc. All rights reserved. ZORK is a registered
            trademark of Infocom, Inc. Revision 88 / Serial number 840726

            --- West of House ---

            You are standing in an open field west of a white house, with a
            boarded front door.

            There is a small mailbox here.

            > north
            --- North of House ---

            You are facing the north side of a white house. There is no
            door here, and all the windows are boarded up. To the north a
            narrow path winds through the trees.

            > north
            --- Forest Path ---

            This is a path winding through a dimly lit forest. The path
            heads north-south here. One particularly large tree with some
            low branches stands at the edge of the path.

            > examine tree
            The tree is large and appears to have some low branches. It
            might be climbable.

            > north
            --- Clearing ---

            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.

            On the ground is a pile of leaves.

            > examine trees
            The forest is all around you, with trees in every direction.

            > examine grating
            You cannot reach any such thing from here.

            > move leaves
            In disturbing the pile of leaves, a grating is revealed.

            > look
            --- Clearing ---

            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.

            There is a grating securely fastened into the ground.

            On the ground is a pile of leaves.

            > examine grating
            The grating is closed.

            >
            Until we meet again in another tale...
            """
        )
    }
}
