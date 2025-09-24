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
            You drive in hard with your sword while the troll pivots with
            his bloody ax ready, both of you past the point of retreat.

            The nasty troll ducks under your elvish blade! His agility
            saves him from certain harm.

            The troll strikes back, his ax parting skin like paper. A line
            of fire traces across your body, followed by the warm rush of
            blood. First blood to them. The wound is real but manageable.

            > attack the troll with my sword
            You manage to graze the troll with your orcrist despite his
            axe, but barely break skin. He notes the minor damage and
            dismisses it.

            Then the troll breaks through with his bloody axe in a move
            that leaves you defenseless, your body a map of unprotected
            targets.

            > attack the troll with my sword
            The troll pulls back from your ancient sword! Doubt replaces
            his earlier confidence.

            The pathetic troll strikes back with his axe but misjudges
            badly, steel meeting nothing but its own momentum.

            > attack the troll with my sword
            The nasty troll reels from your sword! He stagger drunkenly,
            completely off-balance.

            The nasty troll strikes back, his ax parting skin like paper. A
            line of fire traces across your body, followed by the warm rush
            of blood. You grunt from the impact but maintain your stance.

            > attack the troll with my sword
            The troll pulls back from your ancient glamdring! Doubt
            replaces his earlier confidence.

            The nasty troll mistimes the attack completely! His bloody axe
            slips free and bounces out of reach.

            > attack the troll with my sword
            You drive your antique orcrist through the troll's guard,
            slicing through skin and drawing a line of fire across his
            body. The wound is real but manageable.

            The troll ends the exchange with his bloody axe buried deep,
            and you understand with perfect clarity that you will not rise
            again.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 350 points, in 5 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }
}
