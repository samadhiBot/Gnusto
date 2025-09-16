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

            Your sword is glowing very brightly.

            > go north
            You can't go that way.

            Your sword is glowing very brightly.

            > head west
            The troll fends you off with a menacing gesture.

            Your sword is glowing very brightly.

            > talk to the troll
            The troll isn't much of a conversationalist.

            Your sword is glowing very brightly.

            > push the troll
            The troll laughs at your puny gesture.

            Your sword is glowing very brightly.

            > hit the troll with the lantern
            No more waiting as you attack with your lantern raised and the
            pathetic troll responds with his axe, two weapons now committed
            to drawing blood.

            The brass lantern makes a poor weapon against the pathetic
            troll's his axe! This might not end well.

            The troll's retaliatory strike with his ax cuts toward you but
            your body knows how to flow around death.

            Your sword is glowing very brightly.

            > head west
            The troll fends you off with a menacing gesture.

            In the exchange, his ax slips through to mark you--a stinging
            reminder that the troll still has teeth. The wound is trivial
            against your battle fury.

            Your sword is glowing very brightly.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }
}
