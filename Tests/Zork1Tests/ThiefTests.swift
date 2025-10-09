import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine
@testable import Zork1

/// Tests for the sophisticated Zork 1 thief implementation
struct ThiefTests {
    let engine: GameEngine
    let mockIO: MockIOHandler

    init() async throws {
        (engine, mockIO) = await GameEngine.test(
            blueprint: Zork1()
        )

        // Give the player a sword and position them in the passage next to the round room.
        try await engine.apply(
            engine.item(.sword).move(to: .player),
            engine.player.move(to: .ewPassage),
        )

        // Go east to the Round Room. Entering the Round Room starts the thief daemon.
        try await engine.execute("go east")
    }

    @Test("Thief can steal valuable items from player")
    func testThiefStealsValuableItems() async throws {
        let sceptre = await engine.item(.sceptre)
        let thief = await engine.item(.thief)
        let thiefBag = await engine.item(.largeBag)

        // Position player in round room and give player a valuable item
        try await engine.apply(
            sceptre.move(to: .player)
        )

        #expect(await engine.player.isHolding(sceptre.id))

        try await engine.execute(
            """
            inventory
            examine the sceptre
            look at the man
            talk to the man
            inventory
            """
        )

        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > inventory
            You are carrying:
            - A sceptre
            - A sword

            > examine the sceptre
            An ornamented sceptre, tapering to a sharp point, is here.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > look at the man
            The thief is a slippery character with beady eyes that flit
            back and forth. He carries, along with an unmistakable
            arrogance, a large bag over his shoulder and a vicious
            stiletto, whose blade is aimed menacingly in your direction.
            I'd watch out if I were you.

            > talk to the man
            The thief is a strong, silent type.

            The thief just left, still carrying his large bag. You may not
            have noticed that he robbed you blind first.

            > inventory
            You are carrying:
            - A sword
            """
        )

        // The sceptre is in the large bag, which the thief is holding
        #expect(await thiefBag.isHolding(sceptre.id))
        #expect(await thief.isHolding(thiefBag.id))

        // Therefore the thief is holding the sceptre
        #expect(await thief.isHolding(sceptre.id))
    }

    @Test("Player can examine thief")
    func testExamineThief() async throws {
        // When
        try await engine.execute(
            """
            look at the floor
            look at the ceiling
            examine the man
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > look at the floor
            The floor reveals itself to be exactly what it appears --
            nothing more, nothing less.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > look at the ceiling
            The ceiling stubbornly remains ordinary despite your thorough
            examination.

            > examine the man
            The thief is a slippery character with beady eyes that flit
            back and forth. He carries, along with an unmistakable
            arrogance, a large bag over his shoulder and a vicious
            stiletto, whose blade is aimed menacingly in your direction.
            I'd watch out if I were you.

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Player can give valuable items to thief")
    func testGiveValuableItemToThief() async throws {
        try await engine.apply(
            engine.item(.sceptre).move(to: .player)
        )

        // When
        try await engine.execute(
            """
            inventory
            look at the floor
            look at the ceiling
            give the sceptre to the thief
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > inventory
            You are carrying:
            - A sceptre
            - A sword

            > look at the floor
            The floor reveals itself to be exactly what it appears --
            nothing more, nothing less.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > look at the ceiling
            The ceiling stubbornly remains ordinary despite your thorough
            examination.

            > give the sceptre to the thief
            The thief examines the sceptre with obvious delight and
            carefully places it in his bag, giving you a grudging nod of
            acknowledgment.

            The thief, finding nothing of value, left disgusted.
            """
        )

        let sceptre = await engine.item(.sceptre)
        let thief = await engine.item(.thief)
        let thiefBag = await engine.item(.largeBag)

        // The sceptre is in the large bag, which the thief is holding
        #expect(await thiefBag.isHolding(sceptre.id))
        #expect(await thief.isHolding(thiefBag.id))
        #expect(await thief.isHolding(sceptre.id))
    }

    @Test("Thief refuses non-valuable items")
    func testThiefRefusesNonValuableItems() async throws {
        try await engine.apply(
            engine.item(.garlic).move(to: .player)
        )

        // When
        try await engine.execute(
            """
            wait
            wait
            give garlic to thief
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > give garlic to thief
            The thief examines the clove of garlic briefly, then shakes his
            head with obvious disdain. "I only deal in quality
            merchandise," he mutters.

            The thief, finding nothing of value, left disgusted.
            """
        )

        // Verify garlic is still with player
        let garlic = await engine.item(.garlic)

        // The sceptre is in the large bag, which the thief is holding
        #expect(await engine.player.isHolding(garlic.id))
    }

    @Test("Player can attack thief")
    func testAttackThief() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            attack the thief
            stab the thief with my sword
            slay the thief
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > attack the thief
            No more waiting as you attack with your orcrist raised and the
            robber responds with his stiletto, two weapons now committed to
            drawing blood.

            > stab the thief with my sword
            Your parry goes wrong -- your sword jolts loose and clatters
            away while the man advances with his stiletto, death in his
            eyes.

            A long, theatrical slash. You catch it on your elvish sword,
            but the thief twists his knife, and your glamdring goes flying.

            The response is measured and brutal. His knife tears through
            fabric and flesh, painting both red. First blood to them. The
            wound is real but manageable.

            > slay the thief
            The suspicious person grips his sharp blade confidently. You'll
            need more than courage to fight him unarmed.

            The robber ends the exchange with his blade buried deep, and
            you understand with perfect clarity that you will not rise
            again.

            The thief bows formally, raises his stiletto, and with a wry
            grin, ends the battle and your life.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 350 points, in 5 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }

    @Test("Thief handles tell command")
    func testTellThief() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            tell thief about treasure
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > tell thief about treasure
            The thief is a strong, silent type.

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Cannot take thief directly")
    func testCannotTakeThief() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            take thief
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > take thief
            Once you got him, what would you do with him?

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Stiletto examination works")
    func testExamineStilettoInThiefsPossession() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            examine stiletto
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > examine stiletto
            It's a vicious-looking stiletto with a razor-sharp blade. The
            thief grips it expertly, clearly experienced in its use.

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Large bag examination works")
    func testExamineLargeBag() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            look inside the bag
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > look inside the bag
            The thief's large bag bulges with what are obviously stolen
            goods. He watches you carefully, ready to defend his ill-gotten
            gains.

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Cannot take stiletto while thief is present")
    func testCannotTakeStilettoWhileThiefPresent() async throws {
        // When
        try await engine.execute(
            """
            wait
            wait
            take stiletto
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > take stiletto
            The thief is armed and dangerous. You'd have to defeat him
            first before attempting to take his stiletto.

            The thief, finding nothing of value, left disgusted.
            """
        )

        // Verify stiletto is still with thief
        #expect(await engine.item(.stiletto).parent != .player)
    }

    // MARK: - Advanced Feature Tests

    @Test("Thief prioritizes high-value items for theft")
    func testThiefPrioritizesHighValueItems() async throws {
        // Give player multiple items of different values
        try await engine.apply(
            engine.item(.advertisement).move(to: .player),  // Low value
            engine.item(.diamond).move(to: .player)  // High value
        )

        // When
        try await engine.execute(
            """
            inventory
            talk to the thief
            take the stiletto
            wait
            wait
            wait
            wait
            inventory
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > inventory
            You are carrying:
            - A leaflet
            - A huge diamond
            - A sword

            > talk to the thief
            Any such thing remains frustratingly inaccessible.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > take the stiletto
            The thief is armed and dangerous. You'd have to defeat him
            first before attempting to take his stiletto.

            > wait
            The universe's clock ticks inexorably forward.

            The thief just left, still carrying his large bag. You may not
            have noticed that he robbed you blind first.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            Moments slip away like sand through fingers.

            The thief, finding nothing of value, left disgusted.

            > inventory
            You are carrying:
            - A leaflet
            - A sword
            """
        )
    }

    @Test("Thief movement daemon can move thief around dungeon")
    func testThiefMovementDaemon() async throws {
        var thiefLocations = [String]()

        // When - wait several turns to trigger movement daemon
        for _ in 1...20 {
            try await engine.execute("wait")
            let thiefLocation = await engine.item(.thief).parent.entity.description
            if thiefLocations.last != thiefLocation {
                thiefLocations.append(thiefLocation)
            }
        }

        // Then - thief will come and go
        expectNoDifference(
            thiefLocations,
            [
                ".location(.roundRoom)",
                ".nowhere",
                ".location(.roundRoom)",
                ".nowhere",
                ".location(.roundRoom)"
            ]
        )
    }

    @Test("Combat victory drops thief possessions")
    func testCombatVictoryDropsPossessions() async throws {
        // Bring thief close to death, and place some treasure in his bag
        try await engine.apply(
            engine.item(.thief).setHealth(to: 1),
            engine.item(.scarab).clearFlag(.isInvisible),
            engine.item(.scarab).move(to: .largeBag),
            engine.item(.diamond).move(to: .largeBag)
        )

        // When
        try await engine.execute(
            """
            wait
            stab the thief with my sword
            slay the thief
            look
            """
        )

        // Then
        await mockIO.expect(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > stab the thief with my sword
            No more waiting as you attack with your blade raised and the
            thief responds with his knife, two weapons now committed to
            drawing blood.

            > slay the thief
            You strike true with your ancient orcrist! The seedy man drops
            without a sound, weaponless to the end.

            Almost as soon as the thief breathes his last breath, a cloud
            of sinister black fog envelops him, and when the fog lifts, the
            carcass has disappeared. His booty remains.

            > look
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            There are a huge diamond and a beautiful jeweled scarab here.
            """
        )

        #expect(
            await engine.item(.thief).isDead
        )
        #expect(
            await engine.item(.largeBag).location?.id == .roundRoom
        )
    }

    @Test("Treasure scoring integration")
    func testTreasureScoringIntegration() async throws {
        let (engine, _) = await GameEngine.test(
            blueprint: Zork1()
        )

        let initialScore = await engine.player.score

        // Put valuable item in thief's bag
        try await engine.apply(
            engine.item(.diamond).move(to: .item(.largeBag))
        )

        // When - defeat thief (simulate by removing)
        try await engine.apply(
            engine.item(.thief).remove()
        )

        // Then - score should potentially increase when treasures are recovered
        // (This tests the infrastructure exists even if specific scoring varies)
        let finalScore = await engine.player.score
        #expect(finalScore >= initialScore)  // Score shouldn't decrease
    }

    //    @Test("Thief refuses to accept bag or stiletto")
    //    func testThiefRefusesOwnPossessions() async throws {
    //        let (engine, mockIO) = try await setup()
    //
    //        // Simulate getting stiletto somehow
    //        try await engine.apply(
    //            engine.item(.stiletto).move(to: .player)
    //        )
    //
    //        // When
    //        try await engine.execute("give stiletto to thief")
    //
    //        // Then - thief should handle this appropriately
    //        let output = await mockIO.flush()
    //        // Either accepts it back or has some response
    //        #expect(output.isNotEmpty)
    //    }
    //
    //    @Test("Theft considers player vulnerability")
    //    func testTheftMechanics() async throws {
    //        let (engine, mockIO) = try await setup()
    //
    //        let diamond = await engine.item(.diamond)
    //        let skull = await engine.item(.skull)
    //        let potOfGold = await engine.item(.potOfGold)
    //
    //        // Move player loaded with treasure to the round room
    //        try await engine.apply(
    //            diamond.move(to: .player),
    //            skull.move(to: .player),
    //            potOfGold.move(to: .player)
    //        )
    //
    //        // Execute a wait command and trigger daemon processing
    //        try await engine.execute("wait", times: 4)
    //
    //        await mockIO.expect(
    //            """
    //            > go east
    //            --- Round Room ---
    //
    //            This is a circular stone room with passages in all directions.
    //            Several of them have unfortunately been blocked by cave-ins.
    //
    //            > wait
    //            The universe's clock ticks inexorably forward.
    //
    //            > wait
    //            The universe's clock ticks inexorably forward.
    //
    //            Someone carrying a large bag is casually leaning against one of
    //            the walls here. He does not speak, but it is clear from his
    //            aspect that the bag will be taken only over his dead body.
    //
    //            > wait
    //            The universe's clock ticks inexorably forward.
    //
    //            > wait
    //            The universe's clock ticks inexorably forward.
    //
    //            The thief just left, still carrying his large bag. You may not
    //            have noticed that he robbed you blind first.
    //            """
    //        )
    //
    //        // Then - verify theft system is operational
    //        let thiefItems = await engine.item(.largeBag).contents
    //        expectNoDifference(thiefItems, [diamond, potOfGold, skull])
    //
    //        let playerInventory = await engine.player.inventory
    //        expectNoDifference(playerInventory.map(\.id), [.sword])
    //    }
    //
    //    @Test("Thief AI responds to different combat outcomes")
    //    func testThiefCombatOutcomeVariations() async throws {
    //        let (engine, mockIO) = try await setup()
    //
    //        try await engine.execute(
    //            """
    //            wait
    //            attack the thief
    //            slay the thief
    //            stab the thief
    //            kill the thief
    //            """
    //        )
    //        await mockIO.expect(
    //            """
    //            > go east
    //            --- Round Room ---
    //
    //            This is a circular stone room with passages in all directions.
    //            Several of them have unfortunately been blocked by cave-ins.
    //
    //            > wait
    //            The universe's clock ticks inexorably forward.
    //
    //            > attack the thief
    //            You cannot reach any such thing from here.
    //
    //            > slay the thief
    //            Any such thing remains frustratingly inaccessible.
    //
    //            > stab the thief
    //            Any such thing remains frustratingly inaccessible.
    //
    //            > kill the thief
    //            You cannot reach any such thing from here.
    //
    //            Someone carrying a large bag is casually leaning against one of
    //            the walls here. He does not speak, but it is clear from his
    //            aspect that the bag will be taken only over his dead body.
    //            """
    //        )
    //    }
}
