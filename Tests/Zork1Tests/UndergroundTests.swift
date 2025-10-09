import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct UndergroundTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async throws {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1()
        )

        // Give the player a sword and lantern, and position them in the cellar
        try await engine.apply(
            engine.player.move(to: .livingRoom),
            engine.item(.lamp).move(to: .player),
            engine.item(.lamp).setFlag(.isOn),
            engine.item(.trapDoor).setFlag(.isOpen)
        )

        try await engine.execute(
            """
            take the sword
            go down
            """
        )
    }

    @Test("Underground access via trap door")
    func testUndergroundAccess() async throws {
        try await engine.execute("head north")

        await mockIO.expect(
            """
            > take the sword
            Taken.

            > go down
            The trap door crashes shut, and you hear someone barring it.

            --- Cellar ---

            You are in a dark and damp cellar with a narrow passageway
            leading north, and a crawlway to the south. On the west is the
            bottom of a steep metal ramp which is unclimbable.

            Your sword is glowing with a faint blue glow.

            > head north
            --- Troll Room ---

            This is a small room with passages to the east and south and a
            forbidding hole leading west. Bloodstains and deep scratches
            (perhaps made by an axe) mar the walls.

            A nasty-looking troll, brandishing a bloody axe, blocks all
            passages out of the room.

            Your sword is glowing very brightly.
            """
        )
    }

    @Test("Basic underground exploration")
    func testUndergroundExploration() async throws {
        try await engine.execute(
            """
            go north
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

        await mockIO.expect(
            """
            > take the sword
            Taken.

            > go down
            The trap door crashes shut, and you hear someone barring it.

            --- Cellar ---

            You are in a dark and damp cellar with a narrow passageway
            leading north, and a crawlway to the south. On the west is the
            bottom of a steep metal ramp which is unclimbable.

            Your sword is glowing with a faint blue glow.

            > go north
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
            Your path does not extend in that direction.

            > head west
            The troll fends you off with a menacing gesture.

            > talk to the troll
            The troll isn't much of a conversationalist.

            > push the troll
            The troll laughs at your puny gesture.

            > hit the troll with the lantern
            No more waiting as you attack with your lamp raised and the
            troll responds with his ax, two weapons now committed to
            drawing blood.

            > head west
            The troll counters with his axe with such violence that you
            flinch, in a moment of weakness he immediately exploits.

            > go south
            The pathetic troll turns your momentum against you, his bloody
            axe catching flesh in passing, painting a line of fire. Pain
            flickers and dies. Your body has more important work.

            > walk west
            The nasty troll turns your momentum against you, his bloody axe
            catching flesh in passing, painting a line of fire. A flash of
            pain, quickly suppressed. You've taken worse.
            """
        )
    }
}
