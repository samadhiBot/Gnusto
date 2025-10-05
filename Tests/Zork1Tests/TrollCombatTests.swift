import CustomDump
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
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
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
            Your blood sings as your sword cuts toward the nasty troll who
            barely gets his bloody ax into position before impact.

            The troll uses his bloody ax to expertly block and nullify your
            sword, leaving you open.

            Suddenly the troll slips past your guard. His ax opens a wound
            that will mark you, and your blood flows out steady and sure.
            You absorb the hit, feeling flesh tear but knowing you can
            endure.

            > attack the troll with my sword
            Your glamdring bites into the troll despite his bloody ax,
            opening flesh that will need attention. The wound is real but
            manageable.

            Suddenly the troll slips past your guard. His axe opens a wound
            that will mark you, and your blood flows out steady and sure.
            The strike hurts, but your body absorbs it. You remain
            dangerous.

            > attack the troll with my sword
            You drive your elvish blade through the nasty troll's guard,
            slicing through skin and drawing a line of fire across his
            body. The wound stings sharply. He can take more, but not
            forever.

            The troll retaliates with finality as his axe finds the last
            soft place in you and opens it to let the life pour out.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 350 points, in 2 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }
}
