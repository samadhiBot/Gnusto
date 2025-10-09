import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Middleware System Tests")
struct GameEngineMiddlewareTests {

    // MARK: - Test Middleware Implementations

    /// Mock middleware for testing that records all hook calls.
    actor RecordingMiddleware: GnustoMiddleware {
        let stateKey: String
        let priority: Int

        private(set) var beforeTurnCalls = 0
        private(set) var beforeCommandCalls = 0
        private(set) var interceptActionCalls = 0
        private(set) var afterCommandCalls = 0
        private(set) var beforeTimeAdvancementCalls = 0
        private(set) var afterTurnCalls = 0
        private(set) var saveStateCalls = 0
        private(set) var restoreStateCalls = 0

        var beforeTurnResult: MiddlewareResult = .continue
        var beforeCommandResult: CommandMiddlewareResult?
        var interceptActionResult: ActionResult?
        var afterCommandModifier: ((ActionResult) -> ActionResult)?
        var beforeTimeAdvancementResult: MiddlewareResult = .continue

        init(stateKey: String, priority: Int = 0) {
            self.stateKey = stateKey
            self.priority = priority
        }

        func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
            beforeTurnCalls += 1
            return beforeTurnResult
        }

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            beforeCommandCalls += 1
            return beforeCommandResult ?? .continue(command)
        }

        func interceptAction(
            handler: any ActionHandler,
            context: ActionContext
        ) async throws -> ActionResult? {
            interceptActionCalls += 1
            return interceptActionResult
        }

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            afterCommandCalls += 1
            if let modifier = afterCommandModifier {
                return modifier(result)
            }
            return result
        }

        func beforeTimeAdvancement(context: MiddlewareContext) async throws -> MiddlewareResult {
            beforeTimeAdvancementCalls += 1
            return beforeTimeAdvancementResult
        }

        func afterTurn(context: MiddlewareContext) async throws {
            afterTurnCalls += 1
        }

        func saveState(context: MiddlewareContext) async throws -> (any Codable & Sendable)? {
            saveStateCalls += 1
            return ["saveCount": saveStateCalls]
        }

        func restoreState(_ state: any Codable & Sendable, context: MiddlewareContext) async throws
        {
            restoreStateCalls += 1
        }
    }

    /// Middleware that modifies commands.
    struct CommandModifyingMiddleware: GnustoMiddleware {
        let stateKey = "command-modifier"
        let priority = 50

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            // Modify the command by changing its verb
            .continue(
                Command(
                    verb: .examine,
                    directObject: command.directObject,
                    directObjectModifiers: command.directObjectModifiers,
                    indirectObject: command.indirectObject,
                    indirectObjectModifiers: command.indirectObjectModifiers,
                    preposition: command.preposition,
                    direction: command.direction,
                    rawInput: command.rawInput
                )
            )
        }
    }

    /// Middleware that skips command execution.
    struct CommandSkippingMiddleware: GnustoMiddleware {
        let stateKey = "command-skipper"
        let priority = 100

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            .skip(ActionResult("Command was skipped by middleware"))
        }
    }

    /// Middleware that handles entire turns.
    struct TurnHandlingMiddleware: GnustoMiddleware {
        let stateKey = "turn-handler"
        let priority = 150

        func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
            .handled(ActionResult("Turn handled by middleware"))
        }
    }

    /// Middleware that prevents time advancement.
    struct TimeFreezeMiddleware: GnustoMiddleware {
        let stateKey = "time-freeze"
        let priority = 25

        func beforeTimeAdvancement(context: MiddlewareContext) async throws -> MiddlewareResult {
            .handled(ActionResult("Time is frozen"))
        }
    }

    /// Middleware that appends messages to results.
    struct MessageAppendingMiddleware: GnustoMiddleware {
        let stateKey = "message-appender"
        let priority = 10
        let message: String

        init(message: String) {
            self.message = message
        }

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            result.appending(
                ActionResult(message)
            )
        }
    }

    // MARK: - Middleware Registration Tests

    @Test("middleware registered through blueprint")
    func testMiddlewareRegisteredThroughBlueprint() async throws {
        let middleware = RecordingMiddleware(stateKey: "test", priority: 50)
        let game = MinimalGame(middleware: [middleware])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let sortedMiddleware = await engine.sortedMiddleware
        #expect(sortedMiddleware.count == 1)
        #expect(sortedMiddleware[0].stateKey == "test")
        #expect(sortedMiddleware[0].priority == 50)
    }

    @Test("multiple middleware registered through blueprint")
    func testMultipleMiddlewareRegisteredThroughBlueprint() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 50)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 100)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let sortedMiddleware = await engine.sortedMiddleware
        #expect(sortedMiddleware.count == 2)
        #expect(sortedMiddleware[0].stateKey == "test2")
        #expect(sortedMiddleware[1].stateKey == "test1")
    }

    @Test("sortedMiddleware returns middleware in priority order")
    func testSortedMiddleware() async throws {
        let lowPriority = RecordingMiddleware(stateKey: "low", priority: 10)
        let highPriority = RecordingMiddleware(stateKey: "high", priority: 100)
        let mediumPriority = RecordingMiddleware(stateKey: "medium", priority: 50)

        // Register out of order
        let game = MinimalGame(middleware: [lowPriority, highPriority, mediumPriority])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let sorted = await engine.sortedMiddleware
        #expect(sorted.count == 3)
        #expect(sorted[0].stateKey == "high")
        #expect(sorted[1].stateKey == "medium")
        #expect(sorted[2].stateKey == "low")
    }

    // MARK: - Before Turn Hook Tests

    @Test("executeBeforeTurnMiddleware calls all middleware in order")
    func testExecuteBeforeTurnMiddleware() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let result = try await engine.executeBeforeTurnMiddleware()

        #expect(result == .continue)
        #expect(await middleware1.beforeTurnCalls == 1)
        #expect(await middleware2.beforeTurnCalls == 1)
    }

    @Test("executeBeforeTurnMiddleware stops on handled result")
    func testExecuteBeforeTurnMiddlewareStopsOnHandled() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)

        // Make first middleware return .handled
        await middleware1.setBeforeTurnResult(.handled())

        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let result = try await engine.executeBeforeTurnMiddleware()

        #expect(result == .handled())
        #expect(await middleware1.beforeTurnCalls == 1)
        #expect(await middleware2.beforeTurnCalls == 0)  // Should not be called
    }

    // MARK: - Before Command Execution Hook Tests

    @Test("executeBeforeCommandMiddleware calls all middleware in order")
    func testExecuteBeforeCommandMiddleware() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        let result = try await engine.executeBeforeCommandMiddleware(command: command)

        if case .continue(let finalCommand) = result {
            #expect(finalCommand.verb == .take)
        } else {
            Issue.record("Expected .continue result")
        }

        #expect(await middleware1.beforeCommandCalls == 1)
        #expect(await middleware2.beforeCommandCalls == 1)
    }

    @Test("executeBeforeCommandMiddleware can modify command")
    func testExecuteBeforeCommandMiddlewareModifiesCommand() async throws {
        let modifier = CommandModifyingMiddleware()
        let game = MinimalGame(middleware: [modifier])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        let result = try await engine.executeBeforeCommandMiddleware(command: command)

        if case .continue(let finalCommand) = result {
            #expect(finalCommand.verb == .examine)  // Should be modified
        } else {
            Issue.record("Expected .continue result with modified command")
        }
    }

    @Test("executeBeforeCommandMiddleware can skip command")
    func testExecuteBeforeCommandMiddlewareSkipsCommand() async throws {
        let skipper = CommandSkippingMiddleware()
        let game = MinimalGame(middleware: [skipper])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        let result = try await engine.executeBeforeCommandMiddleware(command: command)

        if case .skip(let actionResult) = result {
            #expect(actionResult?.message == "Command was skipped by middleware")
        } else {
            Issue.record("Expected .skip result")
        }
    }

    @Test("executeBeforeCommandMiddleware chains modifications")
    func testExecuteBeforeCommandMiddlewareChainsModifications() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)

        // Both middleware modify the command
        let modifiedCommand1 = Command(
            verb: .examine,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "modified1"
        )
        await middleware1.setBeforeCommandResult(.continue(modifiedCommand1))

        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let originalCommand = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        _ = try await engine.executeBeforeCommandMiddleware(command: originalCommand)

        // Both middleware should be called
        #expect(await middleware1.beforeCommandCalls == 1)
        #expect(await middleware2.beforeCommandCalls == 1)
    }

    // MARK: - After Command Execution Hook Tests

    @Test("executeAfterCommandMiddleware calls all middleware in order")
    func testExecuteAfterCommandMiddleware() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        let result = ActionResult("Original result")
        _ = try await engine.executeAfterCommandMiddleware(command: command, result: result)

        #expect(await middleware1.afterCommandCalls == 1)
        #expect(await middleware2.afterCommandCalls == 1)
    }

    @Test("executeAfterCommandMiddleware chains result modifications")
    func testExecuteAfterCommandMiddlewareChainsResults() async throws {
        let appender1 = MessageAppendingMiddleware(message: "First append")
        let appender2 = MessageAppendingMiddleware(message: "Second append")
        let game = MinimalGame(middleware: [appender1, appender2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .take,
            directObject: nil,
            indirectObject: nil,
            direction: nil,
            rawInput: "take item"
        )

        let result = ActionResult("Original")
        let finalResult = try await engine.executeAfterCommandMiddleware(
            command: command,
            result: result
        )

        // Result should contain all messages in order
        #expect(finalResult.message?.contains("Original") == true)
        #expect(finalResult.message?.contains("First append") == true)
        #expect(finalResult.message?.contains("Second append") == true)
    }

    // MARK: - Before Time Advancement Hook Tests

    @Test("executeBeforeTimeAdvancementMiddleware calls all middleware")
    func testExecuteBeforeTimeAdvancementMiddleware() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let result = try await engine.executeBeforeTimeAdvancementMiddleware()

        #expect(result == .continue)
        #expect(await middleware1.beforeTimeAdvancementCalls == 1)
        #expect(await middleware2.beforeTimeAdvancementCalls == 1)
    }

    @Test("executeBeforeTimeAdvancementMiddleware stops on handled")
    func testExecuteBeforeTimeAdvancementMiddlewareStopsOnHandled() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)

        await middleware1.setBeforeTimeAdvancementResult(.handled())

        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let result = try await engine.executeBeforeTimeAdvancementMiddleware()

        #expect(result == .handled())
        #expect(await middleware1.beforeTimeAdvancementCalls == 1)
        #expect(await middleware2.beforeTimeAdvancementCalls == 0)
    }

    // MARK: - After Turn Hook Tests

    @Test("executeAfterTurnMiddleware calls all middleware")
    func testExecuteAfterTurnMiddleware() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.executeAfterTurnMiddleware()

        #expect(await middleware1.afterTurnCalls == 1)
        #expect(await middleware2.afterTurnCalls == 1)
    }

    @Test("executeAfterTurnMiddleware calls all middleware even if one throws")
    func testExecuteAfterTurnMiddlewareHandlesErrors() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Should not throw even if middleware has issues
        try await engine.executeAfterTurnMiddleware()

        #expect(await middleware1.afterTurnCalls == 1)
        #expect(await middleware2.afterTurnCalls == 1)
    }

    // MARK: - State Persistence Tests

    @Test("saveMiddlewareState collects state from all middleware")
    func testSaveMiddlewareState() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let savedStates = try await engine.saveMiddlewareState()

        #expect(savedStates.count == 2)
        #expect(savedStates["test1"] != nil)
        #expect(savedStates["test2"] != nil)
        #expect(await middleware1.saveStateCalls == 1)
        #expect(await middleware2.saveStateCalls == 1)
    }

    @Test("restoreMiddlewareState restores state to all middleware")
    func testRestoreMiddlewareState() async throws {
        let middleware1 = RecordingMiddleware(stateKey: "test1", priority: 100)
        let middleware2 = RecordingMiddleware(stateKey: "test2", priority: 50)
        let game = MinimalGame(middleware: [middleware1, middleware2])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let savedStates: [String: any Codable & Sendable] = [
            "test1": ["data": "state1"],
            "test2": ["data": "state2"],
        ]

        try await engine.restoreMiddlewareState(savedStates)

        #expect(await middleware1.restoreStateCalls == 1)
        #expect(await middleware2.restoreStateCalls == 1)
    }

    @Test("middleware state persistence round trip")
    func testMiddlewareStatePersistenceRoundTrip() async throws {
        let middleware = RecordingMiddleware(stateKey: "test", priority: 100)
        let game = MinimalGame(middleware: [middleware])
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Save state
        let savedStates = try await engine.saveMiddlewareState()
        #expect(savedStates.count == 1)
        #expect(await middleware.saveStateCalls == 1)

        // Restore state
        try await engine.restoreMiddlewareState(savedStates)
        #expect(await middleware.restoreStateCalls == 1)
    }

    // MARK: - Priority Execution Tests

    @Test("middleware executes in strict priority order")
    func testMiddlewareExecutionOrder() async throws {
        actor ExecutionTracker {
            var order: [String] = []
            func record(_ key: String) {
                order.append(key)
            }
            var currentOrder: [String] { order }
        }

        struct OrderTrackingMiddleware: GnustoMiddleware {
            let stateKey: String
            let priority: Int
            let tracker: ExecutionTracker

            func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
                await tracker.record(stateKey)
                return .continue
            }
        }

        let tracker = ExecutionTracker()

        let high = OrderTrackingMiddleware(stateKey: "high", priority: 100, tracker: tracker)
        let medium = OrderTrackingMiddleware(stateKey: "medium", priority: 50, tracker: tracker)
        let low = OrderTrackingMiddleware(stateKey: "low", priority: 10, tracker: tracker)

        let game = MinimalGame(middleware: [low, high, medium])
        let (engine, _) = await GameEngine.test(blueprint: game)

        _ = try await engine.executeBeforeTurnMiddleware()

        let order = await tracker.currentOrder
        #expect(order == ["high", "medium", "low"])
    }

    // MARK: - Integration Tests

    @Test("middleware integrates with game loop")
    func testMiddlewareGameLoopIntegration() async throws {
        let middleware = RecordingMiddleware(stateKey: "test", priority: 50)
        let game = MinimalGame(middleware: [middleware])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        // Verify all hooks were called during the turn
        #expect(await middleware.beforeTurnCalls == 1)
        #expect(await middleware.beforeCommandCalls == 1)
        #expect(await middleware.afterCommandCalls == 1)
        #expect(await middleware.beforeTimeAdvancementCalls == 1)
        #expect(await middleware.afterTurnCalls == 1)

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("turn handling middleware prevents normal turn processing")
    func testTurnHandlingMiddlewarePreventsProcessing() async throws {
        let turnHandler = TurnHandlingMiddleware()
        let game = MinimalGame(middleware: [turnHandler])
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look")
        )

        try await engine.processTurn()

        // Should not have processed the "look" command
        await mockIO.expect(
            """
            Turn handled by middleware
            """
        )
    }

    @Test("command skipping middleware prevents execution")
    func testCommandSkippingMiddlewarePreventsExecution() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let skipper = CommandSkippingMiddleware()
        let game = MinimalGame(items: testItem, middleware: [skipper])
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("take test item")
        )

        try await engine.processTurn()

        // Item should not have been taken
        let item = await engine.item("testItem")
        #expect(await item.parent != .player)

        await mockIO.expect(
            """
            > take test item
            Command was skipped by middleware
            """
        )
    }

    @Test("time freeze middleware prevents time advancement")
    func testTimeFreezeMiddleware() async throws {
        let timeFreezer = TimeFreezeMiddleware()

        // Create a fuse that would normally fire after 1 turn
        let game = MinimalGame(
            fuses: [
                "test-fuse": Fuse(initialTurns: 1) { _, _ in
                    ActionResult("Fuse fired!")
                },
            ],
            middleware: [timeFreezer]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.processSideEffects(
            .startFuse("test-fuse")
        )

        try await engine.execute("wait", times: 2)

        // Fuse should not have fired
        await mockIO.expect(
            """
            > wait
            Time flows onward, indifferent to your concerns.

            Time is frozen

            > wait
            The universe's clock ticks inexorably forward.

            Time is frozen
            """
        )
    }

    @Test("multiple middleware execute in correct sequence")
    func testMultipleMiddlewareSequence() async throws {
        let appender1 = MessageAppendingMiddleware(message: "\n\nFirst middleware message.")
        let appender2 = MessageAppendingMiddleware(message: "\n\nSecond middleware message.")

        let game = MinimalGame(middleware: [appender1, appender2])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            First middleware message.

            Second middleware message.
            """
        )
    }
}

// MARK: - Helper Extensions

extension GameEngineMiddlewareTests.RecordingMiddleware {
    func setBeforeTurnResult(_ result: MiddlewareResult) {
        self.beforeTurnResult = result
    }

    func setBeforeCommandResult(_ result: CommandMiddlewareResult) {
        self.beforeCommandResult = result
    }

    func setInterceptActionResult(_ result: ActionResult?) {
        self.interceptActionResult = result
    }

    func setAfterCommandModifier(_ modifier: @escaping (ActionResult) -> ActionResult) {
        self.afterCommandModifier = modifier
    }

    func setBeforeTimeAdvancementResult(_ result: MiddlewareResult) {
        self.beforeTimeAdvancementResult = result
    }
}
