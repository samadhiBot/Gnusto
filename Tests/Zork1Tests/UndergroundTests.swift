import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

struct UndergroundTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async throws {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
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
            Your blood sings as your light cuts toward the troll who barely
            gets his ax into position before impact.

            The brass lantern makes a poor weapon against the troll's
            bloody axe! This might not end well.

            The pathetic troll turns your momentum against you, his bloody
            axe catching flesh in passing, painting a line of fire. The cut
            registers dimly. Blood, but not enough to matter.

            > head west
            The troll fends you off with a menacing gesture.

            The troll whips his bloody axe across in answer -- steel
            whispers against skin, leaving a thin signature of pain. The
            strike lands but doesn't slow you. Not yet.

            > go south
            --- Cellar ---

            Your sword is glowing with a faint blue glow.

            > walk west
            --- Bottom of Ramp ---

            You are at the bottom of a steep metal ramp. The ramp leads up
            to the west, but it is too steep and smooth to climb.

            Your sword is no longer glowing.
            """
        )
    }
}
