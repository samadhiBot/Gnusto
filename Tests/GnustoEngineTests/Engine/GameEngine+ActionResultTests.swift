import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine ActionResult Processing Tests")
struct GameEngineActionResultTests {

    // MARK: - Basic ActionResult Processing Tests

    @Test("ActionResult with message only")
    func testActionResultWithMessageOnly() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create a simple ActionResult with just a message
        let actionResult = ActionResult(message: "Simple action completed.")

        // When: Processing the ActionResult
        try await engine.processActionResult(actionResult)

        // Then: Should return the message
        let output = await mockIO.flush()
        expectNoDifference(output, "Simple action completed.")
    }

    @Test("ActionResult with state changes")
    func testActionResultWithStateChanges() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A small brass lamp."),
            .isLightSource,
            .isDevice,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create ActionResult with state changes
        let stateChanges = [
            StateChange.setItemProperty(
                id: "lamp",
                property: .isOn,
                value: .bool(true)
            ),
            StateChange.setItemProperty(
                id: "lamp",
                property: .isTouched,
                value: .bool(true)
            ),
        ]

        let actionResult = ActionResult(
            message: "Lamp activated with multiple changes!",
            changes: stateChanges
        )

        // When: Processing the ActionResult
        try await engine.processActionResult(actionResult)

        // Then: Message should be returned
        let output = await mockIO.flush()
        expectNoDifference(output, "Lamp activated with multiple changes!")

        // And: State changes should be applied
        let finalLamp = try await engine.item("lamp")
        #expect(await finalLamp.hasFlag(.isOn) == true)
        #expect(await finalLamp.hasFlag(.isTouched) == true)
    }

    @Test("ActionResult with side effects")
    func testActionResultWithSideEffects() async throws {
        let testFuse = Fuse(initialTurns: 5) { engine, fuseState in
            ActionResult(message: "💣 Test fuse triggered!")
        }

        let testDaemon = Daemon { engine in
            ActionResult(message: "🤖 Test daemon running")
        }

        let game = MinimalGame(
            fuses: ["testFuse": testFuse],
            daemons: ["testDaemon": testDaemon]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create ActionResult with side effects
        let sideEffects = [
            SideEffect.startFuse("testFuse"),
            SideEffect.runDaemon("testDaemon"),
        ]

        let actionResult = ActionResult(
            message: "Timers activated!",
            effects: sideEffects
        )

        // When: Processing the ActionResult
        try await engine.processActionResult(actionResult)

        // Then: Message should be returned
        let output = await mockIO.flush()
        expectNoDifference(output, "Timers activated!")

        // And: Side effects should be processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses["testFuse"]?.turns == 5)
        #expect(finalState.activeDaemons.contains("testDaemon"))
    }

    @Test("ActionResult with message, changes, and effects")
    func testActionResultWithEverything() async throws {
        let controlPanel = Item(
            id: "panel",
            .name("control panel"),
            .description("A complex control panel."),
            .isDevice,
            .in(.startRoom)
        )

        let testFuse = Fuse(initialTurns: 3) { engine, fuseState in
            ActionResult(message: "⏰ Emergency countdown started!")
        }

        let game = MinimalGame(
            items: controlPanel,
            fuses: ["emergencyFuse": testFuse]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create comprehensive ActionResult
        let stateChanges = [
            StateChange.setItemProperty(
                id: "panel",
                property: .isOn,
                value: .bool(true)
            ),
            StateChange.setItemProperty(
                id: "panel",
                property: .isTouched,
                value: .bool(true)
            ),
        ]

        let sideEffects = [
            SideEffect.startFuse("emergencyFuse")
        ]

        let actionResult = ActionResult(
            message: "Control panel activated! Emergency systems online.",
            changes: stateChanges,
            effects: sideEffects
        )

        // When: Processing the comprehensive ActionResult
        try await engine.processActionResult(actionResult)

        // Then: All components should be processed
        let output = await mockIO.flush()
        expectNoDifference(output, "Control panel activated! Emergency systems online.")

        // State changes applied
        let finalPanel = try await engine.item("panel")
        #expect(await finalPanel.hasFlag(.isOn) == true)
        #expect(await finalPanel.hasFlag(.isTouched) == true)

        // Side effects processed
        let finalState = await engine.gameState
        #expect(
            finalState.activeFuses["emergencyFuse"] == FuseState(
                turns: 3,
                state: [:]
            )
        )
    }

    // MARK: - Error Handling Tests

    @Test("ActionResult processing handles invalid state changes")
    func testActionResultWithInvalidStateChanges() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create ActionResult with invalid state change (non-existent item)
        let invalidChange = StateChange.setItemProperty(
            id: "nonExistentItem",
            property: .isOn,
            value: .bool(true)
        )

        let actionResult = ActionResult(
            message: "This should work despite invalid change",
            changes: [invalidChange]
        )

        // When: Processing ActionResult with invalid change
        await #expect(throws: ActionResponse.self) {
            try await engine.processActionResult(actionResult)
        }

        // Invalid change should be ignored (no crash)
        let history = await engine.changeHistory
        #expect(
            history.contains {
                if case .setItemProperty(let id, _, _) = $0 {
                    return id == "nonExistentItem"
                }
                return false
            } == false)
    }

    @Test("ActionResult processing handles invalid side effects")
    func testActionResultWithInvalidSideEffects() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create ActionResult with invalid side effect (non-existent fuse)
        let invalidSideEffect = SideEffect.startFuse("nonExistentFuse")

        let actionResult = ActionResult(
            message: "This should fail on side effect",
            effects: [invalidSideEffect]
        )

        // When/Then: Processing ActionResult with invalid side effect should throw
        await #expect(throws: ActionResponse.self) {
            try await engine.processActionResult(actionResult)
        }
    }

    @Test("ActionResult nil returns appropriate default message")
    func testActionResultNilHandling() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Processing nil ActionResult
        let emptyResult = ActionResult(message: "")
        try await engine.processActionResult(emptyResult)

        // Then: Should return empty string or appropriate default
        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    // MARK: - Integration Tests with Action Handlers

    @Test("ActionResult integration with custom action handler")
    func testActionResultIntegrationWithCustomHandler() async throws {
        // Create a custom action handler that returns a comprehensive ActionResult
        struct ComplexActionHandler: ActionHandler {
            let synonyms: [Verb] = [Verb("activate")]
            let syntax: [SyntaxRule] = [.match(.verb, .directObject)]
            let requiresLight: Bool = true

            func process(context: ActionContext) async throws -> ActionResult {
                guard let directObject = context.command.directObject,
                    case .item(let item) = directObject
                else {
                    return ActionResult(message: "You need to specify what to activate.")
                }

                let stateChanges = [
                    StateChange.setItemProperty(
                        id: item.id,
                        property: .isOn,
                        value: .bool(true)
                    ),
                    StateChange.setItemProperty(
                        id: item.id,
                        property: .isTouched,
                        value: .bool(true)
                    ),
                ]

                let sideEffects = [
                    SideEffect.startFuse("activationFuse")
                ]

                return ActionResult(
                    message: "The \(await item.name) hums to life with complex activation!",
                    changes: stateChanges,
                    effects: sideEffects
                )
            }
        }

        let device = Item(
            id: "device",
            .name("mysterious device"),
            .description("A strange technological device."),
            .isDevice,
            .in(.startRoom)
        )

        let activationFuse = Fuse(initialTurns: 2) { engine, state in
            ActionResult(message: "🔥 The device overloads!")
        }

        let game = MinimalGame(
            items: device,
            customActionHandlers: [ComplexActionHandler()],
            fuses: ["activationFuse": activationFuse]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Executing the custom action
        try await engine.execute("activate device")

        // Then: All aspects of ActionResult should be processed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > activate device
            The mysterious device hums to life with complex activation!
            """
        )

        // State changes applied
        let finalDevice = try await engine.item("device")
        #expect(await finalDevice.hasFlag(.isOn) == true)
        #expect(await finalDevice.hasFlag(.isTouched) == true)

        // Side effects processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses["activationFuse"] == FuseState(turns: 1))
    }

    @Test("ActionResult processing preserves change order")
    func testActionResultPreservesChangeOrder() async throws {
        let counter = Item(
            id: "counter",
            .name("counter"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: counter
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create ActionResult with ordered state changes
        let orderedChanges = [
            StateChange.setItemProperty(
                id: "counter",
                property: .testCounter,
                value: .int(1)
            ),
            StateChange.setItemProperty(
                id: "counter",
                property: .testCounter,
                value: .int(2)
            ),
            StateChange.setItemProperty(
                id: "counter",
                property: .testCounter,
                value: .int(3)
            ),
        ]

        let actionResult = ActionResult(
            message: "Counter incremented three times.",
            changes: orderedChanges
        )

        // When: Processing the ActionResult
        try await engine.processActionResult(actionResult)

        // Then: Final value should be from the last change
        let output = await mockIO.flush()
        expectNoDifference(output, "Counter incremented three times.")

        let finalCounter = try await engine.item("counter")
        #expect(try await finalCounter.property(.testCounter) == .int(3))

        // And: Change history should preserve order
        let history = await engine.changeHistory
        let counterChanges = history.filter {
            if case .setItemProperty(let id, _, _) = $0 {
                return id == "counter"
            }
            return false
        }
        #expect(counterChanges.count == 3)
        if case .setItemProperty(_, _, let value1) = counterChanges[0] {
            #expect(value1 == .int(1))
        }
        if case .setItemProperty(_, _, let value2) = counterChanges[1] {
            #expect(value2 == .int(2))
        }
        if case .setItemProperty(_, _, let value3) = counterChanges[2] {
            #expect(value3 == .int(3))
        }
    }

    // MARK: - ActionResult Chaining Tests

    @Test("multiple ActionResults process in sequence")
    func testMultipleActionResultsInSequence() async throws {
        // Create a custom handler that processes multiple ActionResults
        struct SequentialActionHandler: ActionHandler {
            let synonyms: [Verb] = [Verb("sequence")]
            let syntax: [SyntaxRule] = [.match(.verb)]
            let requiresLight: Bool = false

            func process(context: ActionContext) async throws -> ActionResult {
                // First ActionResult
                let firstResult = ActionResult(
                    message: "First action completed.",
                    changes: [
                        StateChange.setFlag("step1")
                    ]
                )

                // Process first result
                _ = try await context.engine.processActionResult(firstResult)

                // Second ActionResult
                let secondResult = ActionResult(
                    message: "Second action completed.",
                    changes: [
                        StateChange.setFlag("step2")
                    ]
                )

                // Process second result
                _ = try await context.engine.processActionResult(secondResult)

                // Return final result
                return ActionResult(message: "Sequence completed successfully.")
            }
        }

        let game = MinimalGame(
            customActionHandlers: [SequentialActionHandler()]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Executing the sequential action
        try await engine.execute("sequence")

        // Then: Final message should be displayed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > sequence
            First action completed.

            Second action completed.

            Sequence completed successfully.
            """
        )

        // And: All flags should be set
        #expect(await engine.hasFlag("step1") == true)
        #expect(await engine.hasFlag("step2") == true)
    }

    // MARK: - ActionResult with Pronoun Updates

    @Test("ActionResult triggers automatic pronoun updates")
    func testActionResultTriggersAutomaticPronounUpdates() async throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A simple test item."),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Executing examine command (which should update pronouns)
        try await engine.execute("examine test item")

        // Then: Pronouns should be updated automatically
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun != nil)

        // And: Command should work normally
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine test item
            A simple test item.
            """
        )
    }

    // MARK: - ActionResult Performance Tests

    @Test("ActionResult with many state changes processes efficiently")
    func testActionResultWithManyStateChanges() async throws {
        // Create many items for bulk changes
        var items: [Item] = []
        for i in 1...20 {
            items.append(
                Item(
                    id: ItemID("item\(i)"),
                    .name("item \(i)"),
                    .in(.startRoom)
                ))
        }

        var gameItems: [Item] = [items[0]]
        for i in 1..<items.count {
            gameItems.append(items[i])
        }

        let game = MinimalGame(
            items: gameItems[0], gameItems[1], gameItems[2], gameItems[3], gameItems[4],
            gameItems[5], gameItems[6], gameItems[7], gameItems[8], gameItems[9],
            gameItems[10], gameItems[11], gameItems[12], gameItems[13], gameItems[14],
            gameItems[15], gameItems[16], gameItems[17], gameItems[18], gameItems[19]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create ActionResult with many state changes
        var bulkChanges: [StateChange] = []
        for i in 1...20 {
            bulkChanges.append(
                StateChange.setItemProperty(
                    id: ItemID("item\(i)"),
                    property: .isTouched,
                    value: .bool(true)
                ))
        }

        let actionResult = ActionResult(
            message: "Bulk operation completed on 20 items.",
            changes: bulkChanges
        )

        // When: Processing many changes at once
        try await engine.processActionResult(actionResult)

        // Then: Should complete successfully
        let output = await mockIO.flush()
        expectNoDifference(output, "Bulk operation completed on 20 items.")

        // And: All changes should be applied
        for i in 1...20 {
            let item = try await engine.item(ItemID("item\(i)"))
            #expect(await item.hasFlag(.isTouched) == true)
        }

        // And: Change history should contain all changes
        let history = await engine.changeHistory
        let touchedChanges = history.filter {
            if case .setItemProperty(_, let property, _) = $0 {
                return property == .isTouched
            }
            return false
        }
        #expect(touchedChanges.count == 20)
    }

    // MARK: - ActionResult Return Value Tests

    @Test("ActionResult nil returns empty string")
    func testActionResultNilReturnsEmptyString() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Processing nil ActionResult
        let emptyResult = ActionResult(message: "")
        try await engine.processActionResult(emptyResult)

        // Then: Should return empty string
        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    @Test("ActionResult with empty message returns empty string")
    func testActionResultWithEmptyMessage() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Processing ActionResult with empty message
        let actionResult = ActionResult(message: "")
        try await engine.processActionResult(actionResult)

        // Then: Should return empty string
        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    // MARK: - ActionResult State Consistency Tests

    @Test("ActionResult changes are atomic")
    func testActionResultChangesAreAtomic() async throws {
        let device = Item(
            id: "device",
            .name("device"),
            .isDevice,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Create ActionResult with related changes that should all succeed or all fail
        let atomicChanges = [
            StateChange.setItemProperty(
                id: "device",
                property: .isOn,
                value: .bool(true)
            ),
            StateChange.setFlag("deviceActivated"),
        ]

        let actionResult = ActionResult(
            message: "Device fully activated.",
            changes: atomicChanges
        )

        // When: Processing atomic changes
        try await engine.processActionResult(actionResult)

        // Then: All changes should be applied together
        let output = await mockIO.flush()
        expectNoDifference(output, "Device fully activated.")

        let finalDevice = try await engine.item("device")
        #expect(await finalDevice.hasFlag(.isOn) == true)
        #expect(await engine.hasFlag("deviceActivated") == true)

        // And: Change history should show both changes
        let history = await engine.changeHistory
        #expect(history.count >= 2)
        #expect(
            history.contains {
                if case .setItemProperty(let id, _, _) = $0 {
                    return id == "device"
                }
                return false
            })
        #expect(
            history.contains {
                if case .setFlag = $0 {
                    return true
                }
                return false
            })
    }

    // MARK: - Real-World Integration Tests

    @Test("ActionResult integration with TakeActionHandler")
    func testActionResultIntegrationWithTakeActionHandler() async throws {
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Taking an item (uses real TakeActionHandler)
        try await engine.execute("take gold coin")

        // Then: ActionResult should be processed correctly
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take gold coin
            Taken.
            """
        )

        // And: State should be updated
        let finalCoin = try await engine.item("coin")
        #expect(try await finalCoin.parent == .player)

        // And: Pronouns should be updated
        let pronoun = await engine.gameState.pronoun
        #expect(pronoun != nil)
    }

    @Test("ActionResult integration with device handlers")
    func testActionResultIntegrationWithDeviceHandlers() async throws {
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A polished brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Taking lamp then turning it on
        try await engine.execute(
            "take lamp",
            "turn on lamp"
        )

        // Then: Both ActionResults should be processed
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take lamp
            Taken.

            > turn on lamp
            You successfully turn on the brass lamp.
            """
        )

        // And: Final state should reflect both actions
        let finalLamp = try await engine.item("lamp")
        #expect(try await finalLamp.parent == .player)
        #expect(await finalLamp.hasFlag(.isOn) == true)
        #expect(await finalLamp.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionResult Message Formatting Tests

    @Test("ActionResult supports complex message formatting")
    func testActionResultComplexMessageFormatting() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test multiline message
        let multilineResult = ActionResult(
            """
            This is a complex message
            that spans multiple lines
            and contains various formatting.
            """
        )

        try await engine.processActionResult(multilineResult)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            This is a complex message that spans multiple lines and
            contains various formatting.
            """
        )
    }

    @Test("ActionResult handles special characters in messages")
    func testActionResultHandlesSpecialCharacters() async throws {
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test message with special characters
        let specialCharResult = ActionResult(
            message: "Special chars: é, ñ, 中文, emoji 🎮, quotes \"'`"
        )

        try await engine.processActionResult(specialCharResult)
        let output = await mockIO.flush()
        expectNoDifference(output, "Special chars: é, ñ, 中文, emoji 🎮, quotes \"'`")
    }
}

// MARK: - Test Extensions

extension ItemPropertyID {
    fileprivate static let testCounter = ItemPropertyID("testCounter")
}
