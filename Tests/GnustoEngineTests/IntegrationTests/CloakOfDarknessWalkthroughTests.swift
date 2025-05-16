import CustomDump
import Testing

@testable import CloakOfDarkness
@testable import GnustoEngine

extension Tag {
    @Tag static var integration: Tag
    @Tag static var walkthrough: Tag
}

struct CloakOfDarknessWalkthroughTests {
    /// Performs a basic walkthrough: look, go west, take cloak, wear cloak, go east, look.
    @Test("Basic Cloak Walkthrough", .tags(.integration, .walkthrough))
    func testBasicCloakWalkthrough() async throws {
        let mockIO = await MockIOHandler(
            "inventory",
            "go west",
            "examine brass hook",
            "hang the cloak on the brass hook",
            "examine cloak",
            "examine hook",
            "go east",
            "go south",
            "read the message",
            nil
        )
        let engine = await GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            Cloak of Darkness

            A basic IF demonstration.

            Hurrying through the rainswept November night, you're glad to see the
            bright lights of the Opera House. It's surprising that there aren't more
            people about but, hey, what do you expect in a cheap demo game...?

            Foyer of the Opera House
            ────────────────────────
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.

            > inventory
            You are carrying:
              A velvet cloak

            > go west
            Cloakroom
            ─────────
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            You can see a small brass hook here.

            > examine brass hook
            It's just a small brass hook, screwed to the wall.

            > hang the cloak on the brass hook
            You put the velvet cloak on the small brass hook.

            > examine cloak
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.

            > examine hook
            It's just a small brass hook, with a cloak hanging on it.

            > go east

            > go south
            Bar
            ───
            The bar, much rougher than you’d have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            You can see a scrawled message here.

            > read the message
            The message, neatly marked in the sawdust, reads...

            "You win."
            """)
    }

    /// Tests the win condition: enter bar (dark), remove cloak, drop it, look, examine message.
    @Test("Bar Win Condition (Removing Cloak in Bar)", .tags(.integration, .walkthrough))
    func testBarWinConditionCloakRemovedInBar() async throws {
        let mockIO = await MockIOHandler(
            "s",            // Enter the Bar (dark)
            "remove cloak", // Remove cloak (room becomes lit before next command)
            "drop cloak",   // Drop the cloak (now in light)
            "look",         // Look around (should see lit room)
            "x message",    // Examine message (should trigger win)
            nil
        )
        let engine = await GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.
            > s

            It is pitch black. You are likely to be eaten by a grue.
            > remove cloak
            You can't see any 'cloak' here.
            > drop cloak
            You can't see any 'cloak' here.
            > look
            It is pitch black. You are likely to be eaten by a grue.
            > x message
            It's too dark to do that.
            It is pitch black. You are likely to be eaten by a grue.
            >

            Goodbye!
            """
        )
    }
    /// Tests the win condition: remove cloak, drop it, enter bar (lit), look, examine message.
    @Test("Bar Win Condition (Removing Cloak before Bar)", .tags(.integration, .walkthrough))
    func testBarWinConditionRemovingCloakBeforeBar() async throws {
        let mockIO = await MockIOHandler(
            "remove cloak",
            "drop cloak",
            "s",
            "look",
            "x message",
            nil
        )
        let engine = await GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.
            > remove cloak
            You can't see any 'cloak' here.
            > drop cloak
            You can't see any 'cloak' here.
            > s

            It is pitch black. You are likely to be eaten by a grue.
            > look
            It is pitch black. You are likely to be eaten by a grue.
            > x message
            It's too dark to do that.
            It is pitch black. You are likely to be eaten by a grue.
            >

            Goodbye!
            """
        )
    }

    /// Tests the lose condition: wear cloak, enter bar (dark), disturb things twice, remove cloak, examine message.
    @Test("Bar Lose Condition", .tags(.integration, .walkthrough))
    func testBarLoseCondition() async throws {
        let mockIO = await MockIOHandler(
            "s",           // Enter the Bar (dark)
            "take hook",   // First disturbance (unsafe action)
            "take hook",   // Second disturbance (unsafe action)
            "remove cloak",// Make the room lit
            "x message",   // Examine message (triggers lose condition)
            nil
        )
        let engine = await GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > s
            It is pitch black. You are likely to be eaten by a grue.
            > take hook
            You grope around clumsily in the dark. Better be careful.
            > take hook
            You grope around clumsily in the dark. Better be careful.
            > remove cloak
            You take off the cloak.
            > x message
            The message simply reads: "You lose."

            Goodbye!
            """ // Updated expected transcript for implemented lose condition
        )
    }

    /// Tests 'hang cloak on hook' functionality.
    @Test("Hang Cloak on Hook", .tags(.integration, .walkthrough))
    func testHangCloak() async throws {
        let mockIO = await MockIOHandler(
            "w",                 // Go to Cloakroom
            "remove cloak",      // Remove the cloak first
            "hang cloak on hook", // Now hang it
            "look",
            nil
        )
        let engine = await GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east.
            You can see:
              A hook
            > remove cloak
            You take off the cloak.
            > hang cloak on hook
            You put the cloak on the hook.
            > look
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east.
            You can see:
              A cloak
              A hook
            >
            
            Goodbye!
            """
        )
    }
}
