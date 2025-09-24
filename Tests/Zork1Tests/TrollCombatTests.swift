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

            The nasty troll has left himself wide open and completely
            vulnerable to your attack.

            The troll's retaliatory strike with his bloody ax cuts toward
            you but your body knows how to flow around death.

            > attack the troll with my sword
            Your strike with your elvish orcrist glances off his ax, still
            managing to catch the troll lightly. The light wound barely
            seems to register.

            The troll strikes back with his axe so savagely that you
            falter, uncertainty freezing your muscles for one crucial
            heartbeat.

            > attack the troll with my sword
            Your strike with your antique blade beats aside his bloody axe,
            tearing through clothing and skin alike. You see the ripple of
            pain, but his body absorbs it. He remains dangerous.

            Suddenly the troll slips past your guard. His bloody ax opens a
            wound that will mark you, and your blood flows out steady and
            sure. The blow lands solidly, drawing blood. You feel the sting
            but remain strong.

            > attack the troll with my sword
            You strike true with your glamdring! The troll drops without a
            sound, weaponless to the end.

            > attack the troll with my sword
            The troll stirs, quickly resuming a fighting stance.

            > attack the troll with my sword
            The troll stirs, quickly resuming a fighting stance.
            """
        )
    }
}
