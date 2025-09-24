import CustomDump
import GnustoEngine
import Testing

@testable import Zork1

/// Tests for the Zork 1 troll implementation
struct Zork1TrollCombatTests {
    @Test("Troll blocks movement in troll room")
    func testTrollBlocksMovement() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.zork1()

        // Position player in troll room with live troll
        try await engine.apply(
            engine.player.move(to: .location(.trollRoom)),
        )

        // When - try to go east (should be blocked)
        try await engine.execute("go east")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            The troll fends you off with a menacing gesture.
            """
        )
    }

    @Test("Troll allows movement when dead")
    func testTrollAllowsMovementWhenDead() async throws {
        // Given
        let (engine, _) = await GameEngine.zork1()

        // Position player in troll room and kill troll
        try await engine.apply(
            engine.player.move(to: .location(.trollRoom)),
            await engine.item(.troll).remove()
        )

        // When - try to go east (should work now)
        try await engine.execute("go east")

        // Then - player should move successfully
        #expect(await engine.player.location == .eastWestPassage)
    }

    @Test("Giving weapon to troll has random outcomes")
    func testGivingWeaponToTroll() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.zork1()

        // Set up scenario: player has sword, is with troll
        try await engine.apply(
            engine.player.move(to: .location(.trollRoom)),
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
        // Given
        let (engine, _) = await GameEngine.zork1()

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
        // Given
        let (engine, mockIO) = await GameEngine.zork1()

        try await engine.apply(
            engine.player.move(to: .location(.trollRoom)),
            engine.item(.sword).move(to: .player)
        )

        // When - give sword to troll
        try await engine.execute("give sword to troll")

        // Then - should get a combat-related response
        let output = await mockIO.flush()
        expectNoDifference(
            output,
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
        // Given
        let (engine, mockIO) = await GameEngine.zork1()

        try await engine.apply(
            engine.player.move(to: .location(.trollRoom)),
            engine.location(.trollRoom).setFlag(.isLit),
            engine.item(.sword).move(to: .player)
        )

        // When - give sword to troll (which triggers combat)
        try await engine.execute("attack the troll with my sword", times: 6)

        // Then - should get a response related to troll combat
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the troll with my sword
            Your blood sings as your sword cuts toward the nasty troll who
            barely gets his bloody ax into position before impact.

            The troll weaves past your ancient orcrist! Pure reflexes keep
            him safe from your strike.

            Suddenly the pathetic troll slips past your guard. His axe
            opens a wound that will mark you, and your blood flows out
            steady and sure. First blood to them. The wound is real but
            manageable.

            > attack the troll with my sword
            Your orcrist clips the troll, leaving a shallow cut. The light
            wound barely seems to register.

            Then his bloody axe finds purchase in your flesh. The wound
            opens clean, blood welling dark and constant. The strike hurts,
            but your body absorbs it. You remain dangerous.

            > attack the troll with my sword
            Your glamdring passes harmlessly past the pathetic troll, who
            readies his axe for a counter.

            The troll finishes the battle, his bloody ax doing its work
            with mechanical precision as the cold rushes in to replace
            everything warm.

            ****  You have died  ****

            Your story ends here, but death is merely an intermission in
            the grand performance.

            You scored 0 out of a possible 350 points, in 2 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }
}
