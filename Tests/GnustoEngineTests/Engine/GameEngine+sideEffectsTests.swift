import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Side Effects Tests")
struct GameEngineSideEffectsTests {

    // MARK: - Test Data

    private let testFuseID: FuseID = "testBomb"
    private let testDaemonID: DaemonID = "testClock"
    private let anotherFuseID: FuseID = "delayedMessage"
    private let anotherDaemonID: DaemonID = "backgroundMusic"

    // MARK: - Helper Methods

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        // Test fuse action - return ActionResult with side effect to set flag
        let testFuse = Fuse(initialTurns: 3) { _, _ in
            try ActionResult(
                message: "💥 The fuse exploded!",
                effects: [
                    .startFuse("globalFlag", turns: 1),
                ]
            )
        }

        // Test daemon action - increment a counter using state changes
        let testDaemon = Daemon { engine, _ in
            await ActionResult(
                "🕰️ Daemon tick",
                engine.adjustGlobal("daemonTicks", by: 1)
            )
        }

        // Another test fuse action - return state change via ActionResult
        let anotherFuse = Fuse(initialTurns: 5) { _, _ in
            ActionResult("💌 Message delivered!")
        }

        // Another test daemon action - return state change via ActionResult
        let anotherDaemon = Daemon { engine, _ in
            await ActionResult(
                "🎻 Music is playing",
                engine.setFlag("musicPlaying")
            )
        }

        let game = MinimalGame(
            fuses: [
                testFuseID: testFuse,
                anotherFuseID: anotherFuse,
            ],
            daemons: [
                testDaemonID: testDaemon,
                anotherDaemonID: anotherDaemon,
            ]
        )
        return await GameEngine.test(blueprint: game)
    }

    // MARK: - Start Fuse Tests

    @Test("Start fuse side effect adds fuse to active fuses")
    func testStartFuseSideEffect() async throws {
        let (engine, _) = await createTestEngine()

        // Verify fuse is not initially active
        let initialState = await engine.gameState
        #expect(initialState.activeFuses[testFuseID] == nil)

        // Create and process start fuse side effect
        let sideEffect = try SideEffect.startFuse(testFuseID)

        try await engine.processSideEffects([sideEffect])

        // Verify fuse is now active with default turns
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 3)  // Default from definition
    }

    @Test("Start fuse side effect with custom turns parameter")
    func testStartFuseSideEffectWithCustomTurns() async throws {
        let (engine, _) = await createTestEngine()

        // Create side effect with custom turns
        let customTurns = 7
        let sideEffect = try SideEffect.startFuse(testFuseID, turns: customTurns)

        try await engine.processSideEffects([sideEffect])

        // Verify fuse is active with custom turns
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == customTurns)
    }

    @Test("Start fuse side effect with undefined fuse throws error")
    func testStartUndefinedFuseThrowsError() async throws {
        let (engine, _) = await createTestEngine()

        let undefinedFuseID: FuseID = "nonExistentFuse"
        let sideEffect = try SideEffect.startFuse(undefinedFuseID)

        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects([sideEffect])
        }
    }

    @Test("Start fuse side effect overwrites existing active fuse")
    func testStartFuseSideEffectOverwritesExisting() async throws {
        let (engine, _) = await createTestEngine()

        // Start fuse with default turns
        let firstEffect = try SideEffect.startFuse(testFuseID)

        try await engine.processSideEffects([firstEffect])

        // Verify first start
        let midState = await engine.gameState
        #expect(midState.activeFuses[testFuseID]?.turns == 3)

        // Start same fuse with different turns
        let secondEffect = try SideEffect.startFuse(testFuseID, turns: 10)

        try await engine.processSideEffects([secondEffect])

        // Verify overwrite
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 10)
    }

    // MARK: - Stop Fuse Tests

    @Test("Stop fuse side effect removes active fuse")
    func testStopFuseSideEffect() async throws {
        let (engine, _) = await createTestEngine()

        // Start a fuse first
        let startEffect = try SideEffect.startFuse(testFuseID)

        try await engine.processSideEffects([startEffect])

        // Verify fuse is active
        let midState = await engine.gameState
        #expect(midState.activeFuses[testFuseID]?.turns == 3)

        // Stop the fuse
        let stopEffect = try SideEffect.stopFuse(testFuseID)
        try await engine.processSideEffects([stopEffect])

        // Verify fuse is no longer active
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == nil)
    }

    @Test("Stop fuse side effect on non-active fuse succeeds silently")
    func testStopNonActiveFuse() async throws {
        let (engine, _) = await createTestEngine()

        // Verify fuse is not active
        let initialState = await engine.gameState
        #expect(initialState.activeFuses[testFuseID] == nil)

        // Stop the non-active fuse (should not throw)
        let stopEffect = try SideEffect.stopFuse(testFuseID)

        try await engine.processSideEffects([stopEffect])

        // Should still not be active
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID] == nil)
    }

    // MARK: - Run Daemon Tests

    @Test("Run daemon side effect adds daemon to active daemons")
    func testRunDaemonSideEffect() async throws {
        let (engine, _) = await createTestEngine()

        // Verify daemon is not initially active
        let initialState = await engine.gameState
        #expect(initialState.activeDaemons[testDaemonID] == nil)

        // Run daemon
        let sideEffect = try SideEffect.runDaemon(testDaemonID)

        try await engine.processSideEffects([sideEffect])

        // Verify daemon is now active
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons[testDaemonID] != nil)
    }

    @Test("Run daemon side effect with undefined daemon throws error")
    func testRunUndefinedDaemonThrowsError() async throws {
        let (engine, _) = await createTestEngine()

        let undefinedDaemonID: DaemonID = "nonExistentDaemon"
        let sideEffect = try SideEffect.runDaemon(undefinedDaemonID)

        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects([sideEffect])
        }
    }

    @Test("Run daemon side effect on already active daemon is idempotent")
    func testRunAlreadyActiveDaemon() async throws {
        let (engine, _) = await createTestEngine()

        // Run daemon first time
        let sideEffect = try SideEffect.runDaemon(testDaemonID)
        try await engine.processSideEffects([sideEffect])

        // Verify daemon is active
        let midState = await engine.gameState
        #expect(midState.activeDaemons[testDaemonID] != nil)

        // Run daemon second time (should be idempotent)
        try await engine.processSideEffects([sideEffect])

        // Should still be active (no duplicate)
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons[testDaemonID] != nil)
        #expect(finalState.activeDaemons.count == 1)
    }

    // MARK: - Stop Daemon Tests

    @Test("Stop daemon side effect removes active daemon")
    func testStopDaemonSideEffect() async throws {
        let (engine, _) = await createTestEngine()

        // Start daemon first
        let startEffect = try SideEffect.runDaemon(testDaemonID)
        try await engine.processSideEffects([startEffect])

        // Verify daemon is active
        let midState = await engine.gameState
        #expect(midState.activeDaemons[testDaemonID] != nil)

        // Stop daemon
        let stopEffect = try SideEffect.stopDaemon(testDaemonID)
        try await engine.processSideEffects([stopEffect])

        // Verify daemon is no longer active
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons[testDaemonID] == nil)
    }

    @Test("Stop daemon side effect on non-active daemon succeeds silently")
    func testStopNonActiveDaemon() async throws {
        let (engine, _) = await createTestEngine()

        // Verify daemon is not active
        let initialState = await engine.gameState
        #expect(initialState.activeDaemons[testDaemonID] == nil)

        // Stop the non-active daemon (should not throw)
        let stopEffect = try SideEffect.stopDaemon(testDaemonID)

        try await engine.processSideEffects([stopEffect])

        // Should still not be active
        let finalState = await engine.gameState
        #expect(finalState.activeDaemons[testDaemonID] == nil)
    }

    // MARK: - Multiple Side Effects Tests

    @Test("Process multiple side effects in sequence")
    func testMultipleSideEffects() async throws {
        let (engine, _) = await createTestEngine()

        let effects = try [
            SideEffect.startFuse(testFuseID),
            SideEffect.startFuse(anotherFuseID),
            SideEffect.runDaemon(testDaemonID),
            SideEffect.runDaemon(anotherDaemonID),
        ]

        try await engine.processSideEffects(effects)

        // Verify all side effects were processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 3)
        #expect(finalState.activeFuses[anotherFuseID]?.turns == 5)
        #expect(finalState.activeDaemons[testDaemonID] != nil)
        #expect(finalState.activeDaemons[anotherDaemonID] != nil)
    }

    @Test("Side effects with mixed success and failure")
    func testMixedSideEffects() async throws {
        let (engine, _) = await createTestEngine()

        let effects = try [
            SideEffect.startFuse(testFuseID),  // Valid
            SideEffect.runDaemon(testDaemonID),  // Valid
            SideEffect.startFuse("invalidFuse"),  // Invalid
        ]

        // Should throw on the invalid side effect
        await #expect(throws: ActionResponse.self) {
            try await engine.processSideEffects(effects)
        }

        // Verify that valid side effects before the failure were processed
        // (depends on processing order - currently they're processed sequentially)
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 3)
        #expect(finalState.activeDaemons[testDaemonID] != nil)
    }

    // MARK: - Integration Tests with ActionResult

    @Test("Side effects from ActionResult are processed")
    func testActionResultWithSideEffects() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Create an ActionResult with side effects
        let actionResult = try ActionResult(
            message: "The bomb timer starts ticking...",
            effects: [
                SideEffect.startFuse(testFuseID),
                SideEffect.runDaemon(testDaemonID),
            ]
        )

        // Process the action result directly (internal engine method)
        try await engine.processActionResult(actionResult)

        let output = await mockIO.flush()
        expectNoDifference(output, "The bomb timer starts ticking...")

        // Verify side effects were processed
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 3)
        #expect(finalState.activeDaemons[testDaemonID] != nil)
    }

    // MARK: - Error Cases Tests

    @Test("Invalid parameter types are handled gracefully")
    func testInvalidParameterTypes() async throws {
        let (engine, _) = await createTestEngine()

        // Start fuse with default turns (no custom payload)
        let sideEffect = try SideEffect.startFuse(testFuseID)

        // Should fall back to definition's initialTurns when parameter is wrong type
        try await engine.processSideEffects([sideEffect])

        let finalState = await engine.gameState
        #expect(finalState.activeFuses[testFuseID]?.turns == 3)  // Definition default
    }

    // MARK: - State Change History Tests

    @Test("Side effects create appropriate state changes in history")
    func testSideEffectsCreateStateChanges() async throws {
        let (engine, _) = await createTestEngine()

        let sideEffect = try SideEffect.startFuse(testFuseID)

        try await engine.processSideEffects([sideEffect])

        // Verify state change was recorded
        let history = await engine.changeHistory
        #expect(history.count == 1)

        let change = history.first!
        if case .addActiveFuse(let fuseID, let fuseState) = change {
            #expect(fuseID == testFuseID)
            #expect(fuseState.turns == 3)
        } else {
            #expect(Bool(false), "Expected addActiveFuse case")
        }
    }

    // MARK: - Empty Side Effects Tests

    @Test("Processing empty side effects array succeeds")
    func testEmptySideEffectsArray() async throws {
        let (engine, _) = await createTestEngine()

        // Should not throw
        try await engine.processSideEffects([])

        // No changes should be made
        let finalState = await engine.gameState
        #expect(finalState.activeFuses.isEmpty)
        #expect(finalState.activeDaemons.isEmpty)
        #expect(finalState.changeHistory.isEmpty)
    }
}
