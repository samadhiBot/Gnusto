import Testing
@testable import GnustoEngine
import CustomDump // For potentially better diffs later

// Define custom tags in an extension
extension Tag {
    @Tag static var integration: Tag
    @Tag static var walkthrough: Tag
}

@Suite("Cloak of Darkness Walkthrough Tests")
struct CloakOfDarknessWalkthroughTests {

    /// Performs a basic walkthrough: look, go west, take cloak, wear cloak, go east, look.
    @Test("Basic Cloak Walkthrough", .tags(.integration, .walkthrough))
    @MainActor // Required for GameEngine interaction
    func testBasicCloakWalkthrough() async throws {
        // 1. Setup World
        let (initialState, parser, customHandlers) = WorldSetups.setupCloakOfDarknessWorld()

        // 2. Setup Mock IO with commands
        let walkthroughCommands = [
            "look",
            "w",
            "take cloak",
            "wear cloak",
            "e",
            "look",
            // Let input run out to end the game
        ]
        let mockIO = await MockIOHandler()
        // Enqueue inputs one by one, awaiting each call to the actor
        for command in walkthroughCommands {
            await mockIO.enqueueInput(command)
        }
        await mockIO.enqueueInput(nil) // Signal end of input

        // 3. Setup Engine
        let engine = GameEngine( // Add await
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            customHandlers: customHandlers
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Recorded Output
        let recordedOutputCalls = await mockIO.getRecordedOutput()
        let recordedOutputText = recordedOutputCalls.map { $0.text } // Extract just the text for now

        // 6. Assert Output (Basic sequence check for now)
        // TODO: Improve output assertion - this is very brittle!
        #expect(recordedOutputText.count > 10, "Expected a reasonable amount of output lines.")

        // Example of more specific checks (prone to breaking if formatting changes):
        #expect(recordedOutputText.contains { $0.contains("Foyer of the Opera House") }, "Should show Foyer description.")
        #expect(recordedOutputText.contains { $0.contains("You can see:") }, "Should list visible items.")
        // The hook is inside the cloakroom, not visible initially
        // #expect(recordedOutputText.contains { $0.contains("A hook") }, "Should show hook initially.")
        #expect(recordedOutputText.contains { $0.contains("--- Cloakroom ---") }, "Should show Cloakroom description after moving west.")
        #expect(recordedOutputText.contains { $0 == "Taken." }, "Should confirm cloak was taken.")
        #expect(recordedOutputText.contains { $0 == "You put on the cloak." }, "Should confirm cloak was worn.")

        // Verify input prompts were also recorded
        #expect(recordedOutputCalls.contains { $0.text == "> " && $0.style == .input && !$0.newline }, "Should show input prompt.")

        // Optional: Print output for manual verification during test development
        print("\n--- Recorded Walkthrough Output ---")
        recordedOutputCalls.forEach { print("\($0.style == .input ? "" : "[\($0.style)] ")\($0.text)", terminator: $0.newline ? "\n" : "") }
        print("--- End Recorded Output ---")
    }
}

// Helper extension no longer needed as we enqueue one by one
// extension MockIOHandler {
//     @IOActor
//     func enqueueInput(contentsOf sequence: [String?]) {
//         for item in sequence {
//             enqueueInput(item)
//         }
//     }
// }
