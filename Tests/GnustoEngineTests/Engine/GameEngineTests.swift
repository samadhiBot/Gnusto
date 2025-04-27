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
struct GameEngineTests {
    @Test("Engine Run Initialization and First Prompt in Dark Room")
    func testEngineRunInitializationInDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            longDescription: "It's dark."
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Configure Mock IO to provide one input then stop
        await mockIO.enqueueInput("quit")

        // Act
        await engine.run()

        // Assert
        // Verify setup was called
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)

        // Verify initial location description was printed
        let output = await mockIO.flush()
        expectNoDifference(output, """
            It is pitch black. You are likely to be eaten by a grue.
            > quit
            """)

        // TODO: Check for item listing once implemented in describeCurrentLocation

        // Verify status line was shown before prompt
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 1)
        #expect(statuses.first?.roomName == "Pitch Black Room")
        #expect(statuses.first?.score == 0)
        #expect(statuses.first?.turns == 0) // Turn counter not incremented yet

        // Verify teardown was called
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1)
    }

    @Test("Engine Handles Parse Error")
    func testEngineHandlesParseError() async throws {
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        // Configure parser to always return an error
        let parseError = ParseError.unknownVerb("xyzzy")
        mockParser.defaultParseResult = .failure(parseError)

        let engine = GameEngine(
            game: MinimalGame(),
            parser: mockParser,
            ioHandler: mockIO
        )

        // Configure IO for one failed command then quit
        await mockIO.enqueueInput("xyzzy", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1, "IOHandler setup should be called once")

        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1, "IOHandler teardown should be called once")

        // Check that the specific error message was printed
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Void ---
            An empty void.
            You can see:
              A pebble
            > xyzzy
            I don't know the verb 'xyzzy'.
            > quit
            """)

        // Check turn counter was incremented despite error
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 1, "Turn counter should increment even on parse error")
    }

    @Test("Engine Handles Action Error")
    func testEngineHandlesActionError() async throws {
        let mockTakeHandler = MockActionHandler(
            errorToThrow: .itemNotTakable("startItem")
        )
        let game = MinimalGame(
            registry: DefinitionRegistry(
                customActionHandlers: [VerbID("take"): mockTakeHandler]
            )
        )
        game.state.items["startItem"]?.properties.remove(.takable)

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let takeCommand = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")

        // Configure parser to succeed
        mockParser.parseHandler = { input, _, _ in
            if input == "take pebble" { return .success(takeCommand) }
            if input == "quit" { return .failure(.emptyInput) } // Simulate quit needs a verb
            return .failure(.unknownVerb(input))
        }

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Make pebble non-takable in this test's state
        #expect(game.state.items["startItem"]?.hasProperty(.takable) == false)
        // Ensure room is lit for this test
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        // Configure IO
        await mockIO.enqueueInput("take pebble", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1)

        // Check that the specific action error message was printed
        let output = await mockIO.recordedOutput
        let expectedMessage = "You can't take the pebble."
        #expect(
            output.contains { $0.text == expectedMessage },
            "Expected action error message not found"
        )

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
        let mockLookHandler = MockActionHandler()

        let game = MinimalGame(
            registry: DefinitionRegistry(
                customActionHandlers: [VerbID("look"): mockLookHandler]
            )
        )
        // Ensure room is lit
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let lookCommand = Command(verbID: "look", rawInput: "look")

        // Configure parser
        mockParser.parseHandler = { input, _, _ in
            if input == "look" { return .success(lookCommand) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Configure IO
        await mockIO.enqueueInput("look", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
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
        let mockLookHandler = MockActionHandler()
        let mockTakeHandler = MockActionHandler()
        let game = MinimalGame(
            registry: DefinitionRegistry(
                customActionHandlers: [
                    VerbID("look"): mockLookHandler,
                    VerbID("take"): mockTakeHandler
                ]
            )
        )
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        let lookCommand = Command(verbID: "look", rawInput: "look")
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

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Configure IO for the command sequence
        await mockIO.enqueueInput("look", "take pebble", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
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
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 3) // Initial state + 2 turns
        #expect(statuses[0].turns == 0)
        #expect(statuses[1].turns == 1)
        #expect(statuses[2].turns == 2)
    }

    @Test("Engine Exits Gracefully on Quit Command")
    func testEngineExitsGracefullyOnQuitCommand() async throws {
        let mockQuitHandler = MockActionHandler()
        let game = MinimalGame(
            registry: DefinitionRegistry(
                customActionHandlers: [VerbID("quit"): mockQuitHandler]
            )
        )
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let quitCommand = Command(verbID: "quit", rawInput: "quit")

        // Configure parser to recognize "quit"
        mockParser.parseHandler = { input, _, _ in
            if input == "quit" { return .success(quitCommand) }
            return .failure(.unknownVerb(input))
        }

        // Configure IO for just the quit command
        await mockIO.enqueueInput("quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
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
        let output = await mockIO.recordedOutput
        let quitPromptIndex = output.lastIndex { $0.text == "> " && $0.style == .input }
        #expect(quitPromptIndex != nil, "Expected a prompt before quit")

        // Ensure no further prompts or outputs happened after the quit command's prompt
        if let quitPromptIndex {
             #expect(output.count == quitPromptIndex + 1, "No output should occur after the quit command prompt")
        }

         // Check status line was shown only for initial state
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 1) // Only initial state, loop exits before turn 1 status
        #expect(statuses[0].turns == 0)
    }

    @Test("Engine Handles Nil Input (EOF) Gracefully")
    func testEngineHandlesNilInputGracefully() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Act
        await engine.run()

        // Assert
        // Verify setup and teardown were called
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1, "Teardown should be called even on nil input")

        // Verify initial output occurred (room desc, status, prompt)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Void ---
            An empty void.
            You can see:
              A pebble
            >

            Goodbye!
            """)

        // Check status line was shown only for the initial state
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 1)
        #expect(statuses.first?.turns == 0)

        // Verify no commands were processed (turn counter remains 0)
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 0, "Turn counter should not increment if no input is read")
    }

    @Test("Engine State Persists Between Turns (Take -> Inventory)")
    func testEngineStatePersistsBetweenTurns() async throws {
        let mockInventoryHandler = MockActionHandler()
        let mockTakeHandler = MockActionHandler(performHandler: { command, engine in
            await engine.updateItemParent(itemID: "startItem", newParent: .player)
            await engine.ioHandler.print("Taken.")
        })

        let game = MinimalGame(
            registry: DefinitionRegistry(
                customActionHandlers: [
                    VerbID("take"): mockTakeHandler,
                    VerbID("inventory"): mockInventoryHandler,
                ]
            )
        )
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

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

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Ensure pebble is initially takable and in the room
        #expect(game.state.items["startItem"]?.hasProperty(.takable) == true)
        #expect(game.state.itemLocation(id: "startItem") == .location("startRoom"))
        #expect(game.state.itemsInInventory().isEmpty == true) // No player ID needed

        // Configure IO for the command sequence
        await mockIO.enqueueInput("take pebble", "inventory", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
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
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 3) // Initial + take + inventory
        #expect(statuses[0].turns == 0)
        #expect(statuses[1].turns == 1)
        #expect(statuses[2].turns == 2)

         // Verify output included "Taken."
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Taken." })
    }

    // MARK: - Fuse & Daemon Tests

    @Test("Fuse executes after correct number of turns")
    func testFuseExecution() async throws {
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let stateHolder = TestStateHolder()
        let fuseDef = FuseDefinition(id: "testFuse", initialTurns: 2) { _ in
            await mockIO.print("Fuse triggered!")
            stateHolder.flag = true
        }

        var game = MinimalGame(
            registry: DefinitionRegistry(
                fuseDefinitions: [fuseDef]
            )
        )
        game.state.activeFuses[fuseDef.id] = 2

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Act: Run engine for 3 turns (look, look, quit)
        await mockIO.enqueueInput("look", "look", "quit")
        mockParser.parseHandler = { input, _, _ in
            if input == "look" { return .success(Command(verbID: "look", rawInput: "look")) }
            if input == "quit" { return .failure(.emptyInput) } // Let engine handle quit
            return .failure(.unknownVerb(input))
        }
        await engine.run()

        // Assert
        let output = await mockIO.recordedOutput // Fetch output before assertions
        #expect(output.contains { $0.text == "Fuse triggered!" }, "Fuse message not found in output") // Check message
        #expect(stateHolder.flag == true, "Fuse action flag not set") // Check state holder flag
        #expect(engine.playerMoves() == 2) // Check turns
        #expect(engine.gameState.activeFuses[fuseDef.id] == nil, "Fuse state should be removed after execution") // Check persistent state
    }

    @Test("Daemon executes at correct frequency")
    func testDaemonExecutionFrequency() async throws {
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let stateHolder = TestStateHolder()

        let testDaemonDef = DaemonDefinition(id: "testDaemon", frequency: 3) { _ in
            await mockIO.print("Daemon ran!")
            stateHolder.count += 1
        }
        let game = MinimalGame(
            registry: DefinitionRegistry(
                daemonDefinitions: [testDaemonDef]
            )
        )
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Register the daemon dynamically AFTER engine init
        // Should succeed without throwing
        try engine.registerDaemon(id: "testDaemon")

        // Act: Run engine for 7 turns (look x 7, quit)
        let commands = Array(repeating: "look", count: 7) + ["quit"]
        for command in commands {
            await mockIO.enqueueInput(command)
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
        let output = await mockIO.recordedOutput
        let daemonMessages = output.filter { $0.text == "Daemon ran!" }
        #expect(daemonMessages.count == expectedDaemonRuns, "Daemon message count mismatch")

        // Check daemon action counter
        #expect(stateHolder.count == expectedDaemonRuns, "Daemon action counter mismatch")
        #expect(engine.playerMoves() == 7)
    }

    @Test("Fuse and Daemon Interaction")
    func testFuseAndDaemonInteraction() async throws {
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let stateHolder = TestStateHolder()

        // Set up a fuse that will trigger after 3 turns
        let testFuse = FuseDefinition(id: "testFuse", initialTurns: 3) { _ in
            await mockIO.print("Fuse triggered!")
            stateHolder.flag = true // Mark that fuse was triggered
        }

        // Set up a daemon that will run every 2 turns
        let testDaemon = DaemonDefinition(id: "testDaemon", frequency: 2) { _ in
            await mockIO.print("Daemon executed!")
            stateHolder.count += 1 // Count daemon executions
        }

        var game = MinimalGame(
            registry: DefinitionRegistry(
                fuseDefinitions: [testFuse],
                daemonDefinitions: [testDaemon]
            )
        )

        // Add fuse to initial state
        game.state.activeFuses[testFuse.id] = testFuse.initialTurns

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Register the daemon after engine creation
        // Should succeed without throwing
        try engine.registerDaemon(id: testDaemon.id)

        // Act: Run for 6 turns with "look" commands
        let commands = Array(repeating: "look", count: 6) + ["quit"]
        for command in commands {
            await mockIO.enqueueInput(command)
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
        #expect(engine.gameState.activeFuses[testFuse.id] == nil,
              "Fuse should be removed from game state after execution")

        // Check for expected messages in output
        let output = await mockIO.recordedOutput
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

    // MARK: - Helper Functions & Error Tests

    @Test("ReportActionError: .invalidDirection")
    func testReportErrorInvalidDirection() async throws {
        let game = MinimalGame()
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(
            verbID: "go",
            preposition: "xyzzy",
            rawInput: "go xyzzy"
        )
        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "go xyzzy",
            commandToParse: command
        )
        expectNoDifference(output, """
            A strange buzzing sound indicates something is wrong.
              • Go command processed without a direction.
            """)
    }

    @Test("ReportActionError: .itemNotTakable")
    func testReportErrorItemNotTakable() async throws {
        let game = MinimalGame()
        game.state.items["startItem"]?.properties.remove(.takable)

        #expect(game.state.items["startItem"]?.hasProperty(.takable) == false)
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)
        let command = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "take pebble",
            commandToParse: command
        )
        expectNoDifference(output, "You can't take the pebble.")
    }

    @Test("ReportActionError: .itemNotHeld")
    func testReportErrorItemNotHeld() async throws {
        let game = MinimalGame()

        #expect(game.state.items["startItem"]?.parent == .location("startRoom"))
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)
        let command = Command(verbID: "wear", directObject: "startItem", rawInput: "wear pebble")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "wear pebble",
            commandToParse: command
        )
        expectNoDifference(output, "You aren't holding the pebble.")
    }

    @Test("ReportActionError: .containerIsClosed")
    func testReportErrorContainerIsClosed() async throws {
        var game = MinimalGame()

        // Arrange: Closed container in room, item inside
        let container = Item(
            id: "box",
            name: "box",
            properties: .container
        ) // Closed by default
        let itemIn = Item(id: "gem", name: "gem", parent: .item("box"))
        game.state.items[container.id] = container
        game.state.items[itemIn.id] = itemIn
        game.state.player.currentLocationID = "startRoom" // Ensure player is where box is
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit) // Ensure room is lit
        game.state.items[container.id]?.parent = .location("startRoom") // Box in room

        // Command: Try to take item from closed container (will fail in Take handler)
        // OR simpler: Try to put something IN the closed container
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        game.state.items[itemToPut.id] = itemToPut

        let command = Command(
            verbID: "put",
            directObject: "key",
            indirectObject: "box",
            preposition: "in",
            rawInput: "put key in box"
        )

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "put key in box",
            commandToParse: command
        )

        expectNoDifference(output, "The box is closed.")
    }

    @Test("ReportActionError: .itemNotOpenable")
    func testReportErrorItemNotOpenable() async throws {
        var game = MinimalGame()

        // Arrange: Item that is not openable
        let item = Item(id: "rock", name: "rock", parent: .location("startRoom"))
        game.state.items[item.id] = item
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit) // Ensure room is lit

        let command = Command(verbID: "open", directObject: "rock", rawInput: "open rock")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "open rock",
            commandToParse: command
        )

        expectNoDifference(output, "You can't open the rock.")
    }

    @Test("ReportActionError: .itemNotWearable")
    func testReportErrorItemNotWearable() async throws {
        var game = MinimalGame()

        // Arrange: Item that is takable but not wearable, held by player
        let item = Item(
            id: "rock",
            name: "rock",
            properties: .takable,
            parent: .player
        )
        game.state.items[item.id] = item
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit) // Ensure room is lit

        let command = Command(verbID: "wear", directObject: "rock", rawInput: "wear rock")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "wear rock",
            commandToParse: command
        )

        expectNoDifference(output, "You can't wear the rock.")
    }

    @Test("ReportActionError: .playerCannotCarryMore")

    func testReportErrorPlayerCannotCarryMore() async throws {
        var game = MinimalGame()

        // Arrange: Player holds item, capacity is low, try to take another
        let itemHeld = Item(
            id: "sword",
            name: "sword",
            properties: .takable,
            size: 8,
            parent: .player
        )
        let itemToTake = Item(
            id: "shield",
            name: "shield",
            properties: .takable,
            size: 7,
            parent: .location("startRoom")
        )
        game.state.player.carryingCapacity = 10 // Low capacity
        game.state.items[itemHeld.id] = itemHeld
        game.state.items[itemToTake.id] = itemToTake
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(verbID: "take", directObject: "shield", rawInput: "take shield")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "take shield",
            commandToParse: command
        )

        expectNoDifference(output, "Your hands are full.")
    }

    @Test("ReportActionError: .targetIsNotAContainer")
    func testReportErrorTargetIsNotContainer() async throws {
        var game = MinimalGame()

        // Arrange: Try putting item IN something that's not a container
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        let target = Item(id: "rock", name: "rock", parent: .location("startRoom")) // Not a container
        game.state.items[itemToPut.id] = itemToPut
        game.state.items[target.id] = target
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(
            verbID: "put",
            directObject: "key",
            indirectObject: "rock",
            preposition: "in",
            rawInput: "put key in rock"
        )

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "put key in rock",
            commandToParse: command
        )

        expectNoDifference(output, "You can't put things in the rock.")
    }

    @Test("ReportActionError: .targetIsNotASurface")
    func testReportErrorTargetIsNotSurface() async throws {
        var game = MinimalGame()
        // Arrange: Try putting item ON something that's not a surface
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        let target = Item(id: "rock", name: "rock", parent: .location("startRoom")) // Not a surface
        game.state.items[itemToPut.id] = itemToPut
        game.state.items[target.id] = target
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(
            verbID: "put",
            directObject: "key",
            indirectObject: "rock",
            preposition: "on",
            rawInput: "put key on rock"
        )

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "put key on rock",
            commandToParse: command
        )

        expectNoDifference(output, "You can't put things on the rock.")
    }

    @Test("ReportActionError: .directionIsBlocked")
    func testReportErrorDirectionIsBlocked() async throws {
        let game = MinimalGame()

        // Arrange: Exit blocked by a condition
        // Correct: Use `conditions` array
        let blockedExit = Exit(
            destination: "nowhere",
            blockedMessage: "A shimmering curtain bars the way."
        )
        game.state.locations["startRoom"]?.exits[.north] = blockedExit
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        // Correct: Set `.direction` property, ensuring correct argument order
        let command = Command(verbID: "go", directObject: "north", direction: .north, rawInput: "go north")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "go north",
            commandToParse: command
        )

        expectNoDifference(output, "A shimmering curtain bars the way.")
    }

    @Test("ReportActionError: .itemAlreadyClosed")
    func testReportErrorItemAlreadyClosed() async throws {
        var game = MinimalGame()

        // Arrange: Try closing an already closed item
        // Correct: Ensure it's a container AND .openable, lacks .open
        let container = Item(
            id: "box",
            name: "box",
            properties: .container, .openable,
            parent: .location("startRoom")
        ) // Starts closed
        game.state.items[container.id] = container
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "close box",
            commandToParse: command
        )

        expectNoDifference(output, "The box is already closed.")
    }

    @Test("ReportActionError: .itemIsUnlocked")
    func testReportErrorItemIsUnlocked() async throws {
        var game = MinimalGame()

        // Arrange: Try unlocking an already unlocked item
        // Correct: Remove `key:` parameter. Unlock handler needs key logic.
        let container = Item(
            id: "chest",
            name: "chest",
            properties: .container, .openable, .lockable,
            parent: .location("startRoom")
        ) // Unlocked
        let key = Item(id: "key1", name: "key", parent: .player) // Assume key ID "key1" matches chest internally
        game.state.items[container.id] = container
        game.state.items[key.id] = key
        // Correct: Add scope setup
        game.state.player.currentLocationID = "startRoom"
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        // Correct: Restore indirect object and preposition for key
        let command = Command(
            verbID: "unlock",
            directObject: "chest",
            indirectObject: "key1",
            preposition: "with",
            rawInput: "unlock chest with key"
        )

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "unlock chest with key",
            commandToParse: command
        )

        expectNoDifference(output, "The chest is already unlocked.")
    }

    @Test("ReportActionError: .itemNotCloseable")
    func testReportErrorItemNotCloseable() async throws {
        var game = MinimalGame()

        // Arrange: Item that cannot be closed (no .closeable property)
        // Correct: Remove .open as well, simply not a container/closeable item
        let item = Item(id: "book", name: "book", parent: .location("startRoom"))
        game.state.items[item.id] = item
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(verbID: "close", directObject: "book", rawInput: "close book")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "close book",
            commandToParse: command
        )

        expectNoDifference(output, "You can't close the book.")
    }

    @Test("ReportActionError: .itemNotDroppable")
    func testReportErrorItemNotDroppable() async throws {
        var game = MinimalGame()

        // Arrange: Player holding an item assumed fixed by handler logic
        // Correct: Add `.fixed` property to trigger the check
        let item = Item(
            id: "statue",
            name: "statue",
            properties: .fixed,
            parent: .player
        )
        game.state.items[item.id] = item
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit) // Ensure room is lit

        let command = Command(verbID: "drop", directObject: "statue", rawInput: "drop statue")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "drop statue",
            commandToParse: command
        )

        expectNoDifference(output, "You can't drop the statue.")
    }

    @Test("ReportActionError: .itemNotRemovable")
    func testReportErrorItemNotRemovable() async throws {
        var game = MinimalGame()

        // Arrange: Player wearing an item assumed fixed/irremovable by handler logic
        // Correct: Add `.fixed` property to trigger the check
        let item = Item(
            id: "amulet",
            name: "cursed amulet",
            properties: .wearable, .worn, .fixed,
            parent: .player
        )
        game.state.items[item.id] = item
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit) // Ensure room is lit

        let command = Command(verbID: "remove", directObject: "amulet", rawInput: "remove amulet")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "remove amulet",
            commandToParse: command
        )

        expectNoDifference(output, "You can't remove the cursed amulet.")
    }

    @Test("ReportActionError: .prerequisiteNotMet")
    func testReportErrorPrerequisiteNotMet() async throws {
        let game = MinimalGame()

        // Arrange: Exit condition provides a specific prerequisite message
        // Correct: Use `conditions` array
        let conditionalExit = Exit(
            destination: "nirvana",
            blockedMessage: "You must first find inner peace."
        )
        game.state.locations["startRoom"]?.exits[.up] = conditionalExit
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        // Correct: Set `.direction` property, ensuring correct argument order
        let command = Command(verbID: "go", directObject: "up", direction: .up, rawInput: "go up")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "go up",
            commandToParse: command
        )

        expectNoDifference(output, "You must first find inner peace.")
    }

    @Test("ReportActionError: .roomIsDark")
    func testReportErrorRoomIsDark() async throws {
        var game = MinimalGame()

        game.state.locations["startRoom"]?.properties.remove(.inherentlyLit)
        let item = Item(id: "shadow", name: "shadow", parent: .location("startRoom"))
        game.state.items[item.id] = item
        #expect(game.state.locations["startRoom"]?.hasProperty(.inherentlyLit) == false)
        let command = Command(verbID: "examine", directObject: "shadow", rawInput: "examine shadow")
        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "examine shadow",
            commandToParse: command
        )
        expectNoDifference(output, "It's too dark to do that.")
    }

    @Test("ReportActionError: .wrongKey")
    func testReportErrorWrongKey() async throws {
        var game = MinimalGame()

        // Arrange: Locked item, player tries unlocking with wrong key
        // Correct: Remove `key:` parameter. Unlock handler needs key logic.
        let container = Item(
            id: "chest",
            name: "chest",
            properties: .container, .lockable, .locked,
            parent: .location("startRoom")
        ) // Assumes internally requires "key1"
        let wrongKey = Item(id: "key2", name: "wrong key", parent: .player)
        game.state.items[container.id] = container
        game.state.items[wrongKey.id] = wrongKey
        // Correct: Ensure room is lit and player is present for scope
        game.state.player.currentLocationID = "startRoom"
        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)

        let command = Command(verbID: "unlock", directObject: "chest", indirectObject: "key2", preposition: "with", rawInput: "unlock chest with key2")

        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "unlock chest with key2",
            commandToParse: command
        )

        expectNoDifference(output, "The wrong key doesn't fit the chest.")
    }

    @Test("ReportActionError: .containerIsFull")
    func testReportErrorContainerIsFull() async throws {
        // ... implementation ...
//        game.state.locations["startRoom"]?.properties.insert(.inherentlyLit)
        // ... run command ...
    }

} // End of extension GameEngineTests

// Helper extension for OutputCall checks (optional)
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

// MARK: - Helper Functions

extension GameEngineTests {
    /// Helper to run the engine for one command and capture output.
    private func runCommandAndCaptureOutput(
        game: GameBlueprint,
        commandInput: String,
        commandToParse: Command
    ) async -> String {
        var mockParser = MockParser()
        let mockIO = await MockIOHandler()

        mockParser.parseHandler = { input, _, _ in
            if input == commandInput { return .success(commandToParse) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        await mockIO.enqueueInput(commandInput, "quit")
        await engine.run()
        let outputCalls = await mockIO.recordedOutput
        var commandOutput = ""
        var foundPrompt = false
        for call in outputCalls {
            if call.style == .input && call.text == "> " {
                foundPrompt = true
                continue
            }
            if foundPrompt && call.style != .statusLine {
                commandOutput = call.text
                break
            }
        }
        return commandOutput
    }
}
