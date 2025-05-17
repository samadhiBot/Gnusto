import CustomDump
import GnustoEngine
import Testing

@testable import CloakOfDarkness

struct CloakOfDarknessWalkthroughTests {
    @Test("Basic Cloak of Darkness Walkthrough, eventually winning")
    func testBasicCloakWalkthrough() async throws {
        let mockIO = await MockIOHandler(
            "inventory",
            "examine the cloak",
            "drop it",
            "go south",
            "walk north",
            "go north",
            "go west",
            "examine the brass hook",
            "remove the cloak",
            "hang it on the brass hook",
            "examine the hook",
            "walk east",
            "go south",
            "read the message",
        )
        let engine = await GameEngine(
            blueprint: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()

        expectNoDifference(transcript, """
            Cloak of Darkness

            A basic IF demonstration.

            Hurrying through the rainswept November night, you’re glad to see the
            bright lights of the Opera House. It’s surprising that there aren’t more
            people about but, hey, what do you expect in a cheap demo game…?

            — Foyer of the Opera House —

            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.

            > inventory
            You are carrying:
            - A velvet cloak

            > examine the cloak
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.

            > drop it
            This isn’t the best place to leave a smart cloak lying around.

            > go south
            It is pitch black. You are likely to be eaten by a grue.

            > walk north
            > go north
            You’ve only just arrived, and besides, the weather outside
            seems to be getting worse.

            > go west
            — Cloakroom —

            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.

            You can see a small brass hook here.

            > examine the brass hook
            It’s just a small brass hook, screwed to the wall.

            > remove the cloak
            You take off the velvet cloak.

            > hang it on the brass hook
            You put the velvet cloak on the small brass hook.

            > examine the hook
            It’s just a small brass hook, with a cloak hanging on it.

            > walk east
            > go south
            > read the message
            The message, neatly marked in the sawdust, reads…

            “You win.”
            """)
    }

    @Test("Blundering Cloak of Darkness Walkthrough, eventually losing")
    func testBlunderingCloakWalkthroughLosing() async throws {
        let mockIO = await MockIOHandler(
            "go north",
            "go south",
            "inventory",
            "remove the cloak",
            "shout",
            "walk east",
            "go north",
            "look",
            "go east",
            "go west",
            "take the brass hook",
            "drop cloak",
            "e",
            "s",
            "look",
            "read the message",
        )
        let engine = await GameEngine(
            blueprint: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let transcript = await mockIO.flush()

        expectNoDifference(transcript, """
            Cloak of Darkness

            A basic IF demonstration.

            Hurrying through the rainswept November night, you’re glad to see the
            bright lights of the Opera House. It’s surprising that there aren’t more
            people about but, hey, what do you expect in a cheap demo game…?

            — Foyer of the Opera House —

            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.

            > go north
            You’ve only just arrived, and besides, the weather outside
            seems to be getting worse.

            > go south
            It is pitch black. You are likely to be eaten by a grue.

            > inventory
            You are carrying:
            - A velvet cloak

            > remove the cloak
            In the dark? You could easily disturb something!

            > shout
            I don’t know the verb ‘shout’.

            > walk east
            Blundering around in the dark isn’t a good idea!

            > go north
            > look
            — Foyer of the Opera House —

            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.

            > go east
            You can’t go that way.

            > go west
            — Cloakroom —

            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.

            You can see a small brass hook here.

            > take the brass hook
            You can’t take the small brass hook.

            > drop cloak
            Dropped.

            > e
            > s
            > look
            — Bar —

            The bar, much rougher than you’d have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            You can see a scrawled message here.

            > read the message
            The message has been carelessly trampled, making it
            difficult to read. You can just distinguish the words…

            “You lose.”
            """)
    }
}
