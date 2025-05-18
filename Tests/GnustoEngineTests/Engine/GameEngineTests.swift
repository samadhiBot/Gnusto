import CustomDump
import Testing

@testable import GnustoEngine

// Helper class for sharing state with closures in tests
private actor TestStateHolder {
    var flag = false
    var count = 0

    func markFlag() { flag = true }
    func increment() { count += 1 }
    func getFlag() -> Bool { flag }
    func getCount() -> Int { count }
}

struct GameEngineTests {
    @Test("Engine Run Initialization and First Prompt in Dark Room")
    func testEngineRunInitializationInDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
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
            Minimal Game

            Welcome to the Minimal Game!

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

        let engine = await GameEngine(
            blueprint: MinimalGame(),
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
            Minimal Game

            Welcome to the Minimal Game!

            — Void —

            An empty void.

            You can see a pebble here.

            > xyzzy
            I don’t know the verb ‘xyzzy’.

            > quit
            """)

        // Check turn counter was incremented despite error
        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 1, "Turn counter should increment even on parse error")

        // Check change history only contains 1st room visit and move increment
        #expect(await engine.getChangeHistory() == [
            StateChange(
                entityID: .location(.startRoom),
                attributeKey: .locationAttribute(.isVisited),
                newValue: true
            ),
            StateChange(
                entityID: .player,
                attributeKey: .playerMoves,
                oldValue: 0,
                newValue: 1
            ),
        ])
    }

    @Test("Engine Handles Action Error")
    func testEngineHandlesActionResponse() async throws {
        let mockTakeHandler = MockActionHandler(
            errorToThrow: .itemNotTakable("startItem"),
            throwFrom: .process
        )
        // Initialize pebble without .isTakable
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom],
            items: [pebble],
            customActionHandlers: [.take: mockTakeHandler]
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let takeCommand = Command(
            verb: .take,
            directObject: .item("startItem"),
            rawInput: "take pebble"
        )

        // Configure parser to succeed
        mockParser.parseHandler = { input, _, _ in
            if input == "take pebble" { return .success(takeCommand) }
            if input == "quit" { return .failure(.emptyInput) } // Simulate quit needs a verb
            return .failure(.unknownVerb(input))
        }

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Make pebble non-takable in this test's state
        #expect(game.state.items["startItem"]?.attributes[.isTakable] == nil)

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
        let output = await mockIO.flush()
        expectNoDifference(output, """
            Minimal Game

            Welcome to the Minimal Game!

            — Start Room —

            You are in a nondescript location.

            You can see a pebble here.

            > take pebble
            You can’t take the pebble.

            > quit
            """)

        // Verify the handler was called (optional but good practice)
        let processCalled = await mockTakeHandler.getProcessCalled()
        #expect(processCalled == true, "MockActionHandler.process should have been called")
        let commandReceived = await mockTakeHandler.getLastCommandReceived()
        #expect(commandReceived?.verb == "take")
            #expect(commandReceived?.directObject == .item("startItem"))

        // Check turn counter incremented
        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 1, "Turn counter should increment even on action error")

        // Check change history only contains 1st room visit and move increment
        #expect(await engine.getChangeHistory() == [
            StateChange(
                entityID: .location(.startRoom),
                attributeKey: .locationAttribute(.isVisited),
                newValue: true
            ),
            StateChange(
                entityID: .player,
                attributeKey: .playerMoves,
                oldValue: 0,
                newValue: 1
            ),
        ])
    }

    @Test("Engine Processes Successful Command")
    func testEngineProcessesSuccessfulCommand() async throws {
        let mockLookHandler = MockActionHandler()

        // Initialize room with isLit: true
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .in(.location(startRoom.id)), // pebble in room
            .isTakable
        )
        let game = MinimalGame(
            locations: [startRoom],
            items: [pebble],
            customActionHandlers: [.look: mockLookHandler]
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let lookCommand = Command(verb: .look, rawInput: "look")
        let takePebbleCommand = Command(
            verb: .take,
            directObject: .item("startItem"),
            rawInput: "take pebble"
        )

        // Configure parser
        mockParser.parseHandler = { input, _, _ in
            if input == "look" { return .success(lookCommand) }
            if input == "take pebble" { return .success(takePebbleCommand) }
            if input == "quit" { return .failure(.emptyInput) } // Simulate quit needs a verb
            return .failure(.unknownVerb(input))
        }

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        await mockIO.enqueueInput("look", "take pebble", "quit")

        // Act
        await engine.run()

        // Assert IO
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1)

        // Assert handler calls
        let lookProcessCalled = await mockLookHandler.getProcessCalled()
        #expect(lookProcessCalled == true, "Look handler process should have been called")
        // Since take is handled by a default handler (or a mock one if we set it up),
        // we can’t easily check its .processCalled without more setup.

        // Assert game state changes (e.g., pebble is taken)
        let pebbleState = try await engine.item("startItem")
        #expect(pebbleState.parent == .player, "Pebble should be held by player")

        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 2, "Turn counter should be 2 after two successful commands")
    }

    @Test("Engine Processes Multiple Commands")
    func testEngineProcessesMultipleCommands() async throws {
        let mockLookHandler = MockActionHandler()
        let mockTakeHandler = MockActionHandler()

        // Initialize room with isLit: true
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .isTakable
        )
        let game = MinimalGame(
            locations: [startRoom],
            items: [pebble],
            customActionHandlers: [
                .look: mockLookHandler,
                .take: mockTakeHandler
            ]
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        let lookCommand = Command(
            verb: .look,
            rawInput: "look"
        )
        let takePebbleCommand = Command(
            verb: .take,
            directObject: .item("startItem"),
            rawInput: "take pebble"
        )

        // Configure parser for the sequence
        mockParser.parseHandler = { input, _, _ in
            switch input {
            case "look": return .success(lookCommand)
            case "take pebble": return .success(takePebbleCommand)
            case "quit": return .failure(.emptyInput) // Simulate quit needs a verb
            default: return .failure(.unknownVerb(input))
            }
        }

        let engine = await GameEngine(
            blueprint: game,
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
        #expect(lookCommandReceived?.verb == "look")
        let takeCommandReceived = await mockTakeHandler.getLastCommandReceived()
        #expect(takeCommandReceived?.verb == "take")
            #expect(takeCommandReceived?.directObject == .item("startItem"))

        // Check turn counter reflects two successful commands
        let finalMoves = await engine.playerMoves
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
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let quitCommand = Command(verb: .quit, rawInput: "quit")

        // Configure parser
        mockParser.parseHandler = { input, _, _ in
            if input == "quit" { return .success(quitCommand) }
            return .failure(.unknownVerb(input))
        }

        let engine = await GameEngine(
            blueprint: MinimalGame(),
            parser: mockParser,
            ioHandler: mockIO
        )

        await mockIO.enqueueInput("quit")

        // Act: This should not throw and complete normally
        await engine.run()

        // Assert IO
        let setupCount = await mockIO.setupCallCount
        #expect(setupCount == 1)
        let teardownCount = await mockIO.teardownCallCount
        #expect(teardownCount == 1)

        // Ensure game loop exited (e.g., by checking turns or a flag if IO doesn’t stop it)
        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 0, "Quit command should not increment moves if it's the first command and handled cleanly")
    }

    @Test("Engine Handles Nil Input (EOF) Gracefully")
    func testEngineHandlesNilInputGracefully() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
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
            Minimal Game

            Welcome to the Minimal Game!

            — Void —

            An empty void.

            You can see a pebble here.

            >
            Goodbye!
            """)

        // Check status line was shown only for the initial state
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 1)
        #expect(statuses.first?.turns == 0)

        // Verify no commands were processed (turn counter remains 0)
        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 0, "Turn counter should not increment if no input is read")
    }

    @Test("Engine State Persists Between Turns (Take -> Inventory)")
    func testEngineStatePersistsBetweenTurns() async throws {
        let mockInventoryHandler = MockActionHandler()
        // Use default TakeActionHandler to test state persistence

        // Initialize items with correct properties
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .in(.location(.startRoom)),
            .isTakable
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: [startRoom],
            items: [pebble],
            customActionHandlers: [
                // Only mock inventory
                .inventory: mockInventoryHandler,
            ]
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()

        // Configure the MockParser
        let takeCommand = Command(
            verb: .take,
            directObject: .item("startItem"),
            rawInput: "take pebble"
        )
        let inventoryCommand = Command(
            verb: .inventory,
            rawInput: "inventory"
        )
        mockParser.parseHandler = { input, _, _ in
            switch input {
            case "take pebble": return .success(takeCommand)
            case "inventory": return .success(inventoryCommand)
            // Handle quit implicitly via engine.run loop
            default: return .failure(.unknownVerb(input))
            }
        }

        // Ensure pebble is initially takable and in the room (check initial game state)
        #expect(game.state.items["startItem"]?.attributes[.isTakable] == true)
        #expect(game.state.items["startItem"]?.parent == .location(.startRoom))

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.items(in: .player).isEmpty == true)

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
        let finalPebbleSnapshot = try await engine.item("startItem")
        #expect(finalPebbleSnapshot.parent == .player, "Pebble snapshot should show parent as player")

        let finalInventorySnapshots = await engine.items(in: .player)
        #expect(finalInventorySnapshots.contains { $0.id == "startItem" }, "Player inventory snapshots should contain pebble")

        let finalRoomSnapshots = await engine.items(in: .location(.startRoom))
        #expect(finalRoomSnapshots.isEmpty == true, "Start room snapshots should be empty")

        // Check turn counter reflects two successful commands
        let finalMoves = await engine.playerMoves
        #expect(finalMoves == 2, "Turn counter should be 2 after take and inventory commands")

        // Check status lines were updated
        let statuses = await mockIO.recordedStatusLines
        #expect(statuses.count == 3) // Initial + take + inventory
        #expect(statuses[0].turns == 0)
        #expect(statuses[1].turns == 1)
        #expect(statuses[2].turns == 2)

         // Verify output included "Taken."
        let output = await mockIO.flush()
        expectNoDifference(output, """
            Minimal Game

            Welcome to the Minimal Game!

            — Start Room —

            You are in a nondescript location.

            You can see a pebble here.

            > take pebble
            Taken.

            > inventory
            Mock action succeeded.

            > quit
            """)
    }

    @Test("Engine Records State Changes from Enhanced Handler")
    func testEngineRecordsStateChangesFromEnhancedHandler() async throws {
        // Given: An enhanced handler that changes multiple things
        struct MockMultiChangeHandler: ActionHandler {
            let itemIDToModify: ItemID
            let flagToSet: String

            func validate(context: ActionContext) async throws { }

            func process(context: ActionContext) async throws -> ActionResult {
                // Use snapshot for checks
                guard let item = context.stateSnapshot.items[itemIDToModify] else {
                    throw ActionResponse.internalEngineError("Test item missing")
                }

                // Define multiple changes
                let change1 = StateChange(
                    entityID: .item(itemIDToModify),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: item.attributes[.isTouched],
                    newValue: true,
                )

                let change2 = StateChange(
                    entityID: .item(itemIDToModify),
                    attributeKey: .itemAttribute(.isOn),
                    oldValue: item.attributes[.isOn],
                    newValue: true,
                )

                // Get old flag value from snapshot using GlobalID and engine helper
                let flagID = GlobalID(rawValue: flagToSet)
                // Use the engine context to check the flag state before the change
                let actualOldFlagValue = await context.engine.isFlagSet(flagID)
                let flagOldValueState: StateValue? = actualOldFlagValue ? true : nil // Simpler conversion

                let change3 = StateChange(
                    entityID: .global,
                    attributeKey: .setFlag(flagID),
                    oldValue: flagOldValueState,
                    newValue: true,
                )

                return ActionResult(
                    message: "Multiple changes applied.",
                    stateChanges: [change1, change2, change3]
                )
            }

            // Add empty postProcess for conformance
            func postProcess(context: ActionContext, result: ActionResult) async throws { }
        }

        let testItemID: ItemID = "lamp"
        let testFlagKey: GlobalID = "lampLit" // Use GlobalID type
        let lamp = Item(
            id: testItemID,
            .name("brass lamp"),
            .description("A small brass lamp."),
            .isLightSource,
            .in(.location(.startRoom))
        )
        let mockEnhancedHandler = MockMultiChangeHandler(
            itemIDToModify: testItemID,
            flagToSet: testFlagKey.rawValue
        ) // Pass rawValue if handler needs string
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom],
            items: [lamp],
            // Use customActionHandlers directly with the ActionHandler
            customActionHandlers: [
                "activate": mockEnhancedHandler // No bridge needed
            ]
        )

        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let activateCommand = Command(
            verb: "activate",
            directObject: .item(testItemID),
            rawInput: "activate lamp"
        )

        mockParser.parseHandler = { input, _, _ in
            if input == "activate lamp" { return .success(activateCommand) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Ensure initial state
        #expect(await engine.isFlagSet(testFlagKey) == false)
        #expect(try await engine.item(testItemID).attributes[.isOn] == nil)
        #expect(try await engine.item(testItemID).attributes[.isTouched] == nil)
        #expect(await engine.getChangeHistory().isEmpty)

        // Act
        await mockIO.enqueueInput("activate lamp", "quit")
        await engine.run()

        // Then
        // Check final state
        #expect(await engine.isFlagSet(testFlagKey), "Flag should be set")
        #expect(
            try await engine.item(testItemID).attributes[.isOn] == true,
            "Item .on property should be set"
        )
        #expect(
            try await engine.item(testItemID).attributes[.isTouched] == true,
            "Item .touched property should be set"
        )

        // Check history recorded correctly
        let history = await engine.getChangeHistory()
        #expect(!history.isEmpty, "Change history should not be empty")

        // Check for Player moves increment change
        #expect(
            history.contains { change in
                change.attributeKey == AttributeKey.playerMoves &&
                change.newValue == StateValue.int(1)
            },
            "History should contain playerMoves increment to 1"
        )

        // Check for Item property change (touched + on)
        #expect(
            history.contains { change in
                guard change.entityID == .item(testItemID),
                      case .itemAttribute(let prop) = change.attributeKey,
                      change.newValue == true else { return false }
                return prop == .isTouched || prop == .isOn
            },
            "History should contain item property change adding .on and .touched"
        )

        // Check for Flag change
        #expect(
            history.contains { change in
                change.entityID == .global &&
                    change.attributeKey == AttributeKey.setFlag(testFlagKey) &&
                    change.newValue == true
            },
            "History should contain flag change to true for \(testFlagKey)"
        )

        // Optionally, still check count if exact number is important
        #expect(
            history.count == 5,
            "Expected exactly 5 changes: 1st room visited + moves + item props + flag"
        )

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            Minimal Game

            Welcome to the Minimal Game!

            — Start Room —

            You are in a nondescript location.

            You can see a brass lamp here.

            > activate lamp
            Multiple changes applied.

            > quit
            """)
    }

    // MARK: - Fuse & Daemon Tests

    // TODO: These timer tests need to be updated once initializing active timers is possible.
    //       Currently commenting out the core logic.

    @Test("Fuse executes after correct number of turns")
    func testFuseExecution() async throws {
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let stateHolder = TestStateHolder()
        let fuseDef = FuseDefinition(id: "testFuse", initialTurns: 2) { gameEngineParameter in
            // This closure is @Sendable and runs on the GameEngine actor context.
            // It captures 'mockIO' (@MainActor) and 'stateHolder' (actor).

            // To call mockIO.print (MainActor) from GameEngine actor context:
            await mockIO.print("Fuse triggered!")

            // To call stateHolder.markFlag (TestStateHolder actor)
            await stateHolder.markFlag()
        }

        // Initialize game with fuse definition
        let game = MinimalGame(
            timeRegistry: TimeRegistry(fuseDefinitions: [fuseDef])
            // TODO: Need initial state setup for activeFuses
        )

        let _ = await GameEngine( // Use _ for unused engine
            blueprint: game,
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

        let testDaemonDef = DaemonDefinition(id: "testDaemon", frequency: 3) { gameEngineParameter in
            // This closure is @Sendable and runs on the GameEngine actor context.
            await mockIO.print("Daemon ran!")
            await stateHolder.increment()
        }
        // Initialize game with daemon definition
        let game = MinimalGame(
            timeRegistry: TimeRegistry(daemonDefinitions: [testDaemonDef])
            // TODO: Need initial state setup for activeDaemons
        )
        let _ = await GameEngine( // Use _ for unused engine
            blueprint: game,
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
        let stateHolder = TestStateHolder()

        let testFuse = FuseDefinition(id: "testFuse", initialTurns: 3) { _ in
            await mockIO.print("Fuse! [\(stateHolder.getFlag())]")
            await stateHolder.markFlag()
        }
        let testDaemon = DaemonDefinition(id: "testDaemon", frequency: 2) { _ in
            await mockIO.print("Daemon! [\(stateHolder.getCount())]")
            await stateHolder.increment()
        }

        // Initialize game with definitions
        let game = MinimalGame(
            timeRegistry: TimeRegistry(
                fuseDefinitions: [testFuse],
                daemonDefinitions: [testDaemon]
            )
            // TODO: Need initial state setup for active timers
        )

        let _ = await GameEngine( // Use _ for unused engine
            blueprint: game,
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

    @Test("ReportActionResponse: .invalidDirection")
    func testReportErrorInvalidDirection() async throws {
        // Initialize location with properties directly
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom])

        let command = Command(
            verb: .go,
            preposition: "xyzzy",
            rawInput: "go xyzzy"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "go xyzzy",
            commandToParse: command
        )
        expectNoDifference(output, "Go where?")
    }

    @Test("ReportActionResponse: .itemNotTakable")
    func testReportErrorItemNotTakable() async throws {
        // Initialize item without .takable
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [pebble])

        #expect(game.state.items["startItem"]?.attributes[.isTakable] == nil)

        let command = Command(
            verb: .take,
            directObject: .item("startItem"),
            rawInput: "take pebble"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "take pebble",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t take the pebble.")
    }

    @Test("ReportActionResponse: .itemNotHeld")
    func testReportErrorItemNotHeld() async throws {
        // Initialize item in room, not held
        let pebble = Item(
            id: "startItem",
            .name("pebble"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [pebble])

        #expect(game.state.items["startItem"]?.parent == .location(.startRoom))

        let command = Command(
            verb: .wear,
            directObject: .item("startItem"),
            rawInput: "wear pebble"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "wear pebble",
            commandToParse: command
        )
        expectNoDifference(output, "You aren’t holding the pebble.")
    }

    @Test("ReportActionResponse: .containerIsClosed")
    func testReportErrorContainerIsClosed() async throws {
        // Initialize items directly
        let itemToPut = Item(
            id: "key",
            .name("key"),
            .in(.player)
        )
        let target = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verb: .insert,
            directObject: .item("key"),
            indirectObject: .item("box"),
            preposition: "in",
            rawInput: "put key in box"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "put key in box",
            commandToParse: command
        )
        expectNoDifference(output, "The box is closed.")
    }

    @Test("ReportActionResponse: .itemNotOpenable")
    func testReportErrorItemNotOpenable() async throws {
        // Initialize item directly
        let item = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(
            verb: .open,
            directObject: .item("rock"),
            rawInput: "open rock"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "open rock",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t open the rock.")
    }

    @Test("ReportActionResponse: .itemNotWearable")
    func testReportErrorItemNotWearable() async throws {
        // Initialize item directly, held by player
        let item = Item(
            id: "rock",
            .name("rock"),
            .in(.player),
            .isTakable
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(
            verb: .wear,
            directObject: .item("rock"),
            rawInput: "wear rock"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "wear rock",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t wear the rock.")
    }

    @Test("ReportActionResponse: .playerCannotCarryMore")
    func testReportErrorPlayerCannotCarryMore() async throws {
        // Initialize items and player with capacity
        let itemHeld = Item(
            id: "sword",
            .name("sword"),
            .in(.player),
            .isTakable,
            .size(8)
        )
        let itemToTake = Item(
            id: "shield",
            .name("shield"),
            .in(.location(.startRoom)),
            .isTakable,
            .size(7)
        )
        let player = Player(
            in: .startRoom,
            carryingCapacity: 10 // Set low capacity
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(player: player, locations: [startRoom], items: [itemHeld, itemToTake])

        let command = Command(
            verb: .take,
            directObject: .item("shield"),
            rawInput: "take shield"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "take shield",
            commandToParse: command
        )
        expectNoDifference(output, "Your hands are full.")
    }

    @Test("ReportActionResponse: .targetIsNotAContainer")
    func testReportErrorTargetIsNotContainer() async throws {
        // Initialize items directly
        let itemToPut = Item(
            id: "key",
            .name("key"),
            .in(.player)
        )
        let target = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verb: .insert,
            directObject: .item("key"),
            indirectObject: .item("rock"),
            preposition: "in",
            rawInput: "put key in rock"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "put key in rock",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t put things in the rock.")
    }

    @Test("ReportActionResponse: .targetIsNotASurface")
    func testReportErrorTargetIsNotSurface() async throws {
        // Initialize items directly
        let itemToPut = Item(
            id: "key",
            .name("key"),
            .in(.player)
        )
        let target = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [itemToPut, target])

        let command = Command(
            verb: .putOn,
            directObject: .item("key"),
            indirectObject: .item("rock"),
            preposition: "on",
            rawInput: "put key on rock"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "put key on rock",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t put things on the rock.")
    }

    @Test("ReportActionResponse: .directionIsBlocked")
    func testReportErrorDirectionIsBlocked() async throws {
        // Initialize location with blocked exit
        let blockedExit = Exit(
            destination: "nowhere",
            blockedMessage: "A shimmering curtain bars the way."
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .exits([.north: blockedExit]),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom])

        let command = Command(
            verb: .go,
            directObject: .item("north"),
            direction: .north,
            rawInput: "go north"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "go north",
            commandToParse: command
        )
        expectNoDifference(output, "A shimmering curtain bars the way.")
    }

    @Test("ReportActionResponse: .itemAlreadyClosed")
    func testReportErrorItemAlreadyClosed() async throws {
        // Initialize item as closed container
        let container = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [container])

        let command = Command(
            verb: .close,
            directObject: .item(container.id),
            rawInput: "close box"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "close box",
            commandToParse: command
        )
        expectNoDifference(output, "The box is already closed.")
    }

    @Test("ReportActionResponse: .itemIsUnlocked")
    func testReportErrorItemIsUnlocked() async throws {
        // Initialize unlocked container and key held by player
        let container = Item(
            id: "chest",
            .name("chest"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isLockable,
            .lockKey("key1")
        )
        let key = Item(
            id: "key1",
            .name("key"),
            .in(.player),
            .isTakable
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let player = Player(in: .startRoom)
        let game = MinimalGame(player: player, locations: [startRoom], items: [container, key])

        let command = Command(
            verb: .unlock,
            directObject: .item(container.id),
            indirectObject: .item(key.id),
            preposition: "with",
            rawInput: "unlock chest with key"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "unlock chest with key",
            commandToParse: command
        )
        expectNoDifference(output, "The chest is already unlocked.")
    }

    @Test("ReportActionResponse: .itemNotClosable")
    func testReportErrorItemNotCloseable() async throws {
        // Initialize non-closeable item
        let item = Item(
            id: "book",
            .name("book"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(
            verb: .close,
            directObject: .item(item.id),
            rawInput: "close book"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "close book",
            commandToParse: command
        )
        expectNoDifference(output, "The book is not something you can close.")
    }

    @Test("ReportActionResponse: .itemNotDroppable")
    func testReportErrorItemNotDroppable() async throws {
        // Initialize fixed scenery item held by player
        let item = Item(
            id: "statue",
            .name("statue"),
            .in(.player),
            .isScenery
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(
            verb: .drop,
            directObject: .item(item.id),
            rawInput: "drop statue"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "drop statue",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t drop the statue.")
    }

    @Test("ReportActionResponse: .itemNotRemovable")
    func testReportErrorItemNotRemovable() async throws {
        // Initialize fixed scenery, worn item held by player
        let item = Item(
            id: "amulet",
            .name("cursed amulet"),
            .in(.player),
            .isWearable,
            .isWorn,
            .isScenery
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom], items: [item])

        let command = Command(
            verb: .remove,
            directObject: .item(item.id),
            rawInput: "remove amulet"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "remove amulet",
            commandToParse: command
        )
        expectNoDifference(output, "You can’t remove the cursed amulet.")
    }

    @Test("ReportActionResponse: .prerequisiteNotMet")
    func testReportErrorPrerequisiteNotMet() async throws {
        // Initialize location with conditional exit
        let conditionalExit = Exit(
            destination: "nirvana",
            blockedMessage: "You must first find inner peace."
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .exits([.up: conditionalExit]),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [startRoom])

        let command = Command(
            verb: .go,
            directObject: .item("up"),
            direction: .up,
            rawInput: "go up"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "go up",
            commandToParse: command
        )
        expectNoDifference(output, "You must first find inner peace.")
    }

    @Test("ReportActionResponse: .roomIsDark")
    func testReportErrorRoomIsDark() async throws {
        // Initialize dark room with an item
        let item = Item(
            id: "shadow",
            .name("shadow"),
            .in(.location(.startRoom))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Dark Room"),
            .description("A dark, dark room.")
        )
        let game = MinimalGame(
            locations: [startRoom],
            items: [item]
        )

        #expect(
            game.state.locations[.startRoom]?.hasFlag(.inherentlyLit) == false
        )

        let command = Command(
            verb: .examine,
            directObject: .item(item.id),
            rawInput: "examine shadow"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "examine shadow",
            commandToParse: command
        )
        expectNoDifference(output, "It’s too dark to do that.")
    }

    @Test("ReportActionResponse: .wrongKey")
    func testReportErrorWrongKey() async throws {
        // Initialize locked container and wrong key held by player
        let container = Item(
            id: "chest",
            .name("chest"),
            .in(.location(.startRoom)),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key1")
        )
        let wrongKey = Item(
            id: "key2",
            .name("wrong key"),
            .in(.player),
            .isTakable
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let player = Player(in: .startRoom)
        let game = MinimalGame(player: player, locations: [startRoom], items: [container, wrongKey])

        let command = Command(
            verb: .unlock,
            directObject: .item(container.id),
            indirectObject: .item(wrongKey.id),
            preposition: "with",
            rawInput: "unlock chest with key2"
        )
        let output = try await runCommandAndCaptureOutput(
            blueprint: game,
            commandInput: "unlock chest with key2",
            commandToParse: command
        )
        expectNoDifference(output, "The wrong key doesn’t fit the chest.")
    }

    @Test("Apply Action Result - Success")
    func testApplyActionResult_Success() async throws {
        // Define ItemID and initial item state
        let itemID: ItemID = "lamp"
        let lamp = Item(
            id: itemID,
            .name("brass lamp"),
            .description("A small brass lamp."),
            .isLightSource,
            .in(.location(.startRoom))
        )

        // Define the desired state changes
        let turnOnChanges = [
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isOn),
                oldValue: false,
                newValue: true,
            ),
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: nil, // Assuming not touched initially
                newValue: true,
            )
        ]

        // Define the ActionResult to be returned by the mock handler
        let resultToTest = ActionResult(
            message: "Lamp turned on!",
            stateChanges: turnOnChanges
        )

        // Create a mock handler that returns the ActionResult
        struct MockResultHandler: ActionHandler {
            let result: ActionResult
            func validate(context: ActionContext) async throws { /* No validation needed */ }
            func process(context: ActionContext) async throws -> ActionResult { result }
            func postProcess(context: ActionContext, result: ActionResult) async throws { /* No post-processing needed */ }
        }

        let testVerb: VerbID = "testapply"
        let mockHandler = MockResultHandler(result: resultToTest)

        // Setup game with the mock handler
        let game = MinimalGame(
            items: [lamp],
            customActionHandlers: [testVerb: mockHandler]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        // Create the command to trigger the mock handler
        let testCommand = Command(verb: testVerb, rawInput: "testapply")

        // Act: Execute the command
        await engine.execute(command: testCommand)

        // Assert:
        // Verify the state changes were applied
        let finalLamp = try await engine.item(itemID)
        #expect(finalLamp.attributes[.isOn] == true, "Lamp should be ON")
        #expect(finalLamp.attributes[.isTouched] == true, "Lamp should be TOUCHED")

        // Verify the message was printed
        let output = await mockIO.flush()
        expectNoDifference(output, "Lamp turned on!")
    }

    @Test("applyPronounChange updates game state correctly")
    func testApplyPronounChange_Success() async throws {
        let engine = await GameEngine(blueprint: MinimalGame(), parser: MockParser(), ioHandler: await MockIOHandler())
        let itemID: ItemID = "testItem"

        await engine.applyPronounChange(pronoun: "it", itemID: itemID)

        let pronouns = await engine.gameState.pronouns
        #expect(pronouns["it"] == [.item(itemID)])

        // Check change history
        let history = await engine.gameState.changeHistory
        expectNoDifference(history, [
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(itemID)])
            )
        ])
    }

    // Test for GameEngine.updatePronouns
    @Test("updatePronouns updates game state correctly for single item")
    func testUpdatePronounsSingle() async throws {
        let item = Item(
            id: "testItem",
            .name("Test Item")
        )
        let engine = await GameEngine(
            blueprint: MinimalGame(items: [item]),
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let stateChange = await engine.updatePronouns(to: item)
        #expect(
            stateChange == StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(item.id)])
            )
        )
    }

    @Test("updatePronouns updates game state correctly for multiple items (them)")
    func testUpdatePronounsMultiple() async throws {
        let item1 = Item(id: "item1", .name("Item One"))
        let item2 = Item(id: "item2", .name("Item Two"))
        let engine = await GameEngine(
            blueprint: MinimalGame(items: [item1, item2]),
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let change = await engine.updatePronouns(to: item1, item2)
        #expect(
            change == StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "them"),
                newValue: .entityReferenceSet([.item(item1.id), .item(item2.id)])
            )
        )
    }
}

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
        blueprint: GameBlueprint,
        commandInput: String,
        commandToParse: Command
    ) async throws -> String {
        var mockParser = MockParser()
        let mockIO = await MockIOHandler()

        mockParser.parseHandler = { input, _, _ in
            if input == commandInput { return .success(commandToParse) }
            if input == "quit" { return .failure(.emptyInput) }
            return .failure(.unknownVerb(input))
        }

        let engine = await GameEngine(
            blueprint: blueprint,
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
        return commandOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
