import CloakOfDarkness
import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

struct CloakOfDarknessWalkthroughTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: CloakOfDarkness(
                rng: SeededRandomNumberGenerator()
            )
        )
    }

    @Test("Basic Cloak of Darkness Walkthrough, eventually winning")
    func testBasicCloakWalkthrough() async throws {
        try await engine.execute(
            """
            inventory
            examine the cloak
            drop it
            go south
            walk north
            go north
            go west
            examine the brass hook
            remove the cloak
            hang it on the brass hook
            examine the hook
            walk east
            go south
            read the message
            """
        )

        await mockIO.expectOutput(
            """
            > inventory
            You are carrying:
            - A velvet cloak (worn)

            > examine the cloak
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.

            > drop it
            This isn't the best place to leave a smart cloak lying around.

            > go south
            Darkness rushes in like a living thing.

            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.

            > walk north
            --- Foyer of the Opera House ---

            You are standing in a spacious hall, splendidly decorated in
            red and gold, with glittering chandeliers overhead. The
            entrance from the street is to the north, and there are
            doorways south and west.

            > go north
            You've only just arrived, and besides, the weather outside
            seems to be getting worse.

            > go west
            --- Cloakroom ---

            The walls of this small room were clearly once lined with
            hooks, though now only one remains. The exit is a door to the
            east.

            > examine the brass hook
            It's just a small brass hook, screwed to the wall.

            > remove the cloak
            You remove the velvet cloak.

            > hang it on the brass hook
            You successfully hang the velvet cloak on the small brass hook.

            > examine the hook
            It's just a small brass hook, with a cloak hanging on it.

            > walk east
            --- Foyer of the Opera House ---

            > go south
            --- Bar ---

            The bar, much rougher than you'd have guessed after the
            opulence of the foyer to the north, is completely empty. There
            seems to be some sort of message scrawled in the sawdust on the
            floor.

            > read the message
            The message, neatly marked in the sawdust, reads...

            "You win."
            """
        )
    }

    @Test("Blundering Cloak of Darkness Walkthrough, eventually losing")
    func testBlunderingCloakWalkthroughLosing() async throws {
        try await engine.execute(
            """
            go north
            go south
            inventory
            remove the cloak
            shout
            walk east
            go north
            look
            go east
            go west
            take the brass hook
            drop cloak
            e
            s
            look
            read the message
            """
        )

        await mockIO.expectOutput(
            """
            > go north
            You've only just arrived, and besides, the weather outside
            seems to be getting worse.

            > go south
            Darkness rushes in like a living thing.

            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.

            > inventory
            You are carrying:
            - A velvet cloak (worn)

            > remove the cloak
            In the dark? You could easily disturb something!

            > shout
            In the dark? You could easily disturb something!

            > walk east
            Blundering around in the dark isn't a good idea!

            > go north
            --- Foyer of the Opera House ---

            You are standing in a spacious hall, splendidly decorated in
            red and gold, with glittering chandeliers overhead. The
            entrance from the street is to the north, and there are
            doorways south and west.

            > look
            --- Foyer of the Opera House ---

            You are standing in a spacious hall, splendidly decorated in
            red and gold, with glittering chandeliers overhead. The
            entrance from the street is to the north, and there are
            doorways south and west.

            > go east
            You can't go that way.

            > go west
            --- Cloakroom ---

            The walls of this small room were clearly once lined with
            hooks, though now only one remains. The exit is a door to the
            east.

            > take the brass hook
            You cannot take the small brass hook, much as you might wish
            otherwise.

            > drop cloak
            Relinquished.

            > e
            --- Foyer of the Opera House ---

            > s
            --- Bar ---

            The bar, much rougher than you'd have guessed after the
            opulence of the foyer to the north, is completely empty. There
            seems to be some sort of message scrawled in the sawdust on the
            floor.

            > look
            --- Bar ---

            The bar, much rougher than you'd have guessed after the
            opulence of the foyer to the north, is completely empty. There
            seems to be some sort of message scrawled in the sawdust on the
            floor.

            > read the message
            The message has been carelessly trampled, making it difficult
            to read. You can just distinguish the words...

            "You lose."
            """
        )
    }
}
