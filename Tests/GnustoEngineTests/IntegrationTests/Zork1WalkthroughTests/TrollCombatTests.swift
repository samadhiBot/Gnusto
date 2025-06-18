import CustomDump
import Testing

@testable import GnustoEngine
@testable import Zork1

@Test("Troll blocks movement in troll room")
func testTrollBlocksMovement() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: mockIO
    )

    // Position player in troll room with live troll
    try await engine.apply(
        await engine.movePlayer(to: .location(.trollRoom)),
    )

    // When - try to go east (should be blocked)
    await engine.execute(
        command: Command(
            verb: .go,
            direction: .east,
            rawInput: "go east"
        )
    )

    // Then
    let output = await mockIO.flush()
    expectNoDifference(output, "The troll fends you off with a menacing gesture.")
}

@Test("Troll allows movement when dead")
func testTrollAllowsMovementWhenDead() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: mockIO
    )

    // Position player in troll room and kill troll
    try await engine.apply(
        await engine.movePlayer(to: .location(.trollRoom)),
        try await engine.remove(.troll)
    )


    // When - try to go east (should work now)
    await engine.execute(
        command: Command(
            verb: .go,
            direction: .east,
            rawInput: "go east"
        )
    )

    // Then - player should move successfully
    #expect(await engine.playerLocationID == .eastWestPassage)
}

@Test("Giving weapon to troll has random outcomes")
func testGivingWeaponToTroll() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: mockIO
    )

    // Set up scenario: player has sword, is with troll
    try await engine.apply(
        await engine.movePlayer(to: .location(.trollRoom)),
        try await engine.move(.sword, to: .player)
    )

    // When - give sword to troll multiple times (testing randomness)
    var outcomes: [String] = []
    for _ in 0..<10 {
        // Reset state
        try await engine.apply(
            try await engine.move(.sword, to: .player),
            try await engine.clearFlag(.isFighting, on: .troll)
        )

        await engine.execute(
            command: Command(
                verb: .give,
                directObject: .item(.sword),
                indirectObject: .item(.troll),
                preposition: "to",
                rawInput: "give sword to troll"
            )
        )
        let output = await mockIO.flush()
        outcomes.append(output)
    }

    // Then - should have different outcomes due to randomness
    let uniqueOutcomes = Set(outcomes)
    #expect(uniqueOutcomes.count > 1, "Expected random outcomes, but got identical results")
}

@Test("Enhanced combat system evaluates weapon effectiveness")
func testWeaponEffectivenessEvaluation() async throws {
    // Given
    let game = Zork1()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: MockIOHandler()
    )

    // When - test different weapon types
    let swordEffective = await engine.isEffectiveWeapon(.sword)
    let knifeEffective = await engine.isEffectiveWeapon(.knife)
    let leafEffective = await engine.isEffectiveWeapon(.advertisement)

    // Then
    #expect(swordEffective == true, "Sword should be an effective weapon")
    #expect(knifeEffective == true, "Knife should be an effective weapon")
    #expect(leafEffective == false, "Leaflet should not be an effective weapon")
}

@Test("Combat outcomes follow ZIL patterns")
func testCombatOutcomePatterns() async throws {
    // Given
    let game = Zork1()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: MockIOHandler()
    )

    // When - evaluate weapon attack outcomes
    var outcomes: [CombatOutcome] = []
    for _ in 0..<50 {
        let outcome = try await Troll.evaluateWeaponAttack(engine: engine, weapon: .sword)
        outcomes.append(outcome)
    }

    // Then - should have distribution of different outcome types
    let victories = outcomes.filter {
        if case .victory = $0 { return true }
        return false
    }.count

    let draws = outcomes.filter {
        if case .draw = $0 { return true }
        return false
    }.count

    let defeats = outcomes.filter {
        if case .defeat = $0 { return true }
        return false
    }.count

    // Should have some of each type due to randomness
    #expect(victories > 0, "Should have some victories")
    #expect(draws > 0, "Should have some draws")
    #expect(defeats > 0, "Should have some defeats")
}

@Test("Troll responds appropriately to different combat outcomes")
func testTrollCombatResponses() async throws {
    // Given
    let game = Zork1()
    let engine = await GameEngine(
        blueprint: game,
        parser: StandardParser(),
        ioHandler: MockIOHandler()
    )

    // When & Then - test each outcome type
    let victoryResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .victory("Victory")
    )
    expectNoDifference(victoryResult.message, """
        Victory

        Almost as soon as the troll breathes his last breath, a cloud
        of sinister black fog envelops him, and when the fog lifts,
        the carcass has disappeared.
        """)

    let drawResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .draw("Draw")
    )
    expectNoDifference(drawResult.message, """
        Draw

        You both circle each other warily, weapons at the ready.
        """)

    let defeatResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .defeat("Defeat")
    )
    expectNoDifference(defeatResult.message, """
        Defeat

        The troll stands over your fallen form, grunting what might
        be satisfaction in his guttural tongue.
        """)
}
