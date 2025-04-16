import CustomDump
import Testing

@testable import GnustoEngine

// Helper class for sharing state with closures in tests
@MainActor // Ensure properties accessed on main actor
private class TestStateHolder {
    var flag = false
    var count = 0
}

@Suite("GameEngine Tests")
struct GameEngineTests {

    // Removed instance properties - will declare locally in tests
    // var mockIOHandler: MockIOHandler!
    // var mockParser: MockParser!
    // var engine: GameEngine!
    // var initialState: GameState!

    // Helper to create a minimal game state for testing
    // Make static as it doesn't depend on instance state
    static func createMinimalGameState() -> GameState {
        let items = [Item(id: "startItem", name: "pebble", properties: [.takable])]
        let locations = [Location(id: "startRoom", name: "Void", description: "An empty void.")]
        let player = Player(currentLocationID: "startRoom")
        // Include necessary verbs for tests
        let verbs = [
            Verb(id: "look"),
            Verb(id: "take"),
            Verb(id: "inventory"),
            Verb(id: "quit")
        ]
        let vocabulary = Vocabulary.build(items: items, verbs: verbs)
        return GameState.initial(
            initialLocations: locations,
            initialItems: items,
            initialPlayer: player,
            vocabulary: vocabulary,
            initialItemLocations: ["startItem": "startRoom"]
        )
    }

    // Helper to create a minimal registry for tests
    // Make static as it doesn't depend on instance state
    @MainActor // Needed because FuseDefinition init is @MainActor
    static func createMinimalRegistry(fuseDefs: [FuseDefinition] = [], daemonDefs: [Daemon] = []) -> GameDefinitionRegistry {
        // TODO: Add daemon definitions when DaemonDefinition exists
        return GameDefinitionRegistry(fuseDefinitions: fuseDefs)
    }

    @Test("Engine Run Initialization and First Prompt in Dark Room")
    @MainActor
    func testEngineRunInitializationInDarkRoom() async throws {
        // Arrange - Declare locally
        let initialState = Self.createMinimalGameState() // Creates a dark room
        let mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIOHandler, registry: registry) // Pass registry

        // Configure Mock IO to provide one input then stop
        await mockIOHandler.enqueueInput("quit")

        // Act
        await engine.run()

        // Assert
        // Verify setup was called
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)

        // Verify initial location description was printed
        let output = await mockIOHandler.flush()
        expectNoDifference(output, """
            It is pitch black. You are likely to be eaten by a grue.
            > quit
            """)

        // TODO: Check for item listing once implemented in describeCurrentLocation

        // Verify status line was shown before prompt
        let statuses = await mockIOHandler.recordedStatusLines
        #expect(statuses.count == 1)
        #expect(statuses.first?.roomName == "Void")
        #expect(statuses.first?.score == 0)
        #expect(statuses.first?.turns == 0) // Turn counter not incremented yet

        // Verify teardown was called
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1)
    }

    @Test("Engine Handles Parse Error")
    @MainActor
    func testEngineHandlesParseError() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        // Configure parser to always return an error
        let parseError = ParseError.unknownVerb("xyzzy")
        mockParser.defaultParseResult = .failure(parseError)

        // Configure IO for one failed command then quit
        await mockIOHandler.enqueueInput("xyzzy", "quit")

        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIOHandler, registry: registry) // Pass registry

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1, "IOHandler setup should be called once")

        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1, "IOHandler teardown should be called once")

        // Check that the specific error message was printed
        let output = await mockIOHandler.recordedOutput
        let expectedMessage = "I don\'t know the verb 'xyzzy'."
        #expect(output.contains { $0.text == expectedMessage }, "Expected parse error message not found in output")

        // Check turn counter was incremented despite error
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 1, "Turn counter should increment even on parse error")
    }

    @Test("Engine Handles Action Error")
    @MainActor
    func testEngineHandlesActionError() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        // Make pebble non-takable in this test's state
        initialState.items["startItem"]?.properties.remove(.takable)
        #expect(initialState.items["startItem"]?.hasProperty(.takable) == false)

        // Command for "take pebble"
        let takeCommand = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")

        // Configure parser to succeed
        mockParser.parseHandler = { input, _, _ in
            if input == "take pebble" { return .success(takeCommand) }
            if input == "quit" { return .failure(.emptyInput) } // Simulate quit needs a verb
            return .failure(.unknownVerb(input))
        }

        // Configure mock action handler to throw error
        // Must await actor initialization
        let mockTakeHandler = MockActionHandler(errorToThrow: .itemNotTakable("startItem"))

        // Create engine with the mock handler
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry, // Pass registry
            customHandlers: [VerbID("take"): mockTakeHandler]
        )

        // Configure IO
        await mockIOHandler.enqueueInput("take pebble", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1)

        // Check that the specific action error message was printed
        let output = await mockIOHandler.recordedOutput
        let expectedMessage = "You can't take that."
        #expect(output.contains { $0.text == expectedMessage }, "Expected action error message not found")

        // Verify the handler was called (optional but good practice)
        let handlerCalled = await mockTakeHandler.getPerformCalled()
        #expect(handlerCalled == true, "MockActionHandler.perform should have been called")
        let commandReceived = await mockTakeHandler.getLastCommandReceived()
        #expect(commandReceived?.verbID == "take")
        #expect(commandReceived?.directObject == "startItem")

        // Check turn counter incremented
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 1, "Turn counter should increment even on action error")
    }

    @Test("Engine Processes Successful Command")
    @MainActor
    func testEngineProcessesSuccessfulCommand() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        let lookCommand = Command(verbID: "look", rawInput: "look")

        // Configure parser
        mockParser.parseHandler = { input, _, _ in
            if input == "look" { return .success(lookCommand) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        // Configure mock LOOK handler to just record the call
        let mockLookHandler = MockActionHandler()

        // Create engine with the mock handler
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry, // Pass registry
            customHandlers: [VerbID("look"): mockLookHandler]
        )

        // Configure IO
        await mockIOHandler.enqueueInput("look", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1)

        // Verify the handler was called with the correct command
        let handlerCalled = await mockLookHandler.getPerformCalled()
        #expect(handlerCalled == true, "MockActionHandler.perform should have been called for LOOK")
        let commandReceived = await mockLookHandler.getLastCommandReceived()
        #expect(commandReceived?.verbID == "look", "Handler received incorrect verb")

        // Check turn counter incremented
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 1, "Turn counter should increment for successful command")
    }

    @Test("Engine Processes Multiple Commands")
    @MainActor
    func testEngineProcessesMultipleCommands() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        let lookCommand = Command(verbID: "look", rawInput: "look")
        // Let's use the pebble from the minimal state
        let takePebbleCommand = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")

        // Configure parser for the sequence
        mockParser.parseHandler = { input, _, _ in
            switch input {
            case "look": return .success(lookCommand)
            case "take pebble": return .success(takePebbleCommand)
            case "quit": return .failure(.emptyInput) // Simulate quit needs a verb
            default: return .failure(.unknownVerb(input))
            }
        }

        // Configure mock handlers
        let mockLookHandler = MockActionHandler()
        let mockTakeHandler = MockActionHandler()

        // Create engine
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry, // Pass registry
            customHandlers: [
                VerbID("look"): mockLookHandler,
                VerbID("take"): mockTakeHandler
            ]
        )

        // Configure IO for the command sequence
        await mockIOHandler.enqueueInput("look", "take pebble", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1)

        // Verify handlers were called
        let lookHandlerCalled = await mockLookHandler.getPerformCalled()
        #expect(lookHandlerCalled == true, "Look handler should be called")
        let takeHandlerCalled = await mockTakeHandler.getPerformCalled()
        #expect(takeHandlerCalled == true, "Take handler should be called")

        // Verify commands received by handlers
        let lookCommandReceived = await mockLookHandler.getLastCommandReceived()
        #expect(lookCommandReceived?.verbID == "look")
        let takeCommandReceived = await mockTakeHandler.getLastCommandReceived()
        #expect(takeCommandReceived?.verbID == "take")
        #expect(takeCommandReceived?.directObject == "startItem")

        // Check turn counter reflects two successful commands
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 2, "Turn counter should be 2 after two successful commands")

        // Check status line was updated for each turn (initial + 2 turns)
        let statuses = await mockIOHandler.recordedStatusLines
        #expect(statuses.count == 3) // Initial state + 2 turns
        #expect(statuses[0].turns == 0)
        #expect(statuses[1].turns == 1)
        #expect(statuses[2].turns == 2)
    }

    @Test("Engine Exits Gracefully on Quit Command")
    @MainActor
    func testEngineExitsGracefullyOnQuitCommand() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        let quitCommand = Command(verbID: "quit", rawInput: "quit")

        // Configure parser to recognize "quit"
        mockParser.parseHandler = { input, _, _ in
            if input == "quit" { return .success(quitCommand) }
            return .failure(.unknownVerb(input))
        }

        // Configure mock QUIT handler - it does nothing, signalling successful handling
        let mockQuitHandler = MockActionHandler()

        // Create engine
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry, // Pass registry
            customHandlers: [VerbID("quit"): mockQuitHandler]
        )

        // Configure IO for just the quit command
        await mockIOHandler.enqueueInput("quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1, "Teardown should be called on graceful exit")

        // Verify the quit handler was NOT called (engine handles quit internally)
        // let quitHandlerCalled = await mockQuitHandler.getPerformCalled()
        // #expect(quitHandlerCalled == true, "Quit handler should be called") <-- Removed
        // let quitCommandReceived = await mockQuitHandler.getLastCommandReceived()
        // #expect(quitCommandReceived?.verbID == "quit") <-- Removed

        // Check turn counter - should NOT increment if quit happens before increment.
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 0, "Turn counter should not increment for the quit command if exit happens first")

        // Verify output - only initial description, status, and prompt, then nothing after quit
        let output = await mockIOHandler.recordedOutput
        let quitPromptIndex = output.lastIndex { $0.text == "> " && $0.style == .input }
        #expect(quitPromptIndex != nil, "Expected a prompt before quit")

        // Ensure no further prompts or outputs happened after the quit command's prompt
        if let quitPromptIndex {
             #expect(output.count == quitPromptIndex + 1, "No output should occur after the quit command prompt")
        }

         // Check status line was shown only for initial state
        let statuses = await mockIOHandler.recordedStatusLines
        #expect(statuses.count == 1) // Only initial state, loop exits before turn 1 status
        #expect(statuses[0].turns == 0)
    }

    @Test("Engine Handles Nil Input (EOF) Gracefully")
    @MainActor
    func testEngineHandlesNilInputGracefully() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        let mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIOHandler, registry: registry) // Pass registry

        // Configure Mock IO to provide NO input, triggering readLine to return nil immediately after the first prompt
        // No need to call enqueueInput

        // Act
        await engine.run()

        // Assert
        // Verify setup and teardown were called
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1, "Teardown should be called even on nil input")

        // Verify initial output occurred (room desc, status, prompt)
        let output = await mockIOHandler.flush()
        expectNoDifference(output, """
            It is pitch black. You are likely to be eaten by a grue.
            >

            Goodbye!
            """)

        // Check status line was shown only for the initial state
        let statuses = await mockIOHandler.recordedStatusLines
        #expect(statuses.count == 1)
        #expect(statuses.first?.turns == 0)

        // Verify no commands were processed (turn counter remains 0)
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 0, "Turn counter should not increment if no input is read")
    }

    @Test("Engine State Persists Between Turns (Take -> Inventory)")
    @MainActor
    func testEngineStatePersistsBetweenTurns() async throws {
        // Arrange
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Create registry

        // Ensure pebble is initially takable and in the room
        #expect(initialState.items["startItem"]?.hasProperty(.takable) == true)
        #expect(initialState.itemLocation(id: "startItem") == .location("startRoom"))
        #expect(initialState.itemsInInventory().isEmpty == true) // No player ID needed

        let takePebbleCommand = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")
        let inventoryCommand = Command(verbID: "inventory", rawInput: "inventory")

        // Configure parser
        mockParser.parseHandler = { input, _, _ in
            switch input {
            case "take pebble": return .success(takePebbleCommand)
            case "inventory": return .success(inventoryCommand)
            case "quit": return .failure(.emptyInput)
            default: return .failure(.unknownVerb(input))
            }
        }

        // Configure mock TAKE handler to modify game state
        let mockTakeHandler = MockActionHandler(performHandler: { command, engine in
            // Simulate taking the pebble using direct engine methods
            await engine.updateItemParent(itemID: "startItem", newParent: .player)
            // Add a success message
            await engine.ioHandler.print("Taken.")
        })

        // Configure mock INVENTORY handler to just record call (state check done later)
        let mockInventoryHandler = MockActionHandler()

        // Create engine with necessary verbs in vocabulary & handlers
        // No longer needed - verbs added in createMinimalGameState
        // initialState.vocabulary.addVerb(Verb(id: "take"))
        // initialState.vocabulary.addVerb(Verb(id: "inventory"))
        // initialState.vocabulary.addVerb(Verb(id: "quit")) // Ensure quit is known

        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry, // Pass registry
            customHandlers: [
                VerbID("take"): mockTakeHandler,
                VerbID("inventory"): mockInventoryHandler,
                // No Quit handler needed - handled internally
            ]
        )

        // Configure IO for the command sequence
        await mockIOHandler.enqueueInput("take pebble", "inventory", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIOHandler.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIOHandler.teardownCallCount
        #expect(teardownCount == 1)

        // Verify handlers were called
        let takeHandlerCalled = await mockTakeHandler.getPerformCalled()
        #expect(takeHandlerCalled == true, "Take handler should be called")
        let inventoryHandlerCalled = await mockInventoryHandler.getPerformCalled()
        #expect(inventoryHandlerCalled == true, "Inventory handler should be called")

        // Verify the final state using safe engine accessors
        let finalPebbleSnapshot = engine.itemSnapshot(with: "startItem")
        #expect(finalPebbleSnapshot?.parent == .player, "Pebble snapshot should show parent as player")

        let finalInventorySnapshots = engine.itemSnapshots(withParent: .player)
        #expect(finalInventorySnapshots.contains { $0.id == "startItem" }, "Player inventory snapshots should contain pebble")

        let finalRoomSnapshots = engine.itemSnapshots(withParent: .location("startRoom"))
        #expect(finalRoomSnapshots.isEmpty == true, "Start room snapshots should be empty")

        // Check turn counter reflects two successful commands
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 2, "Turn counter should be 2 after take and inventory commands")

        // Check status lines were updated
        let statuses = await mockIOHandler.recordedStatusLines
        #expect(statuses.count == 3) // Initial + take + inventory
        #expect(statuses[0].turns == 0)
        #expect(statuses[1].turns == 1)
        #expect(statuses[2].turns == 2)

         // Verify output included "Taken."
        let output = await mockIOHandler.recordedOutput
        #expect(output.contains { $0.text == "Taken." })
    }

    // MARK: - Fuse & Daemon Tests

    @Test("Fuse executes after correct number of turns")
    @MainActor
    func testFuseExecution() async throws {
        var initialState = Self.createMinimalGameState() // Needs var to modify activeFuses
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()

        // Arrange: Define the fuse and its action
        let stateHolder = TestStateHolder()
        let fuseDef = FuseDefinition(id: "testFuse", initialTurns: 2) { _ in
            await mockIOHandler.print("Fuse triggered!")
            stateHolder.flag = true
        }
        // Simulate fuse being active in saved state
        initialState.activeFuses[fuseDef.id] = 2

        // Create registry containing the definition
        let registry = Self.createMinimalRegistry(fuseDefs: [fuseDef])

        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIOHandler, registry: registry)

        // Act: Run engine for 3 turns (look, look, quit)
        await mockIOHandler.enqueueInput("look", "look", "quit")
        mockParser.parseHandler = { input, _, _ in
            if input == "look" { return .success(Command(verbID: "look", rawInput: "look")) }
            if input == "quit" { return .failure(.emptyInput) } // Let engine handle quit
            return .failure(.unknownVerb(input))
        }
        await engine.run()

        // Assert
        let output = await mockIOHandler.recordedOutput // Fetch output before assertions
        #expect(output.contains { $0.text == "Fuse triggered!" }, "Fuse message not found in output") // Check message
        #expect(stateHolder.flag == true, "Fuse action flag not set") // Check state holder flag
        #expect(engine.playerMoves() == 2) // Check turns
        #expect(engine.getCurrentGameState().activeFuses[fuseDef.id] == nil, "Fuse state should be removed after execution") // Check persistent state
    }

    @Test("Daemon executes at correct frequency")
    @MainActor
    func testDaemonExecutionFrequency() async throws {
        let initialState = Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()
        let registry = Self.createMinimalRegistry() // Registry needed, but no fuse defs

        // Arrange: Define and register the daemon
        let stateHolder = TestStateHolder()
        let testDaemon = Daemon(id: "testDaemon", frequency: 3) { _ in
            await mockIOHandler.print("Daemon ran!")
            stateHolder.count += 1
        }
        // Daemons are typically registered, not loaded from state, but pass registry to engine init
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIOHandler, registry: registry, initialDaemons: [testDaemon])

        // Act: Run engine for 7 turns (look x 7, quit)
        let commands = Array(repeating: "look", count: 7) + ["quit"]
        for command in commands {
            await mockIOHandler.enqueueInput(command)
        }
        mockParser.parseHandler = { input, _, _ in
             if input == "look" { return .success(Command(verbID: "look", rawInput: "look")) }
             if input == "quit" { return .failure(.emptyInput) }
             return .failure(.unknownVerb(input))
         }
        await engine.run()

        // Assert
        // Daemons run at start of turn based on (turn + 1) % freq == 0
        // Turns: 0, 1, 2, 3, 4, 5, 6
        // Executes at end of turn 2 (before turn 3 starts, turnCount = 2, 2+1=3 % 3 == 0)
        // Executes at end of turn 5 (before turn 6 starts, turnCount = 5, 5+1=6 % 3 == 0)
        let expectedDaemonRuns = 2

        // Check daemon message count
        let output = await mockIOHandler.recordedOutput
        let daemonMessages = output.filter { $0.text == "Daemon ran!" }
        #expect(daemonMessages.count == expectedDaemonRuns, "Daemon message count mismatch")

        // Check daemon action counter
        #expect(stateHolder.count == expectedDaemonRuns, "Daemon action counter mismatch")
        #expect(engine.playerMoves() == 7)
    }

    // TODO: Test removeFuse
    // TODO: Test unregisterDaemon
    // TODO: Test fuse/daemon actions triggering quit
}

// Helper extension for OutputCall checks (optional) - Moved outside struct
extension [MockIOHandler.OutputCall] {
    func contains(text: String, style: TextStyle? = nil, newline: Bool? = nil) -> Bool {
        self.contains { call in
            var match = call.text.contains(text)
            if let style = style { match = match && call.style == style }
            if let newline = newline { match = match && call.newline == newline }
            return match
        }
    }
}
