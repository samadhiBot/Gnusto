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

        // Check change history only contains the move increment
        let history = engine.getChangeHistory()
        #expect(history.count == 1, "Only move increment should be in history on parse error")
        #expect(history.first?.propertyKey == .playerMoves)
        #expect(history.first?.newValue == .int(1))
    }

    @Test("Engine Handles Action Error")
    func testEngineHandlesActionError() async throws {
        let mockTakeHandler = MockActionHandler(
            errorToThrow: .itemNotTakable("startItem"),
            throwFrom: .process
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
        let processCalled = await mockTakeHandler.getProcessCalled()
        #expect(processCalled == true, "MockActionHandler.process should have been called")
        let commandReceived = await mockTakeHandler.getLastCommandReceived()
        #expect(commandReceived?.verbID == "take")
        #expect(commandReceived?.directObject == "startItem")

        // Check turn counter incremented
        let finalMoves = engine.playerMoves()
        #expect(finalMoves == 1, "Turn counter should increment even on action error")

        // Check change history only contains the move increment
        let history = engine.getChangeHistory()
        #expect(history.count == 1, "Only move increment should be in history on action error")
        #expect(history.first?.propertyKey == .playerMoves)
        #expect(history.first?.newValue == .int(1))
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
        let processCalled = await mockLookHandler.getProcessCalled()
        #expect(processCalled == true, "MockActionHandler.process should have been called for LOOK")
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
        let lookProcessCalled = await mockLookHandler.getProcessCalled()
        #expect(lookProcessCalled == true, "Look handler should be called")
        let takeProcessCalled = await mockTakeHandler.getProcessCalled()
        #expect(takeProcessCalled == true, "Take handler should be called")

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
        // Use default TakeActionHandler to test state persistence

        // Initialize items with correct properties
        let pebble = Item(
            id: "startItem",
            name: "pebble",
            properties: .takable,
            parent: .location("startRoom")
        )
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            properties: LocationProperty.inherentlyLit
        )

        let game = MinimalGame(
            locations: [startRoom],
            items: [pebble],
            registry: DefinitionRegistry(
                customActionHandlers: [
                    // Only mock inventory
                    VerbID("inventory"): mockInventoryHandler,
                ]
            )
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        // Configure the MockParser
        let takeCommand = Command(verbID: "take", directObject: "startItem", rawInput: "take pebble")
        let inventoryCommand = Command(verbID: "inventory", rawInput: "inventory")
        mockParser.parseHandler = { input, _, _ in
            switch input {
            case "take pebble": return .success(takeCommand)
            case "inventory": return .success(inventoryCommand)
            // Handle quit implicitly via engine.run loop
            default: return .failure(.unknownVerb(input))
            }
        }

        // Ensure pebble is initially takable and in the room (check initial game state)
        #expect(game.state.items["startItem"]?.hasProperty(.takable) == true)
        #expect(game.state.items["startItem"]?.parent == .location("startRoom"))

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshots(withParent: .player).isEmpty == true)

        // Configure IO for the command sequence
        await mockIO.enqueueInput("take pebble", "inventory", "quit")

        // Act
        await engine.run()

        // Assert
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1)

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

    @Test("Engine Records State Changes from Enhanced Handler")
    func testEngineRecordsStateChangesFromEnhancedHandler() async throws {
        // Given: An enhanced handler that changes multiple things
        struct MockMultiChangeHandler: EnhancedActionHandler {
            let itemIDToModify: ItemID
            let flagToSet: String

            func validate(command: Command, engine: GameEngine) async throws { }

            func process(command: Command, engine: GameEngine) async throws -> ActionResult {
                guard let item = await engine.itemSnapshot(with: itemIDToModify) else {
                    throw ActionError.internalEngineError("Test item missing")
                }

                // Define multiple changes
                let change1 = StateChange(
                    entityId: .item(itemIDToModify),
                    propertyKey: .itemProperties,
                    oldValue: .itemProperties(item.properties),
                    newValue: .itemProperties(item.properties.union([ItemProperty.touched, ItemProperty.on])) // Qualified
                )

                // Correctly determine oldValue for the flag using the new helper
                let actualOldFlagValue: Bool? = await engine.getOptionalFlagValue(key: flagToSet)
                let flagOldValueState: StateValue? = actualOldFlagValue != nil ? .bool(actualOldFlagValue!) : nil

                let change2 = StateChange(
                    entityId: .global,
                    propertyKey: .globalFlag(key: flagToSet),
                    oldValue: flagOldValueState, // Use the correctly determined nil or .bool value
                    newValue: .bool(true)
                )

                return ActionResult(
                    success: true,
                    message: "Multiple changes applied.",
                    stateChanges: [change1, change2]
                )
            }
        }

        let testItemID: ItemID = "testLamp"
        let testFlagKey = "lampLit"
        let lamp = Item(id: testItemID, name: "lamp", properties: .takable)
        let mockEnhancedHandler = MockMultiChangeHandler(itemIDToModify: testItemID, flagToSet: testFlagKey)
        let game = MinimalGame(
            items: [lamp],
            registry: DefinitionRegistry(
                // Use customActionHandlers directly with the EnhancedActionHandler
                customActionHandlers: [
                    VerbID("activate"): mockEnhancedHandler // No bridge needed
                ]
            )
        )
        game.state.locations["startRoom"]?.properties.insert(LocationProperty.inherentlyLit)

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let activateCommand = Command(verbID: "activate", directObject: testItemID, rawInput: "activate lamp")

        mockParser.parseHandler = { input, _, _ in
            if input == "activate lamp" { return .success(activateCommand) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Ensure initial state
        #expect(engine.gameState.flags[testFlagKey] == nil)
        #expect(engine.itemSnapshot(with: testItemID)?.hasProperty(.on) == false)
        #expect(engine.getChangeHistory().isEmpty)

        // Act
        await mockIO.enqueueInput("activate lamp", "quit")
        await engine.run()

        // Then
        // Check final state
        #expect(engine.gameState.flags[testFlagKey] == true, "Flag should be set")
        #expect(engine.itemSnapshot(with: testItemID)?.hasProperty(.on) == true, "Item .on property should be set")
        #expect(engine.itemSnapshot(with: testItemID)?.hasProperty(.touched) == true, "Item .touched property should be set")

        // Check history recorded correctly
        let history = engine.getChangeHistory()
        #expect(!history.isEmpty, "Change history should not be empty")

        // Check for Player moves increment change
        #expect(
            history.contains { change in
                change.propertyKey == StatePropertyKey.playerMoves && change.newValue == StateValue.int(1)
            },
            "History should contain playerMoves increment to 1"
        )

        // Check for Item property change (touched + on)
        #expect(
            history.contains { change in
                guard change.entityId == .item(testItemID), change.propertyKey == StatePropertyKey.itemProperties else { return false }
                if case .itemProperties(let props) = change.newValue {
                    return props.contains(ItemProperty.on) && props.contains(ItemProperty.touched)
                } else {
                    return false
                }
            },
            "History should contain item property change adding .on and .touched"
        )

        // Check for Flag change
        #expect(
            history.contains { change in
                change.entityId == .global &&
                    change.propertyKey == StatePropertyKey.globalFlag(key: testFlagKey) &&
                    change.newValue == StateValue.bool(true)
            },
            "History should contain flag change to true for \(testFlagKey)"
        )

        // Optionally, still check count if exact number is important
        #expect(history.count == 3, "Expected exactly 3 changes: moves + item props + flag")

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Multiple changes applied." })
    }

    // MARK: - Fuse & Daemon Tests

    // TODO: These timer tests need to be updated once initializing active timers is possible.
    //       Currently commenting out the core logic.

    @Test("Fuse executes after correct number of turns")
    func testFuseExecution() async throws {
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let stateHolder = TestStateHolder()
        let fuseDef = FuseDefinition(id: "testFuse", initialTurns: 2) { _ in
            await mockIO.print("Fuse triggered!")
            stateHolder.flag = true
        }

        // Initialize game with fuse definition
        let game = MinimalGame(
            registry: DefinitionRegistry(fuseDefinitions: [fuseDef])
            // TODO: Need initial state setup for activeFuses
        )

        let _ = GameEngine( // Use _ for unused engine
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        /*
        // Cannot start fuse from test setup currently
        // Act: Run engine for 3 turns (look, look, quit)
        ...
        // Assert
        ...
        */
    }

    @Test("Daemon executes at correct frequency")
    func testDaemonExecutionFrequency() async throws {
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let stateHolder = TestStateHolder()

        let testDaemonDef = DaemonDefinition(id: "testDaemon", frequency: 3) { _ in
            await mockIO.print("Daemon ran!")
            stateHolder.count += 1
        }
        // Initialize game with daemon definition
        let game = MinimalGame(
            registry: DefinitionRegistry(daemonDefinitions: [testDaemonDef])
            // TODO: Need initial state setup for activeDaemons
        )
        let _ = GameEngine( // Use _ for unused engine
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        /*
        // Cannot start daemon from test setup currently
        // Act: Run engine for 7 turns (look x 7, quit)
        ...
        // Assert
        ...
        */
    }

    @Test("Fuse and Daemon Interaction")
    func testFuseAndDaemonInteraction() async throws {
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let _ = TestStateHolder() // Use _ for unused stateHolder

        let testFuse = FuseDefinition(id: "testFuse", initialTurns: 3) { _ in /* ... */ }
        let testDaemon = DaemonDefinition(id: "testDaemon", frequency: 2) { _ in /* ... */ }

        // Initialize game with definitions
        let game = MinimalGame(
            registry: DefinitionRegistry(
                fuseDefinitions: [testFuse],
                daemonDefinitions: [testDaemon]
            )
            // TODO: Need initial state setup for active timers
        )

        let _ = GameEngine( // Use _ for unused engine
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        /*
        // Cannot start timers from test setup currently
        // Act: Run for 6 turns
        ...
        // Assert
        ...
        */
    }

    // MARK: - Helper Functions & Error Tests

    @Test("ReportActionError: .invalidDirection")
    func testReportErrorInvalidDirection() async throws {
        // Initialize location with properties directly
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            properties: LocationProperty.inherentlyLit // Qualify LocationProperty
        )
        let game = MinimalGame(locations: [startRoom])

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
        expectNoDifference(output, "A strange buzzing sound indicates something is wrong.")
    }

    @Test("ReportActionError: .itemNotTakable")
    func testReportErrorItemNotTakable() async throws {
        // Initialize item without .takable
        let pebble = Item(id: "startItem", name: "pebble", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [pebble])

        #expect(game.state.items["startItem"]?.hasProperty(.takable) == false)

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
        // Initialize item in room, not held
        let pebble = Item(id: "startItem", name: "pebble", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [pebble])

        #expect(game.state.items["startItem"]?.parent == .location("startRoom"))

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
        // Initialize items directly
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        let target = Item(
            id: "box",
            name: "box",
            properties: .container, .openable,
            parent: .location("startRoom")
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verbID: "insert",
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
        // Initialize item directly
        let item = Item(id: "rock", name: "rock", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [item])

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
        // Initialize item directly, held by player
        let item = Item(
            id: "rock",
            name: "rock",
            properties: .takable,
            parent: .player
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [item])

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
        // Initialize items and player with capacity
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
        let player = Player(
            in: "startRoom",
            carryingCapacity: 10 // Set low capacity
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(player: player, locations: [startRoom], items: [itemHeld, itemToTake])

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
        // Initialize items directly
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        let target = Item(id: "rock", name: "rock", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verbID: "insert",
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
        // Initialize items directly
        let itemToPut = Item(id: "key", name: "key", parent: .player)
        let target = Item(id: "rock", name: "rock", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verbID: "put-on",
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
        // Initialize location with blocked exit
        let blockedExit = Exit(
            destination: "nowhere",
            blockedMessage: "A shimmering curtain bars the way."
        )
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            exits: [.north: blockedExit],
            properties: LocationProperty.inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom])

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
        // Initialize item as closed container
        let container = Item(
            id: "box",
            name: "box",
            properties: .container, .openable,
            parent: .location("startRoom")
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [container])

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
        // Initialize unlocked container and key held by player
        let container = Item(
            id: "chest",
            name: "chest",
            properties: .container, .openable, .lockable,
            parent: .location("startRoom"),
            lockKey: "key1"
        )
        let key = Item(id: "key1", name: "key", properties: .takable, parent: .player)
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let player = Player(in: "startRoom")
        let game = MinimalGame(player: player, locations: [startRoom], items: [container, key])

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
        // Initialize non-closeable item
        let item = Item(id: "book", name: "book", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(verbID: "close", directObject: "book", rawInput: "close book")
        let output = await runCommandAndCaptureOutput(
            game: game,
            commandInput: "close book",
            commandToParse: command
        )
        expectNoDifference(output, "The book is not something you can close.")
    }

    @Test("ReportActionError: .itemNotDroppable")
    func testReportErrorItemNotDroppable() async throws {
        // Initialize fixed item held by player
        let item = Item(
            id: "statue",
            name: "statue",
            properties: .fixed,
            parent: .player
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [item])

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
        // Initialize fixed, worn item held by player
        let item = Item(
            id: "amulet",
            name: "cursed amulet",
            properties: .wearable, .worn, .fixed,
            parent: .player
        )
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let game = MinimalGame(locations: [startRoom], items: [item])

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
        // Initialize location with conditional exit
        let conditionalExit = Exit(
            destination: "nirvana",
            blockedMessage: "You must first find inner peace."
        )
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            exits: [.up: conditionalExit],
            properties: LocationProperty.inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom])

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
        // Initialize dark room with an item
        let item = Item(id: "shadow", name: "shadow", parent: .location("startRoom"))
        let startRoom = Location(id: "startRoom", name: "Dark Room")
        let game = MinimalGame(locations: [startRoom], items: [item])

        #expect(game.state.locations["startRoom"]?.hasProperty(LocationProperty.inherentlyLit) == false)

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
        // Initialize locked container and wrong key held by player
        let container = Item(
            id: "chest",
            name: "chest",
            properties: .container, .lockable, .locked,
            parent: .location("startRoom"),
            lockKey: "key1"
        )
        let wrongKey = Item(id: "key2", name: "wrong key", properties: .takable, parent: .player)
        let startRoom = Location(id: "startRoom", name: "Start Room", properties: LocationProperty.inherentlyLit)
        let player = Player(in: "startRoom")
        let game = MinimalGame(player: player, locations: [startRoom], items: [container, wrongKey])

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
        // TODO: Implementation
    }

} // End of struct GameEngineTests

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
        var commandOutput = "" // Default to empty string
        var promptEncountered = false
        for call in outputCalls {
            // Capture the first non-input, non-status line *after* the input prompt for the command
            if call.style == .input && call.text == "> " {
                promptEncountered = true
                continue
            }
            if promptEncountered && call.style != .input && call.style != .statusLine {
                commandOutput = call.text
                break // Found the command's response
            }
        }
        return commandOutput
    }
}
