import CustomDump
import Testing

@testable import GnustoEngine

// Define custom tags in an extension
extension Tag {
    @Tag static var integration: Tag
    @Tag static var walkthrough: Tag
}

@Suite("Cloak of Darkness Walkthrough Tests")
struct CloakOfDarknessWalkthroughTests {
    /// Performs a basic walkthrough: look, go west, take cloak, wear cloak, go east, look.
    @Test("Basic Cloak Walkthrough", .tags(.integration, .walkthrough))
    @MainActor
    func testBasicCloakWalkthrough() async throws {
        // 1. Setup World
        let (initialState, parser, customHandlers, _, _, _) = WorldSetups.setupCloakOfDarknessWorld()

        // 2. Setup Mock IO with commands
        let mockIO = await MockIOHandler(
            "look",
            "w",
            "take cloak",
            "wear cloak",
            "e",
            "look",
            nil // Signal end of input
        )

        // 3. Setup Engine
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            customHandlers: customHandlers
            // No custom hooks needed for this test
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Recorded Output and format into a transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Transcript Matches (No changes expected here as Foyer/Cloakroom are lit)
        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > look
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east.
            You can see:
              A hook
            > take cloak
            Taken.
            > wear cloak
            You put on the cloak.
            > e
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > look
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            >
            Goodbye!
            """
        )
    }

    /// Tests the win condition: get cloak, wear it, enter bar (dark), look, examine message.
    @Test("Bar Win Condition", .tags(.integration, .walkthrough)) // Renamed test
    @MainActor
    func testBarWinCondition() async throws {
        // 1. Setup World
        let (initialState, parser, customHandlers, _, _, onExamineItem) = WorldSetups.setupCloakOfDarknessWorld()

        // 2. Setup Mock IO: get cloak, wear it, go bar, look, examine message
        let mockIO = await MockIOHandler(
            "w",           // Go to Cloakroom
            "take cloak",  // Take the cloak
            "wear cloak",  // Wear the cloak
            "e",           // Back to Foyer
            "s",           // Enter the Bar (should be dark)
            "look",        // Should just print darkness message
            "x message",   // Examine message (should trigger win)
            nil // End input
        )

        // 3. Setup Engine
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            customHandlers: customHandlers,
            // Pass only the necessary hook
            onExamineItem: onExamineItem
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Win Message and darkness handling
        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east.
            You can see:
              A hook
            > take cloak
            Taken.
            > wear cloak
            You put on the cloak.
            > e
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > s
            It is pitch black. You are likely to be eaten by a grue.
            > look
            It is pitch black. You are likely to be eaten by a grue.
            > x message
            The message simply reads: "You win."

            *** The End ***
            """
        )
    }
}
