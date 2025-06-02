import Testing
import Foundation

@testable import GnustoEngine

@Suite("GameEngine Side Effects Tests")
struct GameEngineSideEffectsTests {

    // MARK: - Test Data

    private let testFuseID: FuseID = "testBomb"
    private let testDaemonID: DaemonID = "testClock"
    private let anotherFuseID: FuseID = "delayedMessage" 
    private let anotherDaemonID: DaemonID = "backgroundMusic"

    // MARK: - Helper Methods

    private func createTestEngine() async -> GameEngine {
        let testFuseDefinition = FuseDefinition(
            id: testFuseID,
            initialTurns: 3
        ) { engine in
            // Test fuse action - just set a flag to indicate it fired
            if let change = await engine.setFlag("fuseExploded") {
                try? await engine.apply(change)
            }
        }

        let testDaemonDefinition = DaemonDefinition(
            id: testDaemonID
        ) { engine in
            // Test daemon action - increment a counter
            let change = await engine.adjustGlobal("daemonTicks", by: 1)
            try? await engine.apply(change)
        }

        let anotherFuseDefinition = FuseDefinition(
            id: anotherFuseID,
            initialTurns: 5
        ) { engine in
            // Another test fuse action
            if let change = await engine.setFlag("messageDelivered") {
                try? await engine.apply(change)
            }
        }

        let anotherDaemonDefinition = DaemonDefinition(
            id: anotherDaemonID
        ) { engine in
            // Another test daemon action
            if let change = await engine.setFlag("musicPlaying") {
                try? await engine.apply(change)
            }
        }

        let timeRegistry = TimeRegistry(
            fuseDefinitions: [
                testFuseDefinition,
                anotherFuseDefinition
            ],
            daemonDefinitions: [
                testDaemonDefinition,
                anotherDaemonDefinition
            ]
        )

        let gameBlueprint = MinimalGame(timeRegistry: timeRegistry)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        return await GameEngine(
            blueprint: gameBlueprint,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    // MARK: - Start Fuse Tests

    @Test("Start fuse side effect adds fuse to active fuses")
    func testStartFuseSideEffect() async throws {
        let engine = await createTestEngine()

        // Verify fuse is not initially active
        let initialState = await engine.gameState
        #expect(initialState.activeFuses[testFuseID] == nil)

        // Create and process start fuse side effect
        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID)
        )

        try await engine.processSideEffects([sideEffect])

        // Verify fuse is now active with default turns
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 3) // Default from definition
    }

    @Test("Start fuse side effect with custom turns parameter")
    func testStartFuseSideEffectWithCustomTurns() async throws {
        let engine = await createTestEngine()

        // Create side effect with custom turns
        let customTurns = 7
        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID),
            parameters: ["turns": .int(customTurns)]
        )

        try await engine.processSideEffects([sideEffect])

        // Verify fuse is active with custom turns
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == customTurns)
    }

    @Test("Start fuse side effect with undefined fuse throws error")
    func testStartUndefinedFuseThrowsError() async throws {
        let engine = await createTestEngine()
        
        let undefinedFuseID: FuseID = "nonExistentFuse"
        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(undefinedFuseID)
        )

        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects([sideEffect])
        }
    }

    @Test("Start fuse side effect overwrites existing active fuse")
    func testStartFuseSideEffectOverwritesExisting() async throws {
        let engine = await createTestEngine()

        // Start fuse with default turns
        let firstEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID)
        )
        try await engine.processSideEffects([firstEffect])

        // Verify first start
        let midState = await engine.gameState
        #expect(midState.activeFuses[testFuseID] == 3)

        // Start same fuse with different turns
        let secondEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID),
            parameters: ["turns": .int(10)]
        )
        try await engine.processSideEffects([secondEffect])

        // Verify overwrite
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 10)
    }

    // MARK: - Stop Fuse Tests

    @Test("Stop fuse side effect removes active fuse")
    func testStopFuseSideEffect() async throws {
        let engine = await createTestEngine()

        // Start a fuse first
        let startEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID)
        )
        try await engine.processSideEffects([startEffect])

        // Verify fuse is active
        let midState = await engine.gameState
        #expect(midState.activeFuses[testFuseID] == 3)

        // Stop the fuse
        let stopEffect = SideEffect(
            type: .stopFuse,
            targetID: .fuse(testFuseID)
        )
        try await engine.processSideEffects([stopEffect])

        // Verify fuse is no longer active
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == nil)
    }

    @Test("Stop fuse side effect on non-active fuse succeeds silently")
    func testStopNonActiveFuse() async throws {
        let engine = await createTestEngine()

        // Verify fuse is not active
        let initialState = await engine.gameState
        #expect(initialState.activeFuses[testFuseID] == nil)

        // Stop the non-active fuse (should not throw)
        let stopEffect = SideEffect(
            type: .stopFuse,
            targetID: .fuse(testFuseID)
        )

        try await engine.processSideEffects([stopEffect])

        // Should still not be active
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == nil)
    }

    // MARK: - Run Daemon Tests

    @Test("Run daemon side effect adds daemon to active daemons")
    func testRunDaemonSideEffect() async throws {
        let engine = await createTestEngine()

        // Verify daemon is not initially active
        let initialState = await engine.gameState
        #expect(!initialState.activeDaemons.contains(testDaemonID))

        // Run daemon
        let sideEffect = SideEffect(
            type: .runDaemon,
            targetID: .daemon(testDaemonID)
        )

        try await engine.processSideEffects([sideEffect])

        // Verify daemon is now active
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons.contains(testDaemonID))
    }

    @Test("Run daemon side effect with undefined daemon throws error")
    func testRunUndefinedDaemonThrowsError() async throws {
        let engine = await createTestEngine()
        
        let undefinedDaemonID: DaemonID = "nonExistentDaemon"
        let sideEffect = SideEffect(
            type: .runDaemon,
            targetID: .daemon(undefinedDaemonID)
        )

        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects([sideEffect])
        }
    }

    @Test("Run daemon side effect on already active daemon is idempotent")
    func testRunAlreadyActiveDaemon() async throws {
        let engine = await createTestEngine()

        // Run daemon first time
        let sideEffect = SideEffect(
            type: .runDaemon,
            targetID: .daemon(testDaemonID)
        )
        try await engine.processSideEffects([sideEffect])

        // Verify daemon is active
        let midState = await engine.gameState
        #expect(midState.activeDaemons.contains(testDaemonID))

        // Run daemon second time (should be idempotent)
        try await engine.processSideEffects([sideEffect])

        // Should still be active (no duplicate)
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons.contains(testDaemonID))
        #expect(finalState.activeDaemons.count == 1)
    }

    // MARK: - Stop Daemon Tests

    @Test("Stop daemon side effect removes active daemon")
    func testStopDaemonSideEffect() async throws {
        let engine = await createTestEngine()

        // Start daemon first
        let startEffect = SideEffect(
            type: .runDaemon,
            targetID: .daemon(testDaemonID)
        )
        try await engine.processSideEffects([startEffect])

        // Verify daemon is active
        let midState = await engine.gameState
        #expect(midState.activeDaemons.contains(testDaemonID))

        // Stop daemon
        let stopEffect = SideEffect(
            type: .stopDaemon,
            targetID: .daemon(testDaemonID)
        )
        try await engine.processSideEffects([stopEffect])

        // Verify daemon is no longer active
        let finalState = await engine.gameState
        #expect(!finalState.activeDaemons.contains(testDaemonID))
    }

    @Test("Stop daemon side effect on non-active daemon succeeds silently")
    func testStopNonActiveDaemon() async throws {
        let engine = await createTestEngine()

        // Verify daemon is not active
        let initialState = await engine.gameState
        #expect(!initialState.activeDaemons.contains(testDaemonID))

        // Stop the non-active daemon (should not throw)
        let stopEffect = SideEffect(
            type: .stopDaemon,
            targetID: .daemon(testDaemonID)
        )

        try await engine.processSideEffects([stopEffect])

        // Should still not be active
        let finalState = await engine.gameState
        #expect(!finalState.activeDaemons.contains(testDaemonID))
    }

    // MARK: - Schedule Event Tests

    @Test("Schedule event side effect logs warning for unimplemented feature")
    func testScheduleEventSideEffect() async throws {
        let engine = await createTestEngine()

        let sideEffect = SideEffect(
            type: .scheduleEvent,
            targetID: .global,
            parameters: [
                "event": .string("delayed_message"),
                "delay": .int(5)
            ]
        )

        // Should not throw - this feature just logs a warning
        try await engine.processSideEffects([sideEffect])

        // No state changes should occur for unimplemented scheduleEvent
        let finalState = await engine.gameState
        #expect(finalState.changeHistory.isEmpty)
    }

    // MARK: - Multiple Side Effects Tests

    @Test("Process multiple side effects in sequence")
    func testMultipleSideEffects() async throws {
        let engine = await createTestEngine()

        let sideEffects = [
            SideEffect(type: .startFuse, targetID: .fuse(testFuseID)),
            SideEffect(type: .startFuse, targetID: .fuse(anotherFuseID)),
            SideEffect(type: .runDaemon, targetID: .daemon(testDaemonID)),
            SideEffect(type: .runDaemon, targetID: .daemon(anotherDaemonID))
        ]

        try await engine.processSideEffects(sideEffects)

        // Verify all side effects were processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 3)
        #expect(finalState.activeFuses[anotherFuseID] == 5)
        #expect(finalState.activeDaemons.contains(testDaemonID))
        #expect(finalState.activeDaemons.contains(anotherDaemonID))
    }

    @Test("Side effects with mixed success and failure")
    func testMixedSideEffects() async throws {
        let engine = await createTestEngine()

        let sideEffects = [
            SideEffect(type: .startFuse, targetID: .fuse(testFuseID)), // Valid
            SideEffect(type: .runDaemon, targetID: .daemon(testDaemonID)), // Valid
            SideEffect(type: .startFuse, targetID: .fuse("invalidFuse")) // Invalid
        ]

        // Should throw on the invalid side effect
        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects(sideEffects)
        }

        // Verify that valid side effects before the failure were processed
        // (depends on processing order - currently they're processed sequentially)
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 3)
        #expect(finalState.activeDaemons.contains(testDaemonID))
    }

    // MARK: - Integration Tests with ActionResult

    @Test("Side effects from ActionResult are processed")
    func testActionResultWithSideEffects() async throws {
        let engine = await createTestEngine()

        // Create an ActionResult with side effects
        let actionResult = ActionResult(
            message: "The bomb timer starts ticking...",
            sideEffects: [
                SideEffect(type: .startFuse, targetID: .fuse(testFuseID)),
                SideEffect(type: .runDaemon, targetID: .daemon(testDaemonID))
            ]
        )

        // Process the action result directly (internal engine method)
        let success = try await engine.processActionResult(actionResult)
        #expect(success == true) // Should return true because there's a message

        // Verify side effects were processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 3)
        #expect(finalState.activeDaemons.contains(testDaemonID))
    }

    // MARK: - Error Cases Tests

    @Test("Invalid EntityID for side effect throws error")
    func testInvalidEntityIDForSideEffect() async throws {
        let engine = await createTestEngine()

        // Try to start a fuse with a daemon ID (wrong entity type)
        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .daemon(testDaemonID) // Wrong! Should be .fuse
        )

        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects([sideEffect])
        }
    }

    @Test("Invalid parameter types are handled gracefully")
    func testInvalidParameterTypes() async throws {
        let engine = await createTestEngine()

        // Start fuse with invalid parameter type for turns
        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID),
            parameters: ["turns": .string("not_a_number")] // Invalid type
        )

        // Should fall back to definition's initialTurns when parameter is wrong type
        try await engine.processSideEffects([sideEffect])

        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == 3) // Definition default
    }

    // MARK: - State Change History Tests

    @Test("Side effects create appropriate state changes in history")
    func testSideEffectsCreateStateChanges() async throws {
        let engine = await createTestEngine()

        let sideEffect = SideEffect(
            type: .startFuse,
            targetID: .fuse(testFuseID)
        )

        try await engine.processSideEffects([sideEffect])

        // Verify state change was recorded
        let history = await engine.changeHistory()
        #expect(history.count == 1)

        let change = history.first!
        #expect(change.entityID == .global)
        #expect(change.attribute == .addActiveFuse(fuseID: testFuseID, initialTurns: 3))
        #expect(change.newValue == .int(3))
    }

    // MARK: - Empty Side Effects Tests

    @Test("Processing empty side effects array succeeds")
    func testEmptySideEffectsArray() async throws {
        let engine = await createTestEngine()

        // Should not throw
        try await engine.processSideEffects([])

        // No changes should be made
        let finalState = await engine.gameState
        #expect(finalState.activeFuses.isEmpty)
        #expect(finalState.activeDaemons.isEmpty)
        #expect(finalState.changeHistory.isEmpty)
    }
} 
