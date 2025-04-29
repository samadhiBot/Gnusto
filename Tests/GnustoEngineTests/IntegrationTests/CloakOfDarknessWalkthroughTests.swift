import CustomDump
import GnustoEngine
import Testing

@testable import CloakOfDarkness

extension Tag {
    @Tag static var integration: Tag
    @Tag static var walkthrough: Tag
}

@MainActor
struct CloakOfDarknessWalkthroughTests {
    /// Performs a basic walkthrough: look, go west, take cloak, wear cloak, go east, look.
    @Test("Basic Cloak Walkthrough", .tags(.integration, .walkthrough))
    func testBasicCloakWalkthrough() async throws {
        let mockIO = await MockIOHandler(
            "look",
            "w",            // Go to Cloakroom
            "remove cloak", // Need to remove before taking/dropping
            "drop cloak",   // Drop it to test taking later (optional step, could just go east)
            "e",            // Go back to Foyer
            "w",            // Back to Cloakroom
            "take cloak",   // Now take the cloak
            "wear cloak",   // And wear it
            "e",            // Back to Foyer
            "look",
            nil             // Signal end of input
        )
        let engine = GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red \
            and gold, with glittering chandeliers overhead. The entrance from \
            the street is to the north, and there are doorways south and west.
            > look
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red \
            and gold, with glittering chandeliers overhead. The entrance from \
            the street is to the north, and there are doorways south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, \
            though now only one remains. The exit is a door to the east.
            You can see:
              A small brass hook
            > remove cloak
            You take off the cloak.
            > drop cloak
            Dropped.
            > e
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red \
            and gold, with glittering chandeliers overhead. The entrance from \
            the street is to the north, and there are doorways south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, \
            though now only one remains. The exit is a door to the east.
            You can see:
              A cloak
              A small brass hook
            > take cloak
            Taken.
            > wear cloak
            You put on the cloak.
            > e
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red \
            and gold, with glittering chandeliers overhead. The entrance from \
            the street is to the north, and there are doorways south and west.
            > look
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red \
            and gold, with glittering chandeliers overhead. The entrance from \
            the street is to the north, and there are doorways south and west.
            >
            
            Goodbye!
            """
        )
    }

    /* TODO: re-enable the following tests after game state refactor

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
        let engine = GameEngine(
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
            > remove cloak
            You take off the cloak.
            > drop cloak
            Dropped.
            > look
            --- Bar ---
            The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.
            You can see:
              A cloak
              A message
            > x message
            The message simply reads: "You win."
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
        let engine = GameEngine(
            game: CloakOfDarkness(),
            parser: StandardParser(),
            ioHandler: mockIO
        )
        await engine.run()

        let actualTranscript = await mockIO.flush()

        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > remove cloak
            You take off the cloak.
            > drop cloak
            Dropped.
            > s
            --- Bar ---
            The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.
            You can see:
              A message
            > look
            --- Bar ---
            The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. There seems to be some sort of message scrawled in the sawdust on the floor.
            You can see:
              A message
            > x message
            The message simply reads: "You win."
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
        let engine = GameEngine(
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
        let engine = GameEngine(
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
     */
}
