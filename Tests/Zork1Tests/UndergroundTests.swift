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
            No more waiting as you attack with your lantern raised and the
            pathetic troll responds with his axe, two weapons now committed
            to drawing blood.

            The brass lantern makes a poor weapon against the pathetic
            troll's his axe! This might not end well.

            The troll's retaliatory strike with his ax cuts toward you but
            your body knows how to flow around death.

            > head west
            The troll fends you off with a menacing gesture.

            In the exchange, his ax slips through to mark you--a stinging
            reminder that the troll still has teeth. The wound is trivial
            against your battle fury.

            > go south
            --- Cellar ---

            In the exchange, his bloody ax slips through to mark you--a
            stinging reminder that the troll still has teeth. The wound is
            trivial against your battle fury.

            Your sword is glowing with a faint blue glow.

            > walk south
            --- East of Chasm ---

            You are on the east edge of a chasm, the bottom of which cannot
            be seen. A narrow passage goes north, and the path you are on
            continues to the east.

            Suddenly the pathetic troll slips past your guard. His axe
            opens a wound that will mark you, and your blood flows out
            steady and sure. The blow lands hard, adding to your growing
            collection of injuries.

            >
            May your adventures elsewhere prove fruitful!
            """
        )
    }
}
