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
            Until we meet again in another tale...
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
            You can't go that way.

            > head west
            The troll fends you off with a menacing gesture.

            > talk to the troll
            The troll isn't much of a conversationalist.

            > push the troll
            The troll laughs at your puny gesture.

            > hit the troll with the lantern
            Your blood sings as your brass lantern cuts toward the troll
            who barely gets his bloody ax into position before impact.

            Attacking with the brass lantern? The pathetic troll grips his
            ax tighter, unimpressed by your improvised weaponry.

            The riposte comes fast, his axe flicking out to trace a shallow
            arc of red across your guard. The cut registers dimly. Blood,
            but not enough to matter.

            > head west
            The troll fends you off with a menacing gesture.

            The troll turns your momentum against you, his axe catching
            flesh in passing, painting a line of fire. The strike lands but
            doesn't slow you. Not yet.

            > go south
            --- Cellar ---

            Your sword is glowing with a faint blue glow.

            > walk west
            --- Bottom of Ramp ---

            You are at the bottom of a steep metal ramp. The ramp leads up
            to the west, but it is too steep and smooth to climb.

            Your sword is no longer glowing.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }
}
