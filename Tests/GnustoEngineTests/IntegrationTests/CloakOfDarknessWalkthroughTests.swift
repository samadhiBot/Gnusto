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
        let (initialState, parser, customHandlers) = WorldSetups.setupCloakOfDarknessWorld()

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
        let engine = GameEngine( // Add await
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            customHandlers: customHandlers
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Recorded Output and format into a transcript
        let actualTranscript = await mockIO.getTranscript()

        // 6. Assert Transcript Matches
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
}
