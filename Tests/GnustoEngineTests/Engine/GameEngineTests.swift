import CustomDump
import Testing

@testable import GnustoEngine

// Helper class for sharing state with closures in tests
@MainActor
private class TestStateHolder {
    var flag = false
    var count = 0
}

@MainActor
@Suite("GameEngine Tests")
struct GameEngineTests {
    // Helper to create a minimal game state for testing
    // Make static as it doesn't depend on instance state
    static func createMinimalGameState() async -> GameState {
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
    static func createMinimalRegistry(fuseDefs: [FuseDefinition] = [], daemonDefs: [DaemonDefinition] = []) -> GameDefinitionRegistry {
        return GameDefinitionRegistry(fuseDefinitions: fuseDefs, daemonDefinitions: daemonDefs) // Add daemonDefs
    }

    @Test("Engine Run Initialization and First Prompt in Dark Room")
    func testEngineRunInitializationInDarkRoom() async throws {
        // Arrange - Declare locally
        let initialState = await Self.createMinimalGameState() // Creates a dark room
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
    func testEngineHandlesParseError() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineHandlesActionError() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineProcessesSuccessfulCommand() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineProcessesMultipleCommands() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineExitsGracefullyOnQuitCommand() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineHandlesNilInputGracefully() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testEngineStatePersistsBetweenTurns() async throws {
        // Arrange
        let initialState = await Self.createMinimalGameState()
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
    func testFuseExecution() async throws {
        var initialState = await Self.createMinimalGameState() // Needs var to modify activeFuses
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
    func testDaemonExecutionFrequency() async throws {
        let initialState = await Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()

        // Arrange: Define the daemon definition
        let stateHolder = TestStateHolder()
        let testDaemonDef = DaemonDefinition(id: "testDaemon", frequency: 3) { _ in
            await mockIOHandler.print("Daemon ran!")
            stateHolder.count += 1
        }

        // Pass definition to registry
        let registry = Self.createMinimalRegistry(daemonDefs: [testDaemonDef])

        // Initialize engine without initialDaemons
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry
        )

        // Register the daemon dynamically AFTER engine init
        let registerSuccess = engine.registerDaemon(id: "testDaemon")
        #expect(registerSuccess == true, "Daemon registration should succeed")

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
        // Daemons run on turns where (turnCount > 0 && turnCount % frequency == 0)
        // With 7 "look" commands, we process turns 0-7
        // With frequency 3, daemon executes on:
        // - Turn 3 (3 % 3 == 0)
        // - Turn 6 (6 % 3 == 0)
        let expectedDaemonRuns = 2

        // Check daemon message count
        let output = await mockIOHandler.recordedOutput
        let daemonMessages = output.filter { $0.text == "Daemon ran!" }
        #expect(daemonMessages.count == expectedDaemonRuns, "Daemon message count mismatch")

        // Check daemon action counter
        #expect(stateHolder.count == expectedDaemonRuns, "Daemon action counter mismatch")
        #expect(engine.playerMoves() == 7)
    }

    @Test("Fuse and Daemon Interaction")
    func testFuseAndDaemonInteraction() async throws {
        // Arrange
        var initialState = await Self.createMinimalGameState()
        var mockParser = MockParser()
        let mockIOHandler = await MockIOHandler()

        // Create a state holder to track events
        let stateHolder = TestStateHolder()

        // Set up a fuse that will trigger after 3 turns
        let testFuse = FuseDefinition(id: "testFuse", initialTurns: 3) { _ in
            await mockIOHandler.print("Fuse triggered!")
            stateHolder.flag = true // Mark that fuse was triggered
        }

        // Set up a daemon that will run every 2 turns
        let testDaemon = DaemonDefinition(id: "testDaemon", frequency: 2) { _ in
            await mockIOHandler.print("Daemon executed!")
            stateHolder.count += 1 // Count daemon executions
        }

        // Create registry with both definitions
        let registry = Self.createMinimalRegistry(
            fuseDefs: [testFuse],
            daemonDefs: [testDaemon]
        )

        // Add fuse to initial state
        initialState.activeFuses[testFuse.id] = testFuse.initialTurns

        // Create engine with our test state
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIOHandler,
            registry: registry
        )

        // Register the daemon after engine creation
        let registerSuccess = engine.registerDaemon(id: testDaemon.id)
        #expect(registerSuccess == true, "Daemon registration should succeed")

        // Act: Run for 6 turns with "look" commands
        let commands = Array(repeating: "look", count: 6) + ["quit"]
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
        // For 6 "look" commands, we process 7 turns total (0-6)
        // With frequency 2, daemon executes when (turn > 0 && turn % 2 == 0)
        // Executes on turn 2 (2 % 2 == 0)
        // Executes on turn 4 (4 % 2 == 0)
        // Executes on turn 6 (6 % 2 == 0)
        let expectedDaemonRuns = 3

        // Check daemon execution count
        #expect(stateHolder.count == expectedDaemonRuns, "Daemon should have executed 3 times")

        // The fuse set for 3 turns should have triggered exactly once
        #expect(stateHolder.flag == true, "Fuse should have triggered")

        // Check that fuse was removed from game state
        #expect(engine.getCurrentGameState().activeFuses[testFuse.id] == nil,
              "Fuse should be removed from game state after execution")

        // Check for expected messages in output
        let output = await mockIOHandler.recordedOutput
        let fuseMessages = output.filter { $0.text == "Fuse triggered!" }
        let daemonMessages = output.filter { $0.text == "Daemon executed!" }

        #expect(fuseMessages.count == 1, "Should see exactly one fuse message")
        #expect(daemonMessages.count == expectedDaemonRuns, "Should see exactly three daemon messages")

        // Verify turn count - we expect 6 turns because we sent 6 "look" commands
        #expect(engine.playerMoves() == 6, "Game should have run for 6 turns")
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
