import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Fuse Tests")
struct FuseTests {

    // MARK: - FuseState Tests

    @Test("FuseState stores and retrieves typed payload correctly")
    func testFuseStateTypedPayload() throws {
        struct CustomPayload: Codable, Sendable, Equatable {
            let enemyID: ItemID
            let locationID: LocationID
            let damage: Int
            let isActive: Bool
        }

        let payload = CustomPayload(
            enemyID: ItemID("goblin"),
            locationID: LocationID("cave"),
            damage: 10,
            isActive: true
        )

        let state = try FuseState(turns: 5, payload: payload)

        #expect(state.turns == 5)
        #expect(state.hasPayload(ofType: CustomPayload.self))

        let retrievedPayload = state.getPayload(as: CustomPayload.self)
        #expect(retrievedPayload?.enemyID == ItemID("goblin"))
        #expect(retrievedPayload?.locationID == LocationID("cave"))
        #expect(retrievedPayload?.damage == 10)
        #expect(retrievedPayload?.isActive == true)
        #expect(retrievedPayload == payload)
    }

    @Test("FuseState predefined payload types work correctly")
    func testFuseStatePredefinedPayloadTypes() throws {
        // Test EnemyLocationPayload
        let enemyPayload = FuseState.EnemyLocationPayload(
            enemyID: ItemID("sword"),
            locationID: LocationID("dungeon"),
            message: "The sword gleams."
        )

        let enemyState = try FuseState(turns: 3, payload: enemyPayload)
        let retrievedEnemyPayload = enemyState.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(retrievedEnemyPayload?.enemyID == ItemID("sword"))
        #expect(retrievedEnemyPayload?.locationID == LocationID("dungeon"))
        #expect(retrievedEnemyPayload?.message == "The sword gleams.")

        // Test StatusEffectPayload
        let statusPayload = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .poisoned
        )

        let statusState = try FuseState(turns: 2, payload: statusPayload)
        let retrievedStatusPayload = statusState.getPayload(as: FuseState.StatusEffectPayload.self)
        #expect(retrievedStatusPayload?.itemID == ItemID("wizard"))
        #expect(retrievedStatusPayload?.effect == .poisoned)

        // Test cross-type access returns nil
        #expect(enemyState.getPayload(as: FuseState.StatusEffectPayload.self) == nil)
        #expect(statusState.getPayload(as: FuseState.EnemyLocationPayload.self) == nil)
    }

    @Test("Basic fuse scheduling works with typed payloads")
    func testBasicFuseSchedulingWithTypedPayloads() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create a custom payload for the fuse
        struct TestPayload: Codable, Sendable, Equatable {
            let effectType: String
            let severity: Int
        }

        let payload = TestPayload(effectType: "poison", severity: 2)

        // Schedule a fuse with typed payload
        let fuseState = try FuseState(turns: 3, payload: payload)
        let result = try ActionResult(
            effects: [
                .startFuse(
                    .statusEffectExpiry,
                    state: fuseState
                ),
            ]
        )
        try await engine.processActionResult(result)

        // Verify fuse was scheduled with correct payload
        let gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 1)

        let scheduledFuse = gameState.activeFuses[FuseID.statusEffectExpiry]
        #expect(scheduledFuse?.turns == 3)

        let retrievedPayload = scheduledFuse?.getPayload(as: TestPayload.self)
        #expect(retrievedPayload?.effectType == "poison")
        #expect(retrievedPayload?.severity == 2)
    }

    @Test("Scheduled fuse turn countdown preserves payload")
    func testFuseTurnCountdownPreservesPayload() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Lab.wizard
        let game = MinimalGame(locations: testRoom, items: wizard)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Schedule fuse with payload
        let payload = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .blessed
        )

        let fuseState = try FuseState(turns: 3, payload: payload)
        let result = try ActionResult(
            effects: [
                .startFuse(.statusEffectExpiry, state: fuseState)
            ]
        )
        try await engine.processActionResult(result)

        // Check countdown over turns while preserving payload
        for expectedTurns in [3, 2, 1] {
            let gameState = await engine.gameState
            let fuse = gameState.activeFuses[FuseID.statusEffectExpiry]
            #expect(fuse?.turns == expectedTurns)

            // Payload should be preserved throughout countdown
            let retrievedPayload = fuse?.getPayload(as: FuseState.StatusEffectPayload.self)
            #expect(retrievedPayload?.itemID == ItemID("wizard"))
            #expect(retrievedPayload?.effect == .blessed)

            if expectedTurns > 1 {
                try await engine.execute("wait")
            }
        }

        // Final turn should remove the fuse
        try await engine.execute("wait")
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[FuseID.statusEffectExpiry] == nil)
    }

    @Test("Multiple fuses with different payloads work independently")
    func testMultipleFusesWithDifferentPayloads() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Lab.wizard
        let game = MinimalGame(locations: testRoom, items: wizard)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create one payload type (EnvironmentalPayload was removed)
        let statusPayload = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .poisoned
        )

        // Schedule two fuses with different timing and payloads
        let result = try ActionResult(
            effects: [
                .startFuse(
                    .statusEffectExpiry,
                    state: try FuseState(turns: 1, payload: statusPayload)
                ),
            ]
        )
        try await engine.processActionResult(result)

        // Verify fuse scheduled with correct payload
        // Check fuse is scheduled
        var gameState = await engine.gameState

        let statusFuse = gameState.activeFuses[FuseID.statusEffectExpiry]

        #expect(statusFuse?.getPayload(as: FuseState.StatusEffectPayload.self) == statusPayload)

        // After 1 turn, first fuse should be gone, second should remain
        try await engine.execute("wait")

        // Fuse should be gone
        let gameState2 = await engine.gameState
        #expect(gameState2.activeFuses[FuseID.statusEffectExpiry] == nil)

        // After another turn, should be completely done
        gameState = await engine.gameState
        #expect(gameState.activeFuses.isEmpty)
    }

    @Test("Convenience constructors create correct payloads")
    func testConvenienceConstructors() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Lab.wizard
        let troll = Lab.troll
        let game = MinimalGame(locations: testRoom, items: wizard, troll)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test convenience constructors
        let enemyLocationState = try FuseState.enemyLocation(
            turns: 5,
            enemyID: ItemID("troll"),
            locationID: LocationID("startRoom"),
            message: "The troll is awake!"
        )

        let statusEffectState = try FuseState.statusEffect(
            turns: 3,
            itemID: ItemID("wizard"),
            effect: .terrified
        )

        // Schedule all three fuses
        let result = try ActionResult(
            effects: [
                .startFuse(.enemyWakeUp, state: enemyLocationState),
                .startFuse(.statusEffectExpiry, state: statusEffectState),
            ]
        )
        try await engine.processActionResult(result)

        let gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 2)

        // Verify enemy location fuse
        let enemyFuse = gameState.activeFuses[FuseID.enemyWakeUp]
        #expect(enemyFuse?.turns == 5)
        let enemyPayload = enemyFuse?.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(enemyPayload?.enemyID == ItemID("troll"))
        #expect(enemyPayload?.locationID == LocationID("startRoom"))
        #expect(enemyPayload?.message == "The troll is awake!")

        // Verify status effect fuse
        let statusFuse = gameState.activeFuses[FuseID.statusEffectExpiry]
        #expect(statusFuse?.turns == 3)
        let statusPayload = statusFuse?.getPayload(as: FuseState.StatusEffectPayload.self)
        #expect(statusPayload?.itemID == ItemID("wizard"))
        #expect(statusPayload?.effect == .terrified)
    }

    @Test("Custom turns override work with typed payloads")
    func testCustomTurnsOverrideWithTypedPayloads() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Lab.troll
        let game = MinimalGame(locations: testRoom, items: troll)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create fuse with custom turns (7 instead of default)
        let fuseState = try FuseState.enemyLocation(
            turns: 7,
            enemyID: ItemID("troll"),
            locationID: LocationID("startRoom"),
            message: "The troll awakens!"
        )

        let result = try ActionResult(
            effects: [
                .startFuse(.enemyWakeUp, state: fuseState)
            ]
        )
        try await engine.processActionResult(result)

        // Verify custom turns are used
        let gameState = await engine.gameState
        let scheduledFuse = gameState.activeFuses[FuseID.enemyWakeUp]
        #expect(scheduledFuse?.turns == 7)

        // Verify payload is still correct
        let payload = scheduledFuse?.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(payload?.enemyID == ItemID("troll"))
        #expect(payload?.locationID == LocationID("startRoom"))
        #expect(payload?.message == "The troll awakens!")
    }

    @Test("Fuse without payload works correctly")
    func testFuseWithoutPayload() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Create fuse without payload
        let fuseState = FuseState(turns: 3)
        let result = try ActionResult(
            effects: [
                .startFuse(.statusEffectExpiry, state: fuseState)
            ]
        )
        try await engine.processActionResult(result)

        // Verify fuse scheduled without payload
        let gameState = await engine.gameState
        let scheduledFuse = gameState.activeFuses[FuseID.statusEffectExpiry]
        #expect(scheduledFuse?.turns == 3)
        #expect(scheduledFuse?.payload == nil)
        #expect(!(scheduledFuse?.hasPayload(ofType: String.self) ?? true))
    }

    @Test("Fuse state equality works with payloads")
    func testFuseStateEqualityWithPayloads() throws {
        let payload1 = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .blessed
        )

        let payload2 = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .blessed
        )

        let payload3 = FuseState.StatusEffectPayload(
            itemID: ItemID("wizard"),
            effect: .cursed
        )

        let fuse1 = try FuseState(turns: 3, payload: payload1)
        let fuse2 = try FuseState(turns: 3, payload: payload2)
        let fuse3 = try FuseState(turns: 3, payload: payload3)

        // Same payloads should be equal
        #expect(fuse1 == fuse2)

        // Different payloads should not be equal
        #expect(fuse1 != fuse3)
        #expect(fuse2 != fuse3)
    }

    @Test("Complex payload structures work in fuses")
    func testComplexPayloadStructuresInFuses() async throws {
        struct ComplexPayload: Codable, Sendable, Equatable {
            let id: String
            let items: [ItemID]
            let locations: [LocationID]
            let metadata: [String: String]
        }

        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let complexPayload = ComplexPayload(
            id: "complex-event",
            items: [ItemID("sword"), ItemID("shield"), ItemID("potion")],
            locations: [LocationID("cave"), LocationID("forest")],
            metadata: [
                "type": "multi-item-event",
                "priority": "high",
                "source": "spell",
            ]
        )

        let fuseState = try FuseState(turns: 4, payload: complexPayload)
        let result = try ActionResult(
            effects: [
                .startFuse(.statusEffectExpiry, state: fuseState)
            ]
        )
        try await engine.processActionResult(result)

        // Verify complex payload is preserved
        let gameState = await engine.gameState
        let scheduledFuse = gameState.activeFuses[FuseID.statusEffectExpiry]
        let retrievedPayload = scheduledFuse?.getPayload(as: ComplexPayload.self)

        #expect(retrievedPayload?.id == "complex-event")
        #expect(retrievedPayload?.items == [ItemID("sword"), ItemID("shield"), ItemID("potion")])
        #expect(retrievedPayload?.locations == [LocationID("cave"), LocationID("forest")])
        #expect(retrievedPayload?.metadata["type"] == "multi-item-event")
        #expect(retrievedPayload?.metadata["priority"] == "high")
        #expect(retrievedPayload?.metadata["source"] == "spell")
    }
}
