import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

struct UndergroundTests {
    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterUnderground,
            "north"
        )
        let (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser()
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.enterUnderground)

            > north
            — Troll Room —

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            A nasty-looking troll, brandishing a bloody axe, blocks all
            passages out of the room.

            Your sword is glowing very brightly.

            >
            Goodbye!
            """)
    }

    @Test("Basic underground exploration")
    func testUndergroundExploration() async throws {
        let mockIO = await MockIOHandler(
            Moves.enterUnderground,
            "north",
            "walk east",
            "go north",
            "head west",
            "talk to the troll",
            "take the troll",
            "attack the troll",
            "stab the troll with the sword",
            "hit the troll with the lantern",
            "head west"
        )
        let (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(),
            parser: StandardParser()
        )
        await engine.run()

        let transcript = await mockIO.flush()
        expectNoDifference(transcript, """
            \(Playback.enterUnderground)

            > north
            — Troll Room —

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
            You can’t go that way.

            Your sword is glowing very brightly.

            > head west
            The troll fends you off with a menacing gesture.

            Your sword is glowing very brightly.

            > talk to the troll
            The troll isn’t much of a conversationalist.

            Your sword is glowing very brightly.

            > take the troll
            The troll spits in your face, grunting “Better luck next time”
            in a rather barbarous accent.

            Your sword is glowing very brightly.

            > attack the troll
            Trying to attack a troll with your bare hands is suicidal.

            Your sword is glowing very brightly.

            > stab the troll with the sword

            > head west
            — Maze —

            This is part of a maze of twisty little passages, all alike.

            >
            Goodbye!
            """)
    }
}
