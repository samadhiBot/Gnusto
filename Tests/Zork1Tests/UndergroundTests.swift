import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct UndergroundTests {
    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterUnderground,
            "north"
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            > north
            --- Troll Room ---

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            A nasty-looking troll, brandishing a bloody axe, blocks all
            passages out of the room.

            Your sword is glowing very brightly.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }

    @Test("Basic underground exploration")
    func testUndergroundExploration() async throws {
        let (engine, mockIO) = await GameEngine.zork1(
            pre: .enterUnderground,
            """
            north
            walk east
            go north
            head west
            talk to the troll
            push the troll
            hit the troll with the lantern
            head west
            go south
            walk west
            """
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(
            transcript,
            """
            > north
            --- Troll Room ---

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            A nasty-looking troll, brandishing a bloody axe, blocks all
            passages out of the room.

            Your sword is glowing very brightly.

            > walk east
            The troll fends you off with a menacing gesture.

            > go north
            The universe conspires against your movement that way.

            > head west
            The troll fends you off with a menacing gesture.

            > talk to the troll
            The troll isn't much of a conversationalist.

            > push the troll
            The troll laughs at your puny gesture.

            > hit the troll with the lantern
            You drive in hard with your light while the troll pivots with
            his bloody ax ready, both of you past the point of retreat.

            You brandish the brass lantern aggressively! The troll almost
            laughs, readying his ax for real combat.

            The troll swings his axe in response but you weave away,
            leaving the weapon to bite empty air.

            > head west
            The troll fends you off with a menacing gesture.

            The riposte comes fast, his bloody ax flicking out to trace a
            shallow arc of red across your guard. Pain flickers and dies.
            Your body has more important work.

            > go south
            --- Cellar ---

            Your sword is glowing with a faint blue glow.

            > walk west
            --- Bottom of Ramp ---

            You are at the bottom of a steep metal ramp. The ramp leads up
            to the west, but it is too steep and smooth to climb.

            Your sword is no longer glowing.

            >
            Farewell, brave soul!
            """
        )
    }
}
