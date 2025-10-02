import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

struct DaemonStateIntegrationTest {
    @Test("Daemon can maintain state between executions")
    func testDaemonStateIntegration() async throws {
        // Given: A daemon that tracks its execution count and maintains custom state
        struct CounterPayload: Codable, Sendable, Equatable {
            var counter: Int
            var message: String
        }

        let statefulDaemon = Daemon(frequency: 2) { _, state in
            // Get current payload or create initial state
            var payload =
                state.getPayload(as: CounterPayload.self)
                ?? CounterPayload(
                    counter: 0,
                    message: "Starting"
                )

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

        let game = MinimalGame(
            daemons: ["counterDaemon": statefulDaemon]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: We activate the daemon and advance time
        try await engine.processSideEffects([SideEffect.runDaemon("counterDaemon")])

        // Advance to turn 2 (daemon runs every 2 turns)
        try await engine.execute("wait")  // turn 1
        try await engine.execute("wait")  // turn 2 - daemon should run

        // Then: Daemon should have executed once
        await mockIO.expectOutput(
            """
            > wait
            Time flows onward, indifferent to your concerns.

            > wait
            The universe's clock ticks inexorably forward.

            🤖 Daemon tick #1
            """
        )

        let state1 = await engine.gameState
        let daemonState1 = state1.activeDaemons["counterDaemon"]!
        #expect(daemonState1.executionCount == 1)
        #expect(daemonState1.lastExecutionTurn == 2)

        let payload1 = daemonState1.getPayload(as: CounterPayload.self)!
        #expect(payload1.counter == 1)
        #expect(payload1.message == "Executed 1 times")

        // When: We advance time again
        try await engine.execute("wait")  // turn 3
        try await engine.execute("wait")  // turn 4 - daemon should run again

        // Then: Daemon should have executed twice with updated state
        await mockIO.expectOutput(
            """
            > wait
            Moments slip away like sand through fingers.

            > wait
            The universe's clock ticks inexorably forward.

            🤖 Daemon tick #2
            """
        )

        let state2 = await engine.gameState
        let daemonState2 = state2.activeDaemons["counterDaemon"]!
        #expect(daemonState2.executionCount == 2)
        #expect(daemonState2.lastExecutionTurn == 4)

        let payload2 = daemonState2.getPayload(as: CounterPayload.self)!
        #expect(payload2.counter == 2)
        #expect(payload2.message == "Executed 2 times")
    }

    @Test("Daemon state persists without payload updates")
    func testDaemonStatePersistenceWithoutPayload() async throws {
        let simpleDaemon = Daemon(frequency: 1) { _, _ in
            // Return nil for state to keep it unchanged
            ActionResult(message: "Simple tick")
        }

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: Location(id: .startRoom, .name("Test Room"), .inherentlyLit),
            daemons: [
                "simpleDaemon": simpleDaemon
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: We activate the daemon and advance time
        try await engine.processSideEffects([SideEffect.runDaemon("simpleDaemon")])

        try await engine.execute("wait")  // turn 1 - daemon should run

        // Then: Execution tracking should still work even without payload changes
        await mockIO.expectOutput(
            """
            > wait
            Time flows onward, indifferent to your concerns.

            Simple tick
            """
        )

        let state1 = await engine.gameState
        let daemonState1 = state1.activeDaemons["simpleDaemon"]!
        #expect(daemonState1.executionCount == 1)
        #expect(daemonState1.lastExecutionTurn == 1)
        #expect(daemonState1.payload == nil)

        // When: We advance time again
        try await engine.execute("wait")  // turn 2 - daemon should run again

        // Then: Execution tracking should increment
        await mockIO.expectOutput(
            """
            > wait
            The universe's clock ticks inexorably forward.

            Simple tick
            """
        )

        let state2 = await engine.gameState
        let daemonState2 = state2.activeDaemons["simpleDaemon"]!
        #expect(daemonState2.executionCount == 2)
        #expect(daemonState2.lastExecutionTurn == 2)
        #expect(daemonState2.payload == nil)
    }

    @Test("Multiple daemons maintain separate states")
    func testMultipleDaemonsSeparateStates() async throws {
        struct DaemonPayload: Codable, Sendable, Equatable {
            var name: String
            var count: Int
        }

        let daemon1 = Daemon(frequency: 1) { _, state in
            var payload =
                state.getPayload(as: DaemonPayload.self)
                ?? DaemonPayload(
                    name: "Alpha",
                    count: 0
                )
            payload.count += 10
            let newState = try state.updatingPayload(payload)
            return ActionResult(
                "Alpha: \(payload.count)",
                .updateDaemonState(
                    daemonID: "daemon1",
                    daemonState: newState
                )
            )
        }

        let daemon2 = Daemon(frequency: 1) { _, state in
            var payload =
                state.getPayload(as: DaemonPayload.self)
                ?? DaemonPayload(
                    name: "Beta",
                    count: 0
                )
            payload.count += 5
            let newState = try state.updatingPayload(payload)
            return ActionResult(
                "Beta: \(payload.count)",
                .updateDaemonState(
                    daemonID: "daemon2",
                    daemonState: newState
                )
            )
        }

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: Location(id: .startRoom, .name("Test Room"), .inherentlyLit),
            daemons: [
                "daemon1": daemon1,
                "daemon2": daemon2,
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: We activate both daemons and advance time
        try await engine.processSideEffects([
            SideEffect.runDaemon("daemon1"),
            SideEffect.runDaemon("daemon2"),
        ])

        try await engine.execute("wait")  // turn 1 - both should run

        // Then: Each daemon should maintain its own state
        let output = await mockIO.flush()
        #expect(output.contains("Alpha: 10"))  // We cannot predict whether Alpha
        #expect(output.contains("Beta: 5"))    // or Beta will come first.

        let finalState = await engine.gameState

        let daemon1State = finalState.activeDaemons["daemon1"]!
        let payload1 = daemon1State.getPayload(as: DaemonPayload.self)!
        #expect(payload1.name == "Alpha")
        #expect(payload1.count == 10)

        let daemon2State = finalState.activeDaemons["daemon2"]!
        let payload2 = daemon2State.getPayload(as: DaemonPayload.self)!
        #expect(payload2.name == "Beta")
        #expect(payload2.count == 5)
    }
}
