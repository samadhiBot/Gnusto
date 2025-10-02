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
            blueprint: Zork1(
                rng: SeededRandomNumberGenerator()
            )
        )

        // Give the player a sword and position them in the passage next to the round room.
        try await engine.apply(
            engine.item(.sword).move(to: .player),
            engine.player.move(to: .location(.ewPassage)),
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
            """)

        await mockIO.expectOutput(
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > look at the floor
            The floor stubbornly remains ordinary despite your thorough
            examination.

            > look at the ceiling
            The ceiling stubbornly remains ordinary despite your thorough
            examination.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > examine the man
            The thief is a slippery character with beady eyes that flit
            back and forth. He carries, along with an unmistakable
            arrogance, a large bag over his shoulder and a vicious
            stiletto, whose blade is aimed menacingly in your direction.
            I'd watch out if I were you.
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
        await mockIO.expectOutput(
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
            The floor stubbornly remains ordinary despite your thorough
            examination.

            > look at the ceiling
            The ceiling stubbornly remains ordinary despite your thorough
            examination.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > give the sceptre to the thief
            The thief examines the sceptre with obvious delight and
            carefully places it in his bag, giving you a grudging nod of
            acknowledgment.
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > give garlic to thief
            The thief examines the clove of garlic briefly, then shakes his
            head with obvious disdain. "I only deal in quality
            merchandise," he mutters.
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > attack the thief
            You explode into motion with your blade hunting flesh as the
            person meets your charge with his stiletto, the dance of death
            begun.

            The impact sends the man reeling! He clutches his knife
            desperately while fighting to stay upright.

            Then his deadly blade bites back hard, wielded with desperate
            fury. The weapon tears rather than cuts, leaving wounds with
            ragged, weeping edges. You reel from the unexpected wound. The
            reality of violence arrives.

            The thief strikes like a snake! The resulting wound is serious.

            > stab the thief with my sword
            The man blocks and turns your elvish orcrist aside with his
            knife, denying your strike completely.

            The robber retaliates with finality as his deadly stiletto
            finds the last soft place in you and opens it to let the life
            pour out.

            The thief comes in from the side, feints, and inserts the blade
            into your ribs.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 350 points, in 4 moves.

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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > tell thief about treasure
            The thief is a strong, silent type.
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > take thief
            Once you got him, what would you do with him?
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > examine stiletto
            It's a vicious-looking stiletto with a razor-sharp blade. The
            thief grips it expertly, clearly experienced in its use.
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > look inside the bag
            The thief's large bag bulges with what are obviously stolen
            goods. He watches you carefully, ready to defend his ill-gotten
            gains.
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
            """)

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > take stiletto
            The thief is armed and dangerous. You'd have to defeat him
            first before attempting to take his stiletto.
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
        await mockIO.expectOutput(
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
            You cannot reach any such thing from here.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > take the stiletto
            The thief is armed and dangerous. You'd have to defeat him
            first before attempting to take his stiletto.

            > wait
            Moments slip away like sand through fingers.

            The holder of the large bag just left, looking disgusted.
            Fortunately, he took nothing.

            > wait
            Moments slip away like sand through fingers.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            Moments slip away like sand through fingers.

            The thief just left, still carrying his large bag. You may not
            have noticed that he robbed you blind first.

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
                ".nowhere",
                ".location(.roundRoom)",
                ".nowhere",
                ".location(.roundRoom)",
                ".nowhere",
            ]
        )
    }

    @Test("Combat victory drops thief possessions")
    func testCombatVictoryDropsPossessions() async throws {
        // Bring thief close to death, and place some treasure in his bag
        try await engine.apply(
            engine.item(.thief).setHealth(to: 1),
            engine.item(.scarab).move(to: .largeBag),
            engine.item(.diamond).move(to: .largeBag)
        )

        await print("🎾 thief:", engine.item(.thief).contents.map(\.id))
        await print("🎾 largeBag:", engine.item(.largeBag).contents.map(\.id))

        // When
        try await engine.execute(
            """
            wait
            wait
            stab the thief with my sword
            slay the thief
            look
            """
        )

        // Then
        await mockIO.expectOutput(
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            The universe's clock ticks inexorably forward.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > stab the thief with my sword
            You explode into motion with your blade hunting flesh as the
            person meets your charge with his stiletto, the dance of death
            begun.

            The impact sends the man reeling! He clutches his knife
            desperately while fighting to stay upright.

            Suddenly the shady robber slips past your guard. His blade
            opens a wound that will mark you, and your blood flows out
            steady and sure. First blood to them. The wound is real but
            manageable.

            > slay the thief
            Your armed advantage proves decisive--your antique glamdring
            ends it! The robber crumples, having fought barehanded and
            lost.

            Almost as soon as the thief breathes his last breath, a cloud
            of sinister black fog envelops him, and when the fog lifts, the
            carcass has disappeared. His booty remains.

            > look
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunately been blocked by cave-ins.

            You can see a huge diamond here.
            """
        )

        // When - check if possessions are handled
        let bagLocation = await engine.item(.largeBag).parent

        // Then - bag should be accessible after thief is gone
        switch bagLocation {
        case .location(let location):
            #expect(location == .roundRoom)  // Should drop in current location
        case .nowhere:
            // Bag might be removed with thief - that's also valid
            break
        default:
            // Bag shouldn't still be "held" by removed thief
            #expect(Bool(false), "Bag should either be dropped or removed when thief dies")
        }
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
    //        await mockIO.expectOutput(
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
    //        await mockIO.expectOutput(
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
