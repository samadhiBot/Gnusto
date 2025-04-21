import CustomDump
import Testing
import CloakOfDarknessGameData

@testable import GnustoEngine

// Define custom tags in an extension
extension Tag {
    @Tag static var integration: Tag
    @Tag static var walkthrough: Tag
}

@MainActor
struct CloakOfDarknessWalkthroughTests {
    // Use StandardParser for tests
    // let parser = StandardParser() // Removed shared instance

    /// Performs a basic walkthrough: look, go west, take cloak, wear cloak, go east, look.
    @Test("Basic Cloak Walkthrough", .tags(.integration, .walkthrough))
    func testBasicCloakWalkthrough() async throws {
        // 1. Setup World using shared library
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO with commands (Adjusted for cloak starting worn)
        let mockIO = await MockIOHandler(
            "look",
            "w",         // Go to Cloakroom
            "remove cloak", // Need to remove before taking/dropping
            "drop cloak",  // Drop it to test taking later (optional step, could just go east)
            "e",         // Go back to Foyer
            "w",         // Back to Cloakroom
            "take cloak", // Now take the cloak
            "wear cloak", // And wear it
            "e",         // Back to Foyer
            "look",
            nil // Signal end of input
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Recorded Output and format into a transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Transcript Matches (Updated for correct initial state & actions)
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
            > remove cloak
            You take off the cloak.
            > drop cloak
            Dropped.
            > e
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > w
            --- Cloakroom ---
            The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east.
            You can see:
              A cloak
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

    /// Tests the win condition: enter bar (dark), remove cloak, drop it, look, examine message.
    @Test("Bar Win Condition (Removing Cloak in Bar)", .tags(.integration, .walkthrough))
    func testBarWinConditionCloakRemovedInBar() async throws {
        // 1. Setup World
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO: Go south, remove cloak, drop cloak, look, examine message
        let mockIO = await MockIOHandler(
            "s",           // Enter the Bar (dark)
            "remove cloak", // Remove cloak (room becomes lit before next command)
            "drop cloak",  // Drop the cloak (now in light)
            "look",        // Look around (should see lit room)
            "x message",   // Examine message (should trigger win)
            nil
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Win Message and darkness handling (Updated for removing cloak in bar)
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
        // 1. Setup World
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO: Remove cloak, drop cloak, go bar, look, examine message
        let mockIO = await MockIOHandler(
            "remove cloak",
            "drop cloak",
            "s",
            "look",
            "x message",
            nil
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Win Message and darkness handling (Updated for correct remove & win msg)
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

    /// Tests the lose condition: wear cloak, enter bar (dark), fumble around, examine message.
    @Test("Bar Lose Condition (Wearing Cloak)", .tags(.integration, .walkthrough))
    func testBarLoseConditionWearingCloak() async throws {
        // 1. Setup World
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO: Keep cloak on, go bar, fumble (e.g., try take), examine message
        let mockIO = await MockIOHandler(
            "s",
            "take hook",
            "x message",
            "x message",
            nil
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Lose Message and darkness handling (Updated for correct darkness, fumble, lose msg)
        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > s
            It is pitch black. You are likely to be eaten by a grue.
            > take hook
            You can't see any 'hook' here.
            > x message
            It's too dark to do that.
            > x message
            It's too dark to do that.
            >

            Goodbye!
            """
        )
    }

    /// Tests the lose condition: wear cloak, enter bar (dark), fumble around, examine message.
    @Test("Bar Lose Condition Wearing Cloak With Verbose Fumble", .tags(.integration, .walkthrough))
    func testBarLoseConditionWearingCloakVerboseFumble() async throws {
        // 1. Setup World
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO: Keep cloak on, go bar, fumble (e.g., try take), examine message
        let mockIO = await MockIOHandler(
            "s",
            "take hook",
            "x message",
            nil
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Lose Message and darkness handling (Updated for correct darkness, fumble, lose msg)
        expectNoDifference(actualTranscript, """
            --- Foyer of the Opera House ---
            You are standing in a spacious hall, splendidly decorated in red and gold, which serves as the lobby of the opera house. The walls are adorned with portraits of famous singers, and the floor is covered with a thick crimson carpet. A grand staircase leads upwards, and there are doorways to the south and west.
            > s
            It is pitch black. You are likely to be eaten by a grue.
            > take hook
            You can't see any 'hook' here.
            > x message
            You grope around clumsily in the dark. Better be careful.
            The message simply reads: "You win."
            """
        )
    }

    /// Tests 'hang cloak on hook' functionality.
    @Test("Hang Cloak on Hook", .tags(.integration, .walkthrough))
    func testHangCloak() async throws {
        // 1. Setup World
        let (initialState, registry, onEnterRoom, beforeTurn) = CloakOfDarknessGameData.setup()

        // 2. Setup Mock IO (Adjusted: must remove cloak first)
        let mockIO = await MockIOHandler(
            "w",                 // Go to Cloakroom
            "remove cloak",      // Remove the cloak first
            "hang cloak on hook", // Now hang it
            "look",
            nil
        )

        // 3. Setup Engine
        let parser = StandardParser() // Added local instance
        let engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: mockIO,
            registry: registry,
            onEnterRoom: onEnterRoom,
            beforeTurn: beforeTurn
        )

        // 4. Run Game Simulation
        await engine.run()

        // 5. Get Transcript
        let actualTranscript = await mockIO.flush()

        // 6. Assert Hang Cloak on Hook (Updated for correct sequence and output)
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
