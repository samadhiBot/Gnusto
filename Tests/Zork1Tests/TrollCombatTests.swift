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
            No more waiting as you attack with your sword raised and the
            troll responds with his ax, two weapons now committed to
            drawing blood.

            The nasty troll evades your blade with a fluid sidestep,
            managing to stay just out of reach.

            Suddenly the troll slips past your guard. His ax opens a wound
            that will mark you, and your blood flows out steady and sure.
            The blow lands solidly, drawing blood. You feel the sting but
            remain strong.

            > attack the troll with my sword
            Your strike with your orcrist glances off his axe, still
            managing to catch the troll lightly. The light wound barely
            seems to register.

            The troll's retaliation with his axe tears through your guard,
            and in an instant you're completely exposed.

            > attack the troll with my sword
            Your ancient sword gives the troll serious pause! Unarmed, he
            suddenly questions this confrontation.

            The pathetic troll's counter with his bloody axe misses
            completely, the weapon whistling through empty space.

            > attack the troll with my sword
            The blow lands hard! The nasty troll stumbles sideways,
            defenseless and struggling to stay on his feet.

            Suddenly the nasty troll slips past your guard. His bloody ax
            opens a wound that will mark you, and your blood flows out
            steady and sure. The strike hurts, but your body absorbs it.
            You remain dangerous.

            > attack the troll with my sword
            Your ancient glamdring gives the troll serious pause! Unarmed,
            he suddenly questions this confrontation.

            Overextending badly, the nasty troll fumbles his bloody axe! It
            clatters away while you circle for advantage.

            > attack the troll with my sword
            Your strike with your antique orcrist beats aside his ax,
            tearing through clothing and skin alike. The blow lands
            solidly, drawing blood. He feels the sting but remains strong.

            The troll's counter drives his axe through something vital and
            you feel yourself emptying onto the ground in warm, spreading
            pools.

            ****  You have died  ****

            The curtain falls on this particular act of your existence. But
            all good stories deserve another telling...

            You scored 0 out of a possible 350 points, in 5 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }
}
