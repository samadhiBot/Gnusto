import GnustoEngine
import GnustoTestSupport
import Testing

@testable import Zork1

/// Tests for the Zork 1 troll implementation
struct Zork1TrollCombatTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1()
        )
    }

    @Test("Troll blocks movement in troll room")
    func testTrollBlocksMovement() async throws {
        // Position player in troll room with live troll
        try await engine.apply(
            engine.player.move(to: .trollRoom),
        )

        // When - try to go east (should be blocked)
        try await engine.execute("go east")

        // Then
        await mockIO.expect(
            """
            > go east
            The troll fends you off with a menacing gesture.
            """
        )
    }

    @Test("Troll allows movement when dead")
    func testTrollAllowsMovementWhenDead() async throws {
        // Position player in troll room and kill troll
        try await engine.apply(
            engine.player.move(to: .trollRoom),
            await engine.item(.troll).remove()
        )

        // When - try to go east (should work now)
        try await engine.execute("go east")

        // Then - player should move successfully
        #expect(await engine.player.location == .eastWestPassage)
    }

    @Test("Giving weapon to troll has random outcomes")
    func testGivingWeaponToTroll() async throws {
        // Set up scenario: player has sword, is with troll
        try await engine.apply(
            engine.player.move(to: .trollRoom),
            await engine.item(.sword).move(to: .player)
        )

        // When - give sword to troll multiple times (testing randomness)
        var outcomes = [String]()
        for _ in 0..<10 {
            // Reset state
            try await engine.apply(
                engine.item(.sword).move(to: .player),
                engine.item(.troll).setCharacterAttributes(isFighting: false)
            )

            try await engine.execute("give sword to troll")
            let output = await mockIO.flush()
            outcomes.append(output)
        }

        // Then - should have different outcomes due to randomness
        let uniqueOutcomes = Set(outcomes)
        #expect(uniqueOutcomes.count > 1, "Expected random outcomes, but got identical results")
    }

    @Test("Enhanced combat system evaluates weapon effectiveness")
    func testWeaponEffectivenessEvaluation() async throws {
        // When - test different weapon effectiveness by checking flags
        let sword = await engine.item(.sword)
        let knife = await engine.item(.knife)
        let advertisement = await engine.item(.advertisement)

        let swordEffective = await sword.hasFlag(.isWeapon)
        let knifeEffective = await knife.hasFlag(.isWeapon)
        let leafEffective = await advertisement.hasFlag(.isWeapon)

        // Then
        #expect(swordEffective == true, "Sword should be an effective weapon")
        #expect(knifeEffective == true, "Knife should be an effective weapon")
        #expect(leafEffective == false, "Leaflet should not be an effective weapon")
    }

    @Test("Combat system handles weapon giving")
    func testWeaponGivingToCombat() async throws {
        try await engine.apply(
            engine.player.move(to: .trollRoom),
            engine.item(.sword).move(to: .player)
        )

        // When - give sword to troll
        try await engine.execute("give sword to troll")

        // Then - should get a combat-related response
        await mockIO.expect(
            """
            > give sword to troll
            The troll, who is not overly proud, graciously accepts the gift
            and, being for the moment sated, throws it back. Fortunately,
            the troll has poor control, and the sword falls to the floor.
            He does not look pleased.
            """
        )
    }

    @Test("Troll combat is functional")
    func testTrollCombat() async throws {
        try await engine.apply(
            engine.player.move(to: .trollRoom),
            engine.location(.trollRoom).setFlag(.isLit),
            engine.item(.sword).move(to: .player)
        )

        // When - give sword to troll (which triggers combat)
        try await engine.execute("attack the troll with my sword", times: 3)

        // Then - should get a response related to troll combat
        await mockIO.expect(
            """
            > attack the troll with my sword
            No more waiting as you attack with your sword raised and the
            troll responds with his ax, two weapons now committed to
            drawing blood.

            > attack the troll with my sword
            The nasty troll drops his guard completely! He's exposed and
            unable to defend against what comes next.

            The troll swings his bloody ax in response but you weave away,
            leaving the weapon to bite empty air.

            > attack the troll with my sword
            Your strike with your orcrist beats aside his ax, tearing
            through clothing and skin alike. He absorbs the hit, flesh
            suffering but endurance holding.

            The troll counters viciously with his axe but rage makes the
            strike wild, missing you entirely.
            """
        )
    }
}
