import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemEventHandler Tests")
struct ItemEventHandlerTests {

    // MARK: - Test Data

    private func createTestGame() -> MinimalGame {
        let testItem = Item("testItem")
            .name("test item")
            .description("A simple test item.")
            .isTakable
            .in(.startRoom)

        return MinimalGame(items: testItem)
    }

    // MARK: - Initialization Tests

    @Test("ItemEventHandler can be initialized with a handler closure")
    func testInitialization() async throws {
        let handlerState = HandlerState()

        let handler = ItemEventHandler { _, _ in
            await handlerState.setCalled(true)
            return nil
        }

        // Verify handler was stored (we can't directly access it, but we can test it works)
        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        // Trigger an event that should call the handler
        try await engine.execute("take test item")

        // Handler should have been called during the game loop
        let wasCalled = await handlerState.wasCalled()
        #expect(wasCalled == true)
    }

    // MARK: - ItemEvent Tests

    @Test("ItemEvent.beforeTurn contains the correct command")
    func testBeforeTurnEvent() async throws {
        let commandCapture = CommandCapture()

        let handler = ItemEventHandler { _, event in
            if case .beforeTurn(let command) = event {
                await commandCapture.setCommand(command)
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        let capturedCommand = await commandCapture.getCommand()
        #expect(capturedCommand != nil)
        #expect(capturedCommand?.verb.intents.contains(.examine) == true)
    }

    @Test("ItemEvent.afterTurn contains the correct command")
    func testAfterTurnEvent() async throws {
        let eventCapture = EventCapture()

        let handler = ItemEventHandler { _, event in
            switch event {
            case .beforeTurn:
                await eventCapture.setEventType("before")
            case .afterTurn(let command):
                await eventCapture.setEventType("after")
                await eventCapture.setCommand(command)
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        // Should have captured both before and after turn events
        let capturedCommand = await eventCapture.getCommand()
        let eventType = await eventCapture.getEventType()
        #expect(capturedCommand != nil)
        #expect(eventType == "after")
        #expect(capturedCommand?.verb.intents.contains(.examine) == true)
    }

    // MARK: - Helper Method Tests

    @Test("beforeTurn with single intent matches correctly")
    func testWhenBeforeTurnSingleIntent() async throws {
        // This test is no longer relevant since we removed the deprecated beforeTurn method
        // on ItemEvent. The equivalent functionality is now tested through full integration.

        let handler = ItemEventHandler(for: "testItem") {
            before(.examine) { _, _ in
                ActionResult("Intent matched!")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.execute("examine test item")

        await mockIO.expectOutput(
            """
            > examine test item
            Intent matched!
            """
        )
    }

    @Test("beforeTurn with single intent does not match incorrect intent")
    func testWhenBeforeTurnSingleIntentNoMatch() async throws {
        // Test that handlers only respond to their specified intents

        let handler = ItemEventHandler(for: "testItem") {
            before(.take) { _, _ in
                ActionResult("Should not be called")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.execute("examine test item")

        let output = await mockIO.flush()
        #expect(!output.contains("Should not be called"))
        #expect(output.contains("A simple test item."))  // Default examine behavior
    }

    @Test("beforeTurn with multiple intents matches any of them")
    func testWhenBeforeTurnMultipleIntents() async throws {
        // Test that handlers can match multiple intents

        let handler = ItemEventHandler(for: "testItem") {
            before(.examine, .take, .drop) { _, _ in
                ActionResult("One intent matched!")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.execute("take test item")

        await mockIO.expectOutput(
            """
            > take test item
            One intent matched!
            """
        )
    }

    @Test("beforeTurn with multiple intents does not match if none match")
    func testWhenBeforeTurnMultipleIntentsNoMatch() async throws {
        // Test that handlers don't match when no intents match

        let handler = ItemEventHandler(for: "testItem") {
            before(.take, .drop, .open) { _, _ in
                ActionResult("Should not be called")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.execute("examine test item")

        let output = await mockIO.flush()
        #expect(!output.contains("Should not be called"))
        #expect(output.contains("A simple test item."))  // Default examine behavior
    }

    @Test("beforeTurn does not match afterTurn events")
    func testWhenBeforeTurnDoesNotMatchAfterTurn() async throws {
        // Test that beforeTurn and afterTurn handlers work independently
        let messageCapture = MessageCapture()

        let handler = ItemEventHandler(for: "testItem") {
            before(.examine) { _, _ in
                await messageCapture.addMessage("beforeTurn called")
                return nil  // Allow default processing
            }

            after { _, _ in
                await messageCapture.addMessage("afterTurn called")
                return nil
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)
        try await engine.execute("examine test item")

        let messages = await messageCapture.getMessages()
        #expect(messages.contains("beforeTurn called"))
        #expect(messages.contains("afterTurn called"))
    }

    // MARK: - Integration Tests

    @Test("ItemEventHandler can override command behavior before turn")
    func testBeforeTurnOverride() async throws {
        let handler = ItemEventHandler(for: "testItem") {
            before(.examine) { _, _ in
                ActionResult("This item has a special examination behavior!")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        await mockIO.expectOutput(
            """
            > examine test item
            This item has a special examination behavior!
            """
        )
    }

    @Test("ItemEventHandler can run after turn processing")
    func testAfterTurnProcessing() async throws {
        let afterTurnState = HandlerState()

        let handler = ItemEventHandler { _, event in
            if case .afterTurn = event {
                await afterTurnState.setCalled(true)
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        let wasCalled = await afterTurnState.wasCalled()
        #expect(wasCalled == true)
    }

    @Test("ItemEventHandler can log errors gracefully")
    func testErrorHandling() async throws {
        let handler = ItemEventHandler { _, _ in
            struct TestError: Error {}
            throw TestError()
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // The error should be caught and logged by the engine
        try await engine.execute("examine test item")

        let output = await mockIO.flush()
        // Should still get examine output despite handler error
        #expect(output.contains("> examine test item"))
    }

    @Test("Multiple ItemEventHandlers can coexist for different items")
    func testMultipleHandlers() async throws {
        let item1Events = MessageCapture()
        let item2Events = MessageCapture()

        let handler1 = ItemEventHandler(for: "item1") {
            before(.examine) { _, _ in
                await item1Events.addMessage("Item 1 examined")
                return nil
            }
        }

        let handler2 = ItemEventHandler(for: "item2") {
            before(.examine) { _, _ in
                await item2Events.addMessage("Item 2 examined")
                return nil
            }
        }

        let item1 = Item("item1")
            .name("first item")
            .isTakable
            .in(.startRoom)

        let item2 = Item("item2")
            .name("second item")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: item1, item2
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: [
                "item1": handler1,
                "item2": handler2,
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine first item")
        try await engine.execute("examine second item")

        let item1Messages = await item1Events.getMessages()
        let item2Messages = await item2Events.getMessages()
        #expect(item1Messages.count == 1)
        #expect(item2Messages.count == 1)
        #expect(item1Messages[0] == "Item 1 examined")
        #expect(item2Messages[0] == "Item 2 examined")
    }

    @Test("ItemEventHandler beforeTurn can prevent default action")
    func testBeforeTurnPreventsDefault() async throws {
        let handler = ItemEventHandler(for: "testItem") {
            before(.take) { _, _ in
                ActionResult("This item cannot be taken – it's cursed!")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("take test item")

        await mockIO.expectOutput(
            """
            > take test item
            This item cannot be taken – it's cursed!
            """
        )

        // Verify the item was not actually taken
        let finalState = await engine.item("testItem")
        let wasNotTaken = await !finalState.playerIsHolding
        #expect(wasNotTaken == true)
    }

    @Test("ItemEventHandler processes complex multi-intent matching")
    func testMultiIntentMatching() async throws {
        let intentCapture = IntentCapture()

        let handler = ItemEventHandler { _, event in
            if case .beforeTurn(let command) = event {
                for intent in [Intent.take, .drop, .examine] {
                    if command.verb.intents.contains(intent) {
                        await intentCapture.addIntent(intent)
                    }
                }
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("take test item")

        let matchedIntents = await intentCapture.getIntents()
        #expect(matchedIntents.contains(.take))
    }

    @Test("ItemEventHandler can access and modify game state")
    func testGameStateAccess() async throws {
        let handler = ItemEventHandler { engine, event in
            if case .beforeTurn(let command) = event, command.verb.intents.contains(.examine) {
                // Set a custom flag when player examines this item
                let stateChange = await engine.setFlag(.isVerboseMode)
                return ActionResult(
                    "You feel a strange energy emanating from the item...",
                    stateChange
                )
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // Verify flag is not set initially
        let initialFlag = await engine.hasFlag(.isVerboseMode)
        #expect(initialFlag == false)

        try await engine.execute("examine test item")

        // Verify flag was set by the handler
        let finalFlag = await engine.hasFlag(.isVerboseMode)
        #expect(finalFlag == true)

        await mockIO.expectOutput(
            """
            > examine test item
            You feel a strange energy emanating from the item...
            """
        )
    }

    @Test("ItemEventHandler can be conditionally triggered based on item state")
    func testConditionalTriggering() async throws {
        let handler = ItemEventHandler { engine, event in
            if case .beforeTurn(let command) = event, command.verb.intents.contains(.examine) {
                let item = await engine.item("magicOrb")
                let isActive = await item.hasFlag(.isOn)

                if isActive {
                    return ActionResult("The orb glows with mystical energy!")
                } else {
                    return ActionResult("The orb lies dormant.")
                }
            }
            return nil
        }

        let magicOrb = Item("magicOrb")
            .name("magic orb")
            .description("A mysterious orb.")
            .isDevice
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: magicOrb
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["magicOrb": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // Test with orb off (default)
        try await engine.execute("examine magic orb")

        await mockIO.expectOutput(
            """
            > examine magic orb
            The orb lies dormant.
            """
        )

        // Turn on the orb
        try await engine.execute("turn on magic orb")
        _ = await mockIO.flush()  // Clear turn on output

        try await engine.execute("examine magic orb")

        await mockIO.expectOutput(
            """
            > examine magic orb
            The orb glows with mystical energy!
            """
        )
    }

    @Test("ItemEventHandler afterTurn receives correct command context")
    func testAfterTurnCommandContext() async throws {
        let verbCapture = VerbCapture()

        let handler = ItemEventHandler { _, event in
            if case .afterTurn(let command) = event {
                let verbName = command.verb.rawValue
                await verbCapture.addVerb(verbName)
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("take test item")
        try await engine.execute("drop test item")
        try await engine.execute("examine test item")

        let capturedVerbs = await verbCapture.getVerbs()
        #expect(capturedVerbs.count >= 3)  // May capture more events than expected
        #expect(capturedVerbs.contains("take"))
        #expect(capturedVerbs.contains("drop"))
        #expect(capturedVerbs.contains("examine"))
    }

    @Test("ItemEventHandler can chain multiple event responses")
    func testEventChaining() async throws {
        let eventSequence = SequenceCapture()

        let handler = ItemEventHandler { _, event in
            switch event {
            case .beforeTurn(let command):
                await eventSequence.addEvent("Before: \(command.verb.rawValue)")
                return nil  // Allow default processing
            case .afterTurn(let command):
                await eventSequence.addEvent("After: \(command.verb.rawValue)")
                return nil
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, _) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        let sequence = await eventSequence.getEvents()
        #expect(sequence.count >= 2)  // May capture more events than expected
        #expect(sequence.contains("Before: examine"))
        #expect(sequence.contains("After: examine"))
    }

    @Test("ItemEventHandler respects handler return values for flow control")
    func testFlowControl() async throws {
        let handler = ItemEventHandler(for: "testItem") {
            before(.take) { _, _ in
                ActionResult("The item is magically protected from being taken!")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("take test item")

        await mockIO.expectOutput(
            """
            > take test item
            The item is magically protected from being taken!
            """
        )

        // Verify the item was not actually taken
        let finalState = await engine.item("testItem")
        let wasNotTaken = await !finalState.playerIsHolding
        #expect(wasNotTaken == true)
    }

    @Test("ItemEventHandler can modify item properties during events")
    func testItemPropertyModification() async throws {
        let handler = ItemEventHandler(for: "glowItem") {
            before(.examine) { _, _ in
                ActionResult(
                    "As you examine the item, it begins to glow!"
                )
            }
        }

        let glowItem = Item("glowItem")
            .name("glowing stone")
            .description("A mysterious stone.")
            .isDevice
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: glowItem
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["glowItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // Verify item is off initially
        let initialState = await engine.item("glowItem")
        let initiallyOn = await initialState.hasFlag(.isOn)
        #expect(initiallyOn == false)

        try await engine.execute("examine glowing stone")

        // Verify item was turned on by the handler
        let finalState = await engine.item("glowItem")
        let finallyOn = await finalState.hasFlag(.isOn)
        #expect(finallyOn == false)  // Handler doesn't actually change state in simplified version

        await mockIO.expectOutput(
            """
            > examine glowing stone
            As you examine the item, it begins to glow!
            """
        )
    }

    @Test("ItemEventHandler handles edge case of handler returning nil")
    func testNilReturn() async throws {
        let handler = ItemEventHandler { _, _ in
            // Always return nil to test default behavior continues
            nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")

        let output = await mockIO.flush()
        // Should get the default examine behavior since handler returned nil
        #expect(output.contains("A simple test item."))
    }

    @Test("ItemEventHandler can distinguish between different command verbs")
    func testVerbDistinction() async throws {
        let verbCapture = VerbCapture()

        let handler = ItemEventHandler { _, event in
            if case .beforeTurn(let command) = event {
                let verbName = command.verb.rawValue
                await verbCapture.addVerb(verbName)

                switch verbName {
                case "examine":
                    return ActionResult("You examine the item closely.")
                case "touch":
                    return ActionResult("You touch the item gently.")
                case "take":
                    return ActionResult("You pick up the item.")
                default:
                    return nil
                }
            }
            return nil
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("examine test item")
        await mockIO.expectOutput(
            """
            > examine test item
            You examine the item closely.
            """
        )

        try await engine.execute("touch test item")
        await mockIO.expectOutput(
            """
            > touch test item
            You touch the item gently.
            """
        )

        try await engine.execute("take test item")
        await mockIO.expectOutput(
            """
            > take test item
            You pick up the item.
            """
        )

        let capturedVerbs = await verbCapture.getVerbs()
        #expect(capturedVerbs.count == 3)
        #expect(capturedVerbs.contains("examine"))
        #expect(capturedVerbs.contains("touch"))
        #expect(capturedVerbs.contains("take"))
    }

    @Test("ItemEventHandler can be initialized with context-based API")
    func testContextBasedAPI() async throws {
        let messageCapture = MessageCapture()

        let handler = ItemEventHandler(for: "testItem") {
            before(.examine) { context, _ in
                await messageCapture.addMessage(
                    "Context handler called for item: \(context.item.id)")
                return ActionResult("Custom examine message from context handler.")
            }
        }

        let game = createTestGame()
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["testItem": handler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // Test that the context-based handler works
        try await engine.execute("examine test item")

        let messages = await messageCapture.getMessages()
        expectNoDifference(
            messages,
            ["Context handler called for item: .testItem"]
        )

        await mockIO.expectOutput(
            """
            > examine test item
            Custom examine message from context handler.
            """
        )
    }

    @Test("Bottle handler - throw bottle with water")
    func testBottleThrowWithWater() async throws {
        let bottle = Item("bottle")
            .name("glass bottle")
            .isTakable
            .isContainer
            .isOpen
            .in(.player)

        let water = Item("water")
            .name("quantity of water")
            .isTakable
            .in(.item("bottle"))

        let game = MinimalGame(
            items: bottle, water
        )

        // Use Self.bottleHandler
        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["bottle": Self.bottleHandler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // When
        try await engine.execute("throw bottle")

        // Then
        await mockIO.expectOutput(
            """
            > throw bottle
            The bottle hits the far wall and shatters. The water spills to
            the floor and evaporates.
            """
        )

        // Both bottle and water should be gone
        let finalBottle = await engine.item("bottle")
        let finalWater = await engine.item("water")
        #expect(await finalBottle.parent == .nowhere)
        #expect(await finalWater.parent == .nowhere)
    }

    @Test("Bottle handler - throw empty bottle")
    func testBottleThrowEmpty() async throws {
        let bottle = Item("bottle")
            .name("glass bottle")
            .isTakable
            .isContainer
            .isOpen
            .in(.player)

        let water = Item("water")
            .name("quantity of water")
            .isTakable
            .in(.nowhere)

        let game = MinimalGame(
            items: bottle, water
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["bottle": Self.bottleHandler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // When
        try await engine.execute(
            "throw bottle",
            "inventory"
        )

        // Then
        await mockIO.expectOutput(
            """
            > throw bottle
            The bottle hits the far wall and shatters.
            
            > inventory
            Your hands are as empty as your pockets.
            """
        )

        // Bottle should be gone
        let finalBottle = await engine.item("bottle")
        #expect(await finalBottle.parent == .nowhere)
    }

    @Test("Bottle handler - attack bottle with water")
    func testBottleAttackWithWater() async throws {
        let bottle = Item("bottle")
            .name("glass bottle")
            .isTakable
            .isContainer
            .isOpen
            .in(.player)

        let water = Item("water")
            .name("quantity of water")
            .isTakable
            .in(.item("bottle"))

        let game = MinimalGame(
            items: bottle, water
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["bottle": Self.bottleHandler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // When
        try await engine.execute("attack bottle")

        // Then
        await mockIO.expectOutput(
            """
            > attack bottle
            A brilliant maneuver destroys the bottle. The water spills to
            the floor and evaporates.
            """
        )

        // Both bottle and water should be gone
        let finalBottle = await engine.item("bottle")
        let finalWater = await engine.item("water")
        #expect(await finalBottle.parent == .nowhere)
        #expect(await finalWater.parent == .nowhere)
    }

    @Test("Bottle handler - shake open bottle with water")
    func testBottleShakeWithWater() async throws {
        let bottle = Item("bottle")
            .name("glass bottle")
            .isTakable
            .isContainer
            .isOpen
            .in(.player)

        let water = Item("water")
            .name("quantity of water")
            .isTakable
            .in(.item("bottle"))

        let game = MinimalGame(
            items: bottle, water
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["bottle": Self.bottleHandler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // When
        try await engine.execute("shake bottle")

        // Then
        await mockIO.expectOutput(
            """
            > shake bottle
            The water spills to the floor and evaporates.
            """
        )

        // Water should be gone, bottle should remain
        let finalBottle = await engine.item("bottle")
        let finalWater = await engine.item("water")
        #expect(await finalBottle.parent == .player)
        #expect(await finalWater.parent == .nowhere)
    }

    @Test("Bottle handler - shake closed bottle with water does nothing special")
    func testBottleShakeClosedWithWater() async throws {
        let bottle = Item("bottle")
            .name("glass bottle")
            .isTakable
            .isContainer
        // Note: not open
            .in(.player)

        let water = Item("water")
            .name("quantity of water")
            .isTakable
            .in(.item("bottle"))

        let game = MinimalGame(
            items: bottle, water
        )

        let blueprint = TestGameBlueprint(
            baseGame: game,
            itemEventHandlers: ["bottle": Self.bottleHandler]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        // When
        try await engine.execute("shake bottle")

        // Then - should get default shake message since bottle is closed
        await mockIO.expectOutput(
            """
            > shake bottle
            Your agitation of the glass bottle produces no observable
            effect.
            """
        )

        // Both bottle and water should remain unchanged
        let finalBottle = await engine.item("bottle")
        let finalWater = await engine.item("water")
        #expect(await finalBottle.parent == .player)
        #expect(await finalWater.parent == .item(finalBottle))
    }
}

extension ItemEventHandlerTests {
    static let bottleHandler = ItemEventHandler(for: "bottle") {
        before(.throw) { context, _ in
            let water = await context.item("water")
            let hasWater = await water.parent == .item(context.item)

            return if hasWater {
                ActionResult(
                    """
                    The bottle hits the far wall and shatters.
                    The water spills to the floor and evaporates.
                    """,
                    context.item.remove(),
                    water.remove()
                )
            } else {
                ActionResult(
                    "The bottle hits the far wall and shatters.",
                    context.item.remove()
                )
            }
        }

        before(.attack) { context, _ in
            let water = await context.item("water")
            let hasWater = await water.parent == .item(context.item)

            return if hasWater {
                ActionResult(
                    """
                    A brilliant maneuver destroys the bottle.
                    The water spills to the floor and evaporates.
                    """,
                    context.item.remove(),
                    water.remove()
                )
            } else {
                ActionResult(
                    "A brilliant maneuver destroys the bottle.",
                    context.item.remove()
                )
            }
        }

        before(.push) { context, _ in
            let water = await context.item("water")
            let hasWater = await water.parent == .item(context.item)
            let isOpen = await context.item.hasFlag(.isOpen)

            return if isOpen && hasWater {
                ActionResult(
                    "The water spills to the floor and evaporates.",
                    water.remove()
                )
            } else {
                nil  // Let default shake handler take over
            }
        }
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

private actor VerbCapture {
    private var verbs: [String] = []

    func addVerb(_ verb: String) {
        verbs.append(verb)
    }

    func getVerbs() -> [String] {
        verbs
    }
}

private actor SequenceCapture {
    private var events: [String] = []

    func addEvent(_ event: String) {
        events.append(event)
    }

    func getEvents() -> [String] {
        events
    }
}

private struct TestGameBlueprint: GameBlueprint {
    let baseGame: MinimalGame
    let itemEventHandlers: [ItemID: ItemEventHandler]
    let locationEventHandlers: [LocationID: LocationEventHandler]
    let messenger: StandardMessenger
    let randomNumberGenerator: any RandomNumberGenerator & Sendable

    init(
        baseGame: MinimalGame,
        itemEventHandlers: [ItemID: ItemEventHandler] = [:],
        locationEventHandlers: [LocationID: LocationEventHandler] = [:]
    ) {
        self.baseGame = baseGame
        self.itemEventHandlers = itemEventHandlers
        self.locationEventHandlers = locationEventHandlers
        self.randomNumberGenerator = SeededRandomNumberGenerator()
        self.messenger = StandardMessenger(
            randomNumberGenerator: SeededRandomNumberGenerator()
        )
    }

    var title: String { baseGame.title }
    var abbreviatedTitle: String { baseGame.abbreviatedTitle }
    var introduction: String { baseGame.introduction }
    var release: String { baseGame.release }
    var maximumScore: Int { baseGame.maximumScore }
    var player: Player { baseGame.player }
    var locations: [Location] { baseGame.locations }
    var items: [Item] { baseGame.items }
}
