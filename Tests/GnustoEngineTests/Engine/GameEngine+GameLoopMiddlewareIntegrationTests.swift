import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Game Loop Middleware Integration Tests")
struct GameEngineGameLoopMiddlewareIntegrationTests {

    // MARK: - Test Middleware Implementations

    /// Middleware that tracks when each hook is called during the game loop.
    actor GameLoopTrackingMiddleware: GnustoMiddleware {
        let stateKey = "game-loop-tracker"
        let priority = 50

        private(set) var callSequence: [String] = []

        func recordCall(_ hook: String) {
            callSequence.append(hook)
        }

        var sequence: [String] { callSequence }

        func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
            callSequence.append("beforeTurn")
            return .continue
        }

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            callSequence.append("beforeCommandExecution")
            return .continue(command)
        }

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            callSequence.append("afterCommandExecution")
            return result
        }

        func beforeTimeAdvancement(context: MiddlewareContext) async throws -> MiddlewareResult {
            callSequence.append("beforeTimeAdvancement")
            return .continue
        }

        func afterTurn(context: MiddlewareContext) async throws {
            callSequence.append("afterTurn")
        }

        func onParseError(
            error: ParseError,
            rawInput: String,
            context: MiddlewareContext
        ) async throws {
            callSequence.append("onParseError")
        }

        func reset() {
            callSequence.removeAll()
        }
    }

    /// Middleware that validates game state at specific points.
    actor StateValidatingMiddleware: GnustoMiddleware {
        let stateKey = "state-validator"
        let priority = 100

        private(set) var playerLocationChecks: [String] = []
        private(set) var itemChecks: [String] = []

        func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
            let location = await context.engine.player.location.name
            playerLocationChecks.append("beforeTurn: \(location)")
            return .continue
        }

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            let location = await context.engine.player.location.name
            playerLocationChecks.append("afterCommand: \(location)")
            return result
        }

        func recordItemCheck(_ itemID: ItemID, parent: ParentProxy) {
            itemChecks.append("\(itemID): \(parent)")
        }
    }

    /// Middleware that modifies player actions dynamically.
    struct ActionModifyingMiddleware: GnustoMiddleware {
        let stateKey = "action-modifier"
        let priority = 75

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            // Convert "take" to "examine" automatically
            .continue(
                Command(
                    verb: command.verb == .take ? .examine : command.verb,
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

    /// Middleware that adds contextual messages based on game state.
    struct ContextualMessageMiddleware: GnustoMiddleware {
        let stateKey = "contextual-messages"
        let priority = 25

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            // Add a message if player is in a specific location
            let locationName = await context.engine.player.location.name
            if locationName.contains("Laboratory") {
                return result.appending(
                    ActionResult("\n\n[You sense something strange in this laboratory.]")
                )
            }
            return result
        }
    }

    /// Middleware that implements a simple event trigger system.
    actor EventTriggerMiddleware: GnustoMiddleware {
        let stateKey = "event-trigger"
        let priority = 50

        private(set) var triggeredEvents: [String] = []
        var shouldTriggerEvent = false
        var eventMessage = "An event has been triggered!"

        func afterCommandExecution(
            command: Command,
            result: ActionResult,
            context: MiddlewareContext
        ) async throws -> ActionResult {
            if shouldTriggerEvent {
                triggeredEvents.append("event")
                shouldTriggerEvent = false
                return result.appending(ActionResult("\n\n" + eventMessage))
            }
            return result
        }

        func armEvent(message: String) {
            shouldTriggerEvent = true
            eventMessage = message
        }
    }

    /// Middleware that counts turns and provides statistics.
    actor StatisticsMiddleware: GnustoMiddleware {
        let stateKey = "statistics"
        let priority = 5

        private(set) var turnCount = 0
        private(set) var commandCount = 0
        private(set) var parseErrorCount = 0

        func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
            turnCount += 1
            return .continue
        }

        func beforeCommandExecution(
            command: Command,
            context: MiddlewareContext
        ) async throws -> CommandMiddlewareResult {
            commandCount += 1
            return .continue(command)
        }

        func reset() {
            turnCount = 0
            commandCount = 0
            parseErrorCount = 0
        }
    }

    // MARK: - Hook Execution Order Tests

    @Test("middleware hooks execute in correct order during turn")
    func testMiddlewareHookExecutionOrder() async throws {
        let tracker = GameLoopTrackingMiddleware()

        let game = MinimalGame(middleware: [tracker])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        let sequence = await tracker.sequence
        #expect(
            sequence == [
                "beforeTurn",
                "beforeCommandExecution",
                "afterCommandExecution",
                "beforeTimeAdvancement",
                "afterTurn",
            ])

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("middleware hooks skip when beforeTurn returns handled")
    func testBeforeTurnHandledSkipsRemainingHooks() async throws {
        struct EarlyExitMiddleware: GnustoMiddleware {
            let stateKey = "early-exit"
            let priority = 100

            func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
                .handled(ActionResult("Turn intercepted!"))
            }
        }

        let tracker = GameLoopTrackingMiddleware()
        let earlyExit = EarlyExitMiddleware()

        let game = MinimalGame(middleware: [earlyExit, tracker])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        // EarlyExit has higher priority (100) than tracker (50), so when earlyExit
        // returns .handled, the middleware chain stops and tracker's beforeTurn
        // is never called. No other hooks should be called either.
        let sequence = await tracker.sequence
        #expect(sequence.isEmpty)

        await mockIO.expect(
            """
            Turn intercepted!
            """
        )
    }

    @Test("middleware hooks skip when beforeCommandExecution returns skip")
    func testBeforeCommandSkipPreventsExecution() async throws {
        struct CommandBlockingMiddleware: GnustoMiddleware {
            let stateKey = "command-blocker"
            let priority = 100

            func beforeCommandExecution(
                command: Command,
                context: MiddlewareContext
            ) async throws -> CommandMiddlewareResult {
                .skip(ActionResult("Command blocked by middleware!"))
            }
        }

        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let tracker = GameLoopTrackingMiddleware()
        let blocker = CommandBlockingMiddleware()

        let game = MinimalGame(
            items: testItem,
            middleware: [blocker, tracker]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take test item")

        // Blocker has higher priority (100) than tracker (50), so when blocker
        // returns .skip, the middleware chain stops and tracker's beforeCommandExecution
        // is never called. However, afterCommand is still called for all middleware.
        let sequence = await tracker.sequence
        #expect(sequence.contains("beforeTurn"))
        #expect(!sequence.contains("beforeCommandExecution"))  // Blocked by higher priority middleware
        #expect(sequence.contains("afterCommandExecution"))  // Still called even when command is skipped
        #expect(sequence.contains("beforeTimeAdvancement"))
        #expect(sequence.contains("afterTurn"))

        // Item should not have been taken
        let item = await engine.item("testItem")
        #expect(await item.parent != .player)

        await mockIO.expect(
            """
            > take test item
            Command blocked by middleware!
            """
        )
    }

    @Test("beforeTimeAdvancement prevents time from advancing")
    func testBeforeTimeAdvancementPreventsTimeTick() async throws {
        struct TimeBlockingMiddleware: GnustoMiddleware {
            let stateKey = "time-blocker"
            let priority = 100

            func beforeTimeAdvancement(
                context: MiddlewareContext
            ) async throws -> MiddlewareResult {
                .handled(ActionResult("Time advancement blocked!"))
            }
        }

        let blocker = TimeBlockingMiddleware()

        let game = MinimalGame(
            fuses: [
                "test-fuse": Fuse(initialTurns: 1) { engine, _ in
                    await ActionResult(
                        "Fuse fired!",
                        engine.setFlag("fuseTriggered")
                    )
                },
            ],
            middleware: [blocker]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        #expect(await engine.hasFlag("fuseTriggered") == false)

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            Time advancement blocked!
            """
        )
    }

    // MARK: - State Consistency Tests

    @Test("middleware observes consistent state throughout turn")
    func testMiddlewareStateConsistency() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .isTakable
            .in(.startRoom)

        let validator = StateValidatingMiddleware()

        let game = MinimalGame(
            items: testItem,
            middleware: [validator]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take test item")

        let checks = await validator.playerLocationChecks
        #expect(checks.count == 2)
        #expect(checks[0].contains("Laboratory"))
        #expect(checks[1].contains("Laboratory"))

        await mockIO.expect(
            """
            > take test item
            Taken.
            """
        )
    }

    @Test("middleware can modify commands before execution")
    func testMiddlewareCommandModification() async throws {
        let testItem = Item("testItem")
            .name("test item")
            .description("A simple test item.")
            .isTakable
            .in(.startRoom)

        let modifier = ActionModifyingMiddleware()

        let game = MinimalGame(
            items: testItem,
            middleware: [modifier]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take test item")

        // Command was modified from "take" to "examine"
        // So item should not be in player's inventory
        let item = await engine.item("testItem")
        #expect(await item.parent != .player)

        await mockIO.expect(
            """
            > take test item
            A simple test item.
            """
        )
    }

    @Test("middleware can add contextual messages to results")
    func testMiddlewareContextualMessages() async throws {
        let contextual = ContextualMessageMiddleware()

        let game = MinimalGame(middleware: [contextual])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            [You sense something strange in this laboratory.]
            """
        )
    }

    // MARK: - Multiple Middleware Tests

    @Test("multiple middleware execute in priority order")
    func testMultipleMiddlewarePriorityOrder() async throws {
        actor OrderRecorder {
            var order: [String] = []
            func record(_ id: String) {
                order.append(id)
            }
            var recorded: [String] { order }
        }

        struct OrderedMiddleware: GnustoMiddleware {
            let stateKey: String
            let priority: Int
            let recorder: OrderRecorder

            func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
                await recorder.record(stateKey)
                return .continue
            }
        }

        let recorder = OrderRecorder()

        let high = OrderedMiddleware(stateKey: "high", priority: 100, recorder: recorder)
        let medium = OrderedMiddleware(stateKey: "medium", priority: 50, recorder: recorder)
        let low = OrderedMiddleware(stateKey: "low", priority: 10, recorder: recorder)

        let game = MinimalGame(middleware: [medium, low, high])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        let order = await recorder.recorded
        #expect(order == ["high", "medium", "low"])

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("multiple middleware can chain result modifications")
    func testMultipleMiddlewareChainResults() async throws {
        struct MessageAppender: GnustoMiddleware {
            let stateKey: String
            let priority: Int
            let message: String

            func afterCommandExecution(
                command: Command,
                result: ActionResult,
                context: MiddlewareContext
            ) async throws -> ActionResult {
                result.appending(ActionResult("\n\n" + message))
            }
        }

        let first = MessageAppender(
            stateKey: "first",
            priority: 100,
            message: "[First middleware message]"
        )
        let second = MessageAppender(
            stateKey: "second",
            priority: 50,
            message: "[Second middleware message]"
        )
        let third = MessageAppender(
            stateKey: "third",
            priority: 10,
            message: "[Third middleware message]"
        )

        let game = MinimalGame(middleware: [first, second, third])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        try await engine.processTurn()

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            [First middleware message]

            [Second middleware message]

            [Third middleware message]

            >
            Farewell, brave soul!
            """
        )
    }

    // MARK: - Event System Tests

    @Test("middleware can implement event trigger system")
    func testMiddlewareEventTriggerSystem() async throws {
        let eventTrigger = EventTriggerMiddleware()

        let game = MinimalGame(middleware: [eventTrigger])

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            ioHandler: await MockIOHandler("look", "look")
        )

        // First turn - no event
        try await engine.execute("look")

        // Arm an event
        await eventTrigger.armEvent(message: "A mysterious figure appears!")

        // Second turn - event should trigger
        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            A mysterious figure appears!
            """
        )

        let events = await eventTrigger.triggeredEvents
        #expect(events.count == 1)
    }

    // MARK: - Statistics and Analytics Tests

    @Test("middleware can track game statistics")
    func testMiddlewareStatisticsTracking() async throws {
        let stats = StatisticsMiddleware()

        let game = MinimalGame(middleware: [stats])

        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("look", times: 3)

        #expect(await stats.turnCount == 3)
        #expect(await stats.commandCount == 3)
    }

    // MARK: - Parse Error Tests

    @Test("middleware hooks called even on parse errors")
    func testMiddlewareCalledOnParseErrors() async throws {
        let tracker = GameLoopTrackingMiddleware()
        let game = MinimalGame(middleware: [tracker])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("xyzzy invalid nonsense command")

        // beforeTurn, onParseError, and afterTurn should still be called
        let sequence = await tracker.sequence
        #expect(sequence.contains("beforeTurn"))
        #expect(sequence.contains("onParseError"))  // Called when parse fails
        #expect(sequence.contains("beforeTimeAdvancement"))
        #expect(sequence.contains("afterTurn"))

        // afterCommandExecution should NOT be called for parse errors
        #expect(!sequence.contains("afterCommandExecution"))

        await mockIO.expect(
            """
            > xyzzy invalid nonsense command
            The phrase 'invalid nonsense command' eludes my comprehension.
            """
        )
    }

    // MARK: - Multiple Turn Tests

    @Test("middleware state persists across multiple turns")
    func testMiddlewareStatePersistence() async throws {
        let stats = StatisticsMiddleware()
        let game = MinimalGame(middleware: [stats])
        let (engine, _) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        #expect(await stats.turnCount == 1)

        try await engine.execute("look")
        #expect(await stats.turnCount == 2)

        try await engine.execute("look")
        #expect(await stats.turnCount == 3)
    }

    // MARK: - Edge Cases

    @Test("middleware handles empty result modifications gracefully")
    func testMiddlewareEmptyResultModification() async throws {
        struct EmptyAppendingMiddleware: GnustoMiddleware {
            let stateKey = "empty-appender"
            let priority = 50

            func afterCommandExecution(
                command: Command,
                result: ActionResult,
                context: MiddlewareContext
            ) async throws -> ActionResult {
                // Append an empty result
                result.appending(ActionResult(message: nil, changes: [], effects: []))
            }
        }

        let middleware = EmptyAppendingMiddleware()

        let game = MinimalGame(middleware: [middleware])

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("middleware with no state key still functions")
    func testMiddlewareWithoutStateKey() async throws {
        struct StatelessMiddleware: GnustoMiddleware {
            let stateKey = ""  // Empty state key
            let priority = 50

            func afterCommandExecution(
                command: Command,
                result: ActionResult,
                context: MiddlewareContext
            ) async throws -> ActionResult {
                result.appending(ActionResult("\n\nStateless middleware ran."))
            }
        }

        let middleware = StatelessMiddleware()
        let game = MinimalGame(middleware: [middleware])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            Stateless middleware ran.
            """
        )
    }

    // MARK: - Integration with Game Features

    @Test("middleware integrates with fuse system")
    func testMiddlewareIntegrationWithFuses() async throws {
        let tracker = GameLoopTrackingMiddleware()
        let game = MinimalGame(
            fuses: [
                "test-fuse": Fuse(initialTurns: 1) { engine, _ in
                    await ActionResult(
                        "The fuse has been triggered!",
                        engine.setFlag("fuseTriggered")
                    )
                },
            ],
            middleware: [tracker]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.apply(
            .addActiveFuse(fuseID: "test-fuse", state: FuseState(turns: 1))
        )
        try await engine.execute("look")

        // Then
        // Fuse should fire after beforeTimeAdvancement
        #expect(await engine.hasFlag("fuseTriggered"))

        let sequence = await tracker.sequence
        let timeIndex = sequence.firstIndex(of: "beforeTimeAdvancement") ?? -1
        let turnIndex = sequence.firstIndex(of: "afterTurn") ?? -1
        #expect(timeIndex < turnIndex)  // Time advancement happens before afterTurn

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            The fuse has been triggered!
            """
        )
    }

    @Test("middleware integrates with daemon system")
    func testMiddlewareIntegrationWithDaemons() async throws {
        struct CounterPayload: Codable, Sendable, Equatable {
            var counter: Int
            var message: String
        }
        let initialPayload = CounterPayload(
            counter: 0,
            message: "Starting"
        )

        let statefulDaemon = Daemon(frequency: 2) { _, state in
            // Get current payload or create initial state
            var payload = state.getPayload(as: CounterPayload.self) ?? initialPayload

            // Update the counter and message
            payload.counter += 1
            payload.message = "Executed \(payload.counter) times"

            // Create new daemon state with updated payload
            let newState = try state.updatingPayload(payload)

            return ActionResult(
                "🤖 Daemon tick #\(payload.counter)",
                .updateDaemonState(
                    daemonID: "counterDaemon",
                    daemonState: newState
                )
            )
        }

        let tracker = GameLoopTrackingMiddleware()

        let game = MinimalGame(
            daemons: ["counterDaemon": statefulDaemon],
            middleware: [tracker]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.apply(
            .addActiveDaemon(
                daemonID: "counterDaemon",
                daemonState: DaemonState(payload: initialPayload)
            )
        )
        try await engine.execute("wait", times: 4)

        await mockIO.expect(
            """
            > wait
            Time flows onward, indifferent to your concerns.

            > wait
            The universe's clock ticks inexorably forward.

            🤖 Daemon tick #1

            > wait
            Moments slip away like sand through fingers.

            > wait
            The universe's clock ticks inexorably forward.

            🤖 Daemon tick #2
            """
        )
    }
}
