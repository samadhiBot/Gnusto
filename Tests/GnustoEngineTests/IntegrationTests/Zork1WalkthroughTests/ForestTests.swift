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
            "examine tree",
            "north",
            "examine trees",
            "examine grating",
            "move leaves",
            "look",
            "examine grating"
        )
        let engine = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.zork1Intro)

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

            > examine tree
            The tree is large and appears to have some low branches. It
            might be climbable.

            > north
            — Clearing —

            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.

            There is a pile of leaves here.

            > examine trees
            The forest is all around you, with trees in every direction.

            > examine grating
            You can’t see any ‘grating’ here.

            > move leaves
            In disturbing the pile of leaves, a grating is revealed.

            > look
            — Clearing —

            You are in a clearing, with a forest surrounding you on all
            sides. A path leads south.

            There is a grating securely fastened into the ground.

            On the ground is a pile of leaves.

            > examine grating
            The grating is closed.

            >
            Goodbye!
            """)

    }
}
