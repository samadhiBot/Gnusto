import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Fuse Tests")
struct FuseTests {

    // MARK: - FuseState Tests

    @Test("FuseState stores and retrieves custom data correctly")
    func testFuseState() {
        let state = FuseState(
            turns: 5,
            state: [
                "enemyID": .string("goblin"),
                "locationID": .string("cave"),
                "damage": .int(10),
                "isActive": .bool(true),
            ]
        )

        #expect(state.turns == 5)
        #expect(state.getString("enemyID") == "goblin")
        #expect(state.getItemID("enemyID")?.rawValue == "goblin")
        #expect(state.getLocationID("locationID")?.rawValue == "cave")
        #expect(state.getInt("damage") == 10)
        #expect(state.getBool("isActive") == true)
        #expect(state.getString("nonexistent") == nil)
    }

    @Test("FuseState convenience accessors work correctly")
    func testFuseStateAccessors() {
        let state = FuseState(
            turns: 3,
            state: [
                "itemRef": .string("sword"),
                "locationRef": .string("dungeon"),
                "count": .int(42),
                "enabled": .bool(false),
                "missing": .string(""),
            ]
        )

        // Test successful conversions
        #expect(state.getItemID("itemRef")?.rawValue == "sword")
        #expect(state.getLocationID("locationRef")?.rawValue == "dungeon")
        #expect(state.getInt("count") == 42)
        #expect(state.getBool("enabled") == false)

        // Test failed conversions (wrong types)
        #expect(state.getInt("itemRef") == nil)
        #expect(state.getBool("count") == nil)
        #expect(state.getString("count") == nil)

        // Test missing keys
        #expect(state.getString("notThere") == nil)
        #expect(state.getItemID("notThere") == nil)
        #expect(state.getLocationID("notThere") == nil)
    }

    @Test("Basic fuse scheduling works")
    func testBasicFuseScheduling() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Schedule a basic event with custom state
        let result = ActionResult(
            .startFuse(
                .statusEffectExpiry,
                turns: 3,
                state: [
                    "effectType": .string("poison"),
                    "severity": .int(2),
                ]
            )
        )
        try await engine.processActionResult(result)

        // Verify event was scheduled with correct state
        let gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 1)

        let event = gameState.activeFuses[FuseID.statusEffectExpiry]
        #expect(event?.turns == 3)
        #expect(event?.getString("effectType") == "poison")
        #expect(event?.getInt("severity") == 2)
    }

    @Test("Scheduled event turn countdown works")
    func testFuseTurnCountdown() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Schedule event with 3 turns
        let result = ActionResult(
            effects: [
                .startFuse(
                    .statusEffectExpiry,
                    turns: 3,
                    state: ["test": .string("value")]
                )
            ]
        )
        try await engine.processActionResult(result)

        // Check countdown over turns
        for expectedTurns in [3, 2, 1] {
            let gameState = await engine.gameState
            let event = gameState.activeFuses[FuseID.statusEffectExpiry]
            #expect(event?.turns == expectedTurns)
            #expect(event?.getString("test") == "value")  // State preserved

            if expectedTurns > 1 {
                try await engine.execute("wait")
            }
        }

        // Final turn should remove the event
        try await engine.execute("wait")
        let finalState = await engine.gameState
        #expect(finalState.activeFuses[FuseID.statusEffectExpiry] == nil)
    }

    @Test("Multiple fuses work independently")
    func testMultipleFuses() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Schedule two events with different timing and state
        let result = ActionResult(
            effects: [
                .startFuse(
                    .statusEffectExpiry,
                    turns: 1,
                    state: ["type": .string("poison")]
                ),
                .startFuse(
                    .environmentalChange,
                    turns: 2,
                    state: ["weather": .string("rain")]
                ),
            ]
        )
        try await engine.processActionResult(result)

        // Verify both events scheduled
        var gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 2)

        // After 1 turn, first event should be gone
        try await engine.execute("wait")
        gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 1)
        #expect(gameState.activeFuses[FuseID.statusEffectExpiry] == nil)
        #expect(gameState.activeFuses[FuseID.environmentalChange] != nil)

        // After 2 turns, second event should be gone
        try await engine.execute("wait")
        gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 0)
    }

    @Test("Convenience methods create correct state")
    func testConvenienceMethods() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Test all convenience methods
        let result = ActionResult(
            effects: [
                .startEnemyWakeUpFuse(
                    enemyID: ItemID("orc"),
                    message: "The orc is awake!",
                    turns: 5
                ),
                .startEnemyReturnFuse(
                    enemyID: ItemID("dragon"),
                    to: LocationID("cave"),
                    message: "The dragon has returned!",
                    turns: 3
                ),
                .startStatusEffectExpiryFuse(
                    for: ItemID("player"),
                    effectName: "paralysis",
                    turns: 2
                ),
            ]
        )
        try await engine.processActionResult(result)

        let gameState = await engine.gameState
        #expect(gameState.activeFuses.count == 3)

        // Verify enemy wake-up event
        let wakeUpEvent = gameState.activeFuses[FuseID.enemyWakeUp]
        #expect(wakeUpEvent?.turns == 5)
        #expect(wakeUpEvent?.getString("enemyID") == "orc")

        // Verify enemy return event
        let returnEvent = gameState.activeFuses[FuseID.enemyReturn]
        #expect(returnEvent?.turns == 3)
        #expect(returnEvent?.getString("enemyID") == "dragon")
        #expect(returnEvent?.getString("locationID") == "cave")

        // Verify status effect event
        let statusEvent = gameState.activeFuses[FuseID.statusEffectExpiry]
        #expect(statusEvent?.turns == 2)
        #expect(statusEvent?.getString("itemID") == "player")
        #expect(statusEvent?.getString("effectName") == "paralysis")
    }

    @Test("Custom turns override default event turns")
    func testCustomTurnsOverride() async throws {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: testRoom)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Schedule with custom turns (default for enemyWakeUp would be 3, we use 7)
        let result = ActionResult(
            effects: [
                .startEnemyWakeUpFuse(
                    enemyID: ItemID("orc"),
                    message: "The orc awakens!",
                    turns: 7
                )
            ]
        )
        try await engine.processActionResult(result)

        // Verify custom turns are used
        let gameState = await engine.gameState
        #expect(gameState.activeFuses[FuseID.enemyWakeUp]?.turns == 7)
    }
}
