import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("LocationEventHandler Tests")
struct LocationEventHandlerTests {

    // MARK: - Test Data

    private func createTestGame(
        locationEventHandlers: [LocationID: LocationEventHandler] = [:]
    ) -> MinimalGame {
        let startRoom = Location(.startRoom)
            .name("Starting Room")
            .inherentlyLit
            .north("anotherRoom")

        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .description("Another room for testing.")
            .inherentlyLit

        return MinimalGame(
            locations: startRoom, anotherRoom,
            locationEventHandlers: locationEventHandlers
        )
    }

    // MARK: - Initialization Tests

    @Test("LocationEventHandler can be initialized with a handler closure")
    func testInitialization() async throws {
        let handlerCalled = HandlerState()

        let handler = LocationEventHandler { _, _ in
            await handlerCalled.setCalled(true)
            return nil
        }

        // Verify handler was stored (we can't directly access it, but we can test it works)
        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Trigger an event that should call the handler
        try await engine.execute("look")

        // Handler should have been called during the game loop
        let wasCalled = await handlerCalled.wasCalled()
        #expect(wasCalled == true)
    }

    // MARK: - LocationEvent Tests

    @Test("LocationEvent.beforeTurn contains the correct command")
    func testBeforeTurnEvent() async throws {
        let commandCapture = CommandCapture()

        let handler = LocationEventHandler { _, event in
            if case .beforeTurn(let command) = event {
                await commandCapture.setCommand(command)
            }
            return nil
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        let capturedCommand = await commandCapture.getCommand()
        #expect(capturedCommand != nil)
        #expect(capturedCommand?.verb.intents.contains(.examine) == true)
    }

    @Test("LocationEvent.afterTurn contains the correct command")
    func testAfterTurnEvent() async throws {
        let eventCapture = EventCapture()

        let handler = LocationEventHandler { _, event in
            switch event {
            case .beforeTurn:
                await eventCapture.setEventType("before")
            case .afterTurn(let command):
                await eventCapture.setEventType("after")
                await eventCapture.setCommand(command)
            case .onEnter:
                await eventCapture.setEventType("enter")
            }
            return nil
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        // Should have captured both before and after turn events
        let capturedCommand = await eventCapture.getCommand()
        let eventType = await eventCapture.getEventType()
        #expect(capturedCommand != nil)
        #expect(eventType == "after")
        #expect(capturedCommand?.verb.intents.contains(.examine) == true)
    }

    @Test("LocationEvent.onEnter triggers when entering a location")
    func testOnEnterEvent() async throws {
        let enterTrigger = HandlerState()

        let handler = LocationEventHandler { _, event in
            if case .onEnter = event {
                await enterTrigger.setCalled(true)
            }
            return nil
        }

        let game = createTestGame(
            locationEventHandlers: ["anotherRoom": handler]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Move to the room with the handler
        try await engine.execute(
            """
            look
            north
            """
        )
        await mockIO.expectOutput(
            """
            > look
            --- Starting Room ---

            This location is still under construction. The game developers
            apologize for any inconvenience.

            > north
            --- Another Room ---

            Another room for testing.
            """
        )

        let wasTriggered = await enterTrigger.wasCalled()
        #expect(wasTriggered == true)
    }

    @Test("Debug onEnter event - verify movement and handler registration")
    func testOnEnterDebug() async throws {
        let enterTrigger = HandlerState()

        let handler = LocationEventHandler { _, event in
            if case .onEnter = event {
                await enterTrigger.setCalled(true)
            }
            return nil
        }

        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .description("Another room.")
            .inherentlyLit
            .north(.startRoom)
        let game = MinimalGame(
            player: Player(in: "anotherRoom"),
            locations: anotherRoom,
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialLocation = await engine.player.location.id
        #expect(initialLocation == "anotherRoom")

        // Verify blueprint has the handler registered
        let hasHandler = engine.locationEventHandlers[.startRoom] != nil
        #expect(hasHandler == true)

        // Move to the room with the handler
        try await engine.execute("north")

        // Verify movement worked
        let finalLocation = await engine.player.location.id
        #expect(finalLocation == .startRoom)

        // Check if handler was triggered
        let wasTriggered = await enterTrigger.wasCalled()
        #expect(wasTriggered == true)

        // Print debug info if test fails
        let output = await mockIO.flush()
        print("Movement output: \(output)")
    }

    // MARK: - Integration Tests

    @Test("LocationEventHandler can override command behavior before turn")
    func testBeforeTurnOverride() async throws {
        let handler = LocationEventHandler(for: .startRoom) {
            beforeTurn(.examine) { _, _ in
                ActionResult("Custom look behavior!")
            }
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expectOutput(
            """
            > look
            Custom look behavior!
            """
        )
    }

    @Test("LocationEventHandler can run after turn processing")
    func testAfterTurnProcessing() async throws {
        let afterTurnState = HandlerState()

        let handler = LocationEventHandler { _, event in
            if case .afterTurn = event {
                await afterTurnState.setCalled(true)
            }
            return nil
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        let wasCalled = await afterTurnState.wasCalled()
        #expect(wasCalled == true)
    }

    @Test("LocationEventHandler handles onEnter when moving to location")
    func testOnEnterIntegration() async throws {
        let messageCapture = MessageCapture()

        let handler = LocationEventHandler { _, event in
            if case .onEnter = event {
                await messageCapture.addMessage("Entered the test room!")
                return nil  // Don't override the default behavior
            }
            return nil
        }

        let startRoom = Location(.startRoom)
            .name("Test Room")
            .description("A room for testing.")
            .inherentlyLit
            .south("destination")

        let destination = Location("destination")
            .name("Destination Room")
            .description("The destination location.")
            .inherentlyLit
            .north(.startRoom)
        let game = MinimalGame(
            locations: startRoom, destination,
            locationEventHandlers: ["destination": handler]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute(
            """
            look
            south
            """
        )

        let messages = await messageCapture.getMessages()
        expectNoDifference(
            messages,
            [
                "Entered the test room!"
            ])

        await mockIO.expectOutput(
            """
            > look
            --- Test Room ---

            A room for testing.

            > south
            --- Destination Room ---

            The destination location.
            """
        )
    }

    @Test("LocationEventHandler can log errors gracefully")
    func testErrorHandling() async throws {
        let handler = LocationEventHandler { _, _ in
            struct TestError: Error {}
            throw TestError()
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // The error should be caught and logged by the engine
        try await engine.execute("look")

        // Should still get normal look output despite handler error
        await mockIO.expectOutput(
            """
            > look
            --- Starting Room ---

            This location is still under construction. The game developers
            apologize for any inconvenience.
            """
        )
    }

    @Test("Multiple LocationEventHandlers can coexist for different locations")
    func testMultipleHandlers() async throws {
        let room1Events = MessageCapture()
        let room2Events = MessageCapture()

        let handler1 = LocationEventHandler { _, event in
            if case .onEnter = event {
                await room1Events.addMessage("Room 1 entered")
            }
            return nil
        }

        let handler2 = LocationEventHandler { _, event in
            if case .onEnter = event {
                await room2Events.addMessage("Room 2 entered")
            }
            return nil
        }

        let room1 = Location("room1")
            .name("Room 1")
            .description("First room.")
            .inherentlyLit
            .east("room2")

        let room2 = Location("room2")
            .name("Room 2")
            .description("Second room.")
            .inherentlyLit
            .west("room1")

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: room1, room2,
            locationEventHandlers: [
                "room1": handler1,
                "room2": handler2,
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Move from room1 to room2
        try await engine.execute("east")

        // Move back to room1
        try await engine.execute("west")

        let room1Messages = await room1Events.getMessages()
        let room2Messages = await room2Events.getMessages()
        expectNoDifference(
            room1Messages,
            [
                "Room 1 entered"
            ])
        expectNoDifference(
            room2Messages,
            [
                "Room 2 entered"
            ])
    }

    @Test("LocationEventHandler beforeTurn can prevent default action")
    func testBeforeTurnPreventsDefault() async throws {
        let handler = LocationEventHandler(for: .startRoom) {
            beforeTurn(.examine) { _, _ in
                ActionResult("You are not allowed to look here!")
            }
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expectOutput(
            """
            > look
            You are not allowed to look here!
            """
        )
    }

    @Test("LocationEventHandler processes complex multi-intent matching")
    func testMultiIntentMatching() async throws {
        let intentCapture = IntentCapture()

        let handler = LocationEventHandler { _, event in
            if case .beforeTurn(let command) = event {
                for intent in [Intent.take, .drop, .examine] {
                    if command.verb.intents.contains(intent) {
                        await intentCapture.addIntent(intent)
                    }
                }
            }
            return nil
        }

        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            locations: createTestGame().locations[0],
            items: testItem,
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("take test item")

        let matchedIntents = await intentCapture.getIntents()
        #expect(matchedIntents.contains(.take))
    }

    @Test("LocationEventHandler onEnter triggers only when entering, not when already in location")
    func testOnEnterTriggersOnlyOnEntry() async throws {
        let enterCounter = Counter()

        let handler = LocationEventHandler { _, event in
            if case .onEnter = event {
                await enterCounter.increment()
            }
            return nil
        }

        let startRoom = Location(.startRoom)
            .name("Test Room")
            .description("A room for testing.")
            .inherentlyLit
            .south("destinationRoom")

        let destinationRoom = Location("destinationRoom")
            .name("Destination Room")
            .description("Destination location.")
            .inherentlyLit
            .north("startRoom")

        let game = MinimalGame(
            locations: startRoom, destinationRoom,
            locationEventHandlers: ["destinationRoom": handler]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute commands that don't involve entering the test room
        try await engine.execute(
            "look",
            "inventory"
        )

        let countAfterCommands = await enterCounter.value()
        #expect(countAfterCommands == 0)

        // Now enter the test room
        try await engine.execute("south")

        let countAfterEnter = await enterCounter.value()
        #expect(countAfterEnter == 1)

        // Execute more commands while in the test room
        try await engine.execute(
            "look",
            "inventory",
            "north"
        )

        // Should still be 1 - onEnter doesn't trigger for actions within the room
        let finalCount = await enterCounter.value()
        #expect(finalCount == 1)

        await mockIO.expectOutput(
            """
            > look
            --- Test Room ---

            A room for testing.

            > inventory
            Your hands are as empty as your pockets.

            > south
            --- Destination Room ---

            Destination location.

            > look
            --- Destination Room ---

            Destination location.

            > inventory
            You are unburdened by material possessions.

            > north
            --- Test Room ---
            """
        )
    }

    @Test("LocationEventHandler can access and modify game state")
    func testGameStateAccess() async throws {
        let handler = LocationEventHandler { engine, event in
            if case .beforeTurn(let command) = event, command.verb.intents.contains(.examine) {
                // Set a custom flag when player tries to look
                let stateChange = await engine.setFlag(.isVerboseMode)
                return ActionResult(
                    "You sense something mystical about this place...",
                    stateChange
                )
            }
            return nil
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify flag is not set initially
        let initialFlag = await engine.hasFlag(.isVerboseMode)
        #expect(initialFlag == false)

        try await engine.execute("look")

        // Verify flag was set by the handler
        let finalFlag = await engine.hasFlag(.isVerboseMode)
        #expect(finalFlag == true)

        await mockIO.expectOutput(
            """
            > look
            You sense something mystical about this place...
            """
        )
    }

    @Test("LocationEventHandler can be initialized with context-based API")
    func testContextBasedAPI() async throws {
        let messageCapture = MessageCapture()

        let handler = LocationEventHandler(for: .startRoom) {
            beforeTurn(.examine) { context, _ in
                await messageCapture.addMessage(
                    "Context handler called for location: \(context.location.id)")
                return ActionResult("Custom look message from context handler.")
            }
        }

        let game = createTestGame(
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test that the context-based handler works
        try await engine.execute("look")

        let messages = await messageCapture.getMessages()
        expectNoDifference(
            messages,
            [
                "Context handler called for location: .startRoom"
            ])

        await mockIO.expectOutput("""
            > look
            Custom look message from context handler.
            """)
    }

    @Test("LocationEventHandler ActionResult.yield allows normal processing to continue")
    func testYieldFunctionality() async throws {
        let handler = LocationEventHandler(for: .startRoom) {
            // First matcher: yield if room is lit
            beforeTurn { context, _ in
                let isLit = await context.location.hasFlag(.isLit)
                let isInherentlyLit = await context.location.hasFlag(.inherentlyLit)
                if isLit || isInherentlyLit {
                    return ActionResult.yield  // Let normal processing continue
                }
                return nil  // Not handled, try next matcher
            }

            // Second matcher: block movement in dark
            beforeTurn(.move) { _, _ in
                ActionResult("You stumble in the darkness!")
            }

            // Third matcher: block other actions in dark
            beforeTurn { _, _ in
                ActionResult("Too dark to do that!")
            }
        }

        let testRoom = Location(.startRoom)
            .name("Test Room")
            .description("A test room that can be lit or dark.")
            .north("otherRoom")
            // Note: no .inherentlyLit - starts dark

        let otherRoom = Location("otherRoom")
            .name("Other Room")
            .description("Another room.")
            .inherentlyLit
            .south(.startRoom)

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: testRoom, otherRoom,
            locationEventHandlers: [.startRoom: handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test 1: When room is dark, handler should block actions
        try await engine.execute("look")

        await mockIO.expectOutput(
            """
            > look
            Too dark to do that!
            """
        )

        // Test 2: When room is dark, handler should block movement
        try await engine.execute("north")

        await mockIO.expectOutput(
            """
            > north
            You stumble in the darkness!
            """
        )

        // Now test with a lit room by creating a new engine with lit room
        let litTestRoom = Location(.startRoom)
            .name("Test Room")
            .description("A test room that can be lit or dark.")
            .inherentlyLit  // This room starts lit
            .north("otherRoom")

        let litGame = MinimalGame(
            locations: litTestRoom, otherRoom,
            locationEventHandlers: [.startRoom: handler]
        )
        let (litEngine, litMockIO) = await GameEngine.test(blueprint: litGame)

        // Test 3: When room is lit, handler should yield and allow normal processing
        try await litEngine.execute("look")

        let output3 = await litMockIO.flush()
        // Should get normal room description because handler yielded
        #expect(output3.contains("-- Test Room --"))
        #expect(output3.contains("A test room that can be lit or dark."))

        // Test 4: Verify movement works when lit (handler yields)
        try await litEngine.execute("north")

        let output4 = await litMockIO.flush()
        // Should successfully move to other room
        #expect(output4.contains("-- Other Room --"))
        #expect(output4.contains("Another room."))
    }
}

// MARK: - Test Helpers

private actor HandlerState {
    private var called = false

    func setCalled(_ value: Bool) {
        called = value
    }

    func wasCalled() -> Bool {
        called
    }
}

private actor CommandCapture {
    private var command: Command?

    func setCommand(_ cmd: Command) {
        command = cmd
    }

    func getCommand() -> Command? {
        command
    }
}

private actor EventCapture {
    private var eventType: String?
    private var command: Command?

    func setEventType(_ type: String) {
        eventType = type
    }

    func setCommand(_ cmd: Command) {
        command = cmd
    }

    func getEventType() -> String? {
        eventType
    }

    func getCommand() -> Command? {
        command
    }
}

private actor MessageCapture {
    private var messages: [String] = []

    func addMessage(_ message: String) {
        messages.append(message)
    }

    func getMessages() -> [String] {
        messages
    }
}

private actor IntentCapture {
    private var intents: [Intent] = []

    func addIntent(_ intent: Intent) {
        intents.append(intent)
    }

    func getIntents() -> [Intent] {
        intents
    }
}

// MARK: - Counter

private actor Counter {
    private var count = 0

    func increment() {
        count += 1
    }

    func value() -> Int {
        count
    }
}
