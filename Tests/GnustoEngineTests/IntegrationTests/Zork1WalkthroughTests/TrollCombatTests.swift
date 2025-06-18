import Testing
import GnustoEngine
@testable import Zork1

@Test("Troll blocks movement in troll room")
func testTrollBlocksMovement() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: mockIO)

    // Position player in troll room with live troll
    try await engine.teleportPlayer(to: .trollRoom)

    // When - try to go east (should be blocked)
    try await engine.processCommand("go east")

    // Then
    let output = await mockIO.flush()
    expectNoDifference(output, "The troll fends you off with a menacing gesture.")
}

@Test("Troll allows movement when dead")
func testTrollAllowsMovementWhenDead() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: mockIO)

    // Position player in troll room and kill troll
    try await engine.teleportPlayer(to: .trollRoom)
    try await engine.remove(.troll)

    // When - try to go east (should work now)
    try await engine.processCommand("go east")

    // Then - player should move successfully
    let currentLocation = await engine.playerLocation()
    #expect(currentLocation.id == .eastWestPassage)
}

@Test("Giving weapon to troll has random outcomes")
func testGivingWeaponToTroll() async throws {
    // Given
    let game = Zork1()
    let mockIO = await MockIOHandler()
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: mockIO)

    // Set up scenario: player has sword, is with troll
    try await engine.teleportPlayer(to: .trollRoom)
    try await engine.move(.sword, to: .player)

    // When - give sword to troll multiple times (testing randomness)
    var outcomes: [String] = []
    for _ in 0..<10 {
        // Reset state
        try await engine.move(.sword, to: .player)
        try await engine.clearFlag(.isFighting, on: .troll)

        try await engine.processCommand("give sword to troll")
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
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: MockIOHandler())

    // When - test different weapon types
    let swordEffective = await engine.isEffectiveWeapon(.sword)
    let knifeEffective = await engine.isEffectiveWeapon(.knife)
    let leafEffective = await engine.isEffectiveWeapon(.leaflet)

    // Then
    #expect(swordEffective == true, "Sword should be an effective weapon")
    #expect(knifeEffective == true, "Knife should be an effective weapon")
    #expect(leafEffective == false, "Leaflet should not be an effective weapon")
}

@Test("Combat outcomes follow ZIL patterns")
func testCombatOutcomePatterns() async throws {
    // Given
    let game = Zork1()
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: MockIOHandler())

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
    let engine = GameEngine(game: game, parser: StandardParser(vocabulary: game.vocabulary), ioHandler: MockIOHandler())

    // When & Then - test each outcome type
    let victoryResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .victory("Test victory")
    )
    #expect(victoryResult.message.contains("cloud of sinister black fog"))

    let drawResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .draw("Test draw")
    )
    #expect(drawResult.message.contains("circle each other warily"))

    let defeatResult = try await Troll.handleTrollCombatResponse(
        engine: engine,
        outcome: .defeat("Test defeat")
    )
    #expect(defeatResult.message.contains("stands over your fallen form"))
}
