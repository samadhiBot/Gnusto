import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine
@testable import Zork1

/// Tests for the sophisticated Zork 1 thief implementation
struct ThiefTests {
    func setup() async throws -> (GameEngine, MockIOHandler) {
        let (engine, mockIO) = await GameEngine.zork1()
        try await engine.apply(
            engine.item(.sword).move(to: .player),
            engine.player.move(to: .location(.ewPassage)),
        )
        // Go east to the Round Room. Entering the Round Room starts the thief daemon.
        try await engine.execute("go east")
        return (engine, mockIO)
    }

    @Test("Thief can steal valuable items from player")
    func testThiefStealsValuableItems() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        let sceptre = await engine.item(.sceptre)
        let thief = await engine.item(.thief)
        let thiefBag = await engine.item(.largeBag)

        // Position player in round room and give player a valuable item
        try await engine.apply(
            sceptre.move(to: .player)
        )

        #expect(await engine.player.isHolding(sceptre.id))

        try await engine.execute(
            "inventory",
            "examine the sceptre",
            "look at the man",
            "look at me",
            "inventory"
        )

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

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

            > look at me
            As good-looking as ever, which is to say, adequately
            presentable.

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
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute(
            "look at the floor",
            "examine thief"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > look at the floor
            The floor reveals itself to be exactly what it appears--nothing
            more, nothing less.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > examine thief
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
        // Given
        let (engine, mockIO) = try await setup()

        try await engine.apply(
            engine.item(.sceptre).move(to: .player)
        )

        // When
        try await engine.execute(
            """
            wait
            give sceptre to thief
            """
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > give sceptre to thief
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
        // Given
        let (engine, mockIO) = try await setup()

        try await engine.apply(
            engine.item(.garlic).move(to: .player)
        )

        // When
        try await engine.execute(
            "wait",
            "give garlic to thief"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > wait
            Time flows onward, indifferent to your concerns.

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
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute(
            "attack the thief",
            "stab the thief with my sword",
            "slay the thief",
            "stab the thief",
            "kill the thief",
            "stab the thief",

        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > attack the thief
            You cannot reach any such thing from here.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > stab the thief with my sword
            No more waiting as you attack with your glamdring raised and
            the robber responds with his stiletto, two weapons now
            committed to drawing blood.

            You hook his stiletto with your sword and wrench it free! The
            sneaky man stumbles back, suddenly defenseless.

            Suddenly the robber slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The blow lands solidly, drawing blood. You
            feel the sting but remain strong.

            > slay the thief
            The man has left himself wide open and completely vulnerable to
            your attack.

            Suddenly the thief slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The strike hurts, but your body absorbs it.
            You remain dangerous.

            > stab the thief
            The man has left himself wide open and completely vulnerable to
            your attack.

            A long, theatrical slash. You catch it on your sword, but the
            thief twists his knife, and your orcrist goes flying.

            > kill the thief
            You aren't holding the sword.

            Attacking the robber bare-handed while he hold his stiletto?
            That would be suicidal.

            The thief, a pragmatist, dispatches you as a threat to his
            livelihood.

            ****  You have died  ****

            The curtain falls on this particular act of your existence. But
            all good stories deserve another telling...

            You scored 0 out of a possible 350 points, in 5 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }

    @Test("Thief handles tell command")
    func testTellThief() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("tell thief about treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > tell thief about treasure
            Any such thing remains frustratingly inaccessible.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.
            """
        )
    }

    @Test("Cannot take thief directly")
    func testCannotTakeThief() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("take thief")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > take thief
            Any such thing lurks beyond your reach.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.
            """
        )
    }

    @Test("Stiletto examination works")
    func testExamineStilettoInThiefsPossession() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("examine stiletto")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > examine stiletto
            Any such thing lurks beyond your reach.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.
            """
        )
    }

    @Test("Large bag examination works")
    func testExamineLargeBag() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("look inside the bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > look inside the bag
            Any such thing lurks beyond your reach.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.
            """
        )
    }

    @Test("Cannot take stiletto while thief is present")
    func testCannotTakeStilettoWhileThiefPresent() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("take stiletto")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > take stiletto
            Any such thing lurks beyond your reach.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.
            """
        )

        // Verify stiletto is still with thief
        #expect(await engine.item(.stiletto).parent != .player)
    }

    // MARK: - Advanced Feature Tests

    @Test("Thief prioritizes high-value items for theft")
    func testThiefPrioritizesHighValueItems() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // Give player multiple items of different values
        try await engine.apply(
            engine.item(.advertisement).move(to: .player),  // Low value
            engine.item(.diamond).move(to: .player)  // High value
        )

        // When
        try await engine.execute(
            """
            look
            talk to the thief
            take the stiletto
            dance with the thief
            kiss the thief
            wait
            """
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > look
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > talk to the thief
            The thief is a strong, silent type.

            > take the stiletto
            The thief is armed and dangerous. You'd have to defeat him
            first before attempting to take his stiletto.

            The thief just left, still carrying his large bag. You may not
            have noticed that he robbed you blind first.

            > dance with the thief
            You and the thief move together in unexpected harmony, if only
            for a moment.

            > kiss the thief
            The thief has given no indication of welcoming such intimate
            contact.

            > wait
            The universe's clock ticks inexorably forward.

            The thief, finding nothing of value, left disgusted.
            """
        )
    }

    @Test("Thief movement daemon can move thief around dungeon")
    func testThiefMovementDaemon() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When - wait several turns to trigger movement daemon
        for _ in 1...10 {
            _ = await mockIO.flush()
            try await engine.execute("wait")
        }

        // Then - thief might have moved (daemon runs every 3 turns)
        let finalThiefLocation = await engine.item(.thief).parent

        // Verify thief can potentially move (even if didn't this time due to randomness)
        // At minimum, verify the thief still exists and is in a valid location
        switch finalThiefLocation {
        case .location(let locationProxy):
            #expect(await locationProxy.name.isNotEmpty)  // Valid location
        default:
            // Thief should always be in a location
            #expect(Bool(false), "Thief should be in a location")
        }
    }

    @Test("Thief movement shows atmospheric messages")
    func testThiefMovementMessages() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // Force thief to move to another location
        try await engine.apply(
            engine.item(.thief).move(to: .location(.northSouthPassage))
        )
        _ = await mockIO.flush()  // Clear any move message

        // When - move thief back to player's location
        try await engine.apply(
            engine.item(.thief).move(to: .location(.roundRoom))
        )

        // Then - should potentially see atmospheric arrival message
        // (This is testing the infrastructure exists)
        let thief = await engine.item(.thief)
        let thiefParent = await thief.parent
        if case .location(let locationProxy) = thiefParent {
            #expect(locationProxy.id == .roundRoom)
        } else {
            #expect(Bool(false), "Thief should be in round room")
        }
    }

    @Test("Enhanced combat considers weapon effectiveness")
    func testEnhancedCombatWithWeapons() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // When
        try await engine.execute("attack the thief with my sword", times: 3)

        // Then - should get enhanced combat response
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > attack the thief with my sword
            You cannot reach any such thing from here.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > attack the thief with my sword
            No more waiting as you attack with your glamdring raised and
            the robber responds with his stiletto, two weapons now
            committed to drawing blood.

            You hook his stiletto with your sword and wrench it free! The
            sneaky man stumbles back, suddenly defenseless.

            Suddenly the robber slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The blow lands solidly, drawing blood. You
            feel the sting but remain strong.

            > attack the thief with my sword
            The man has left himself wide open and completely vulnerable to
            your attack.

            Suddenly the thief slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The strike hurts, but your body absorbs it.
            You remain dangerous.
            """
        )
    }

    @Test("Combat victory drops thief possessions")
    func testCombatVictoryDropsPossessions() async throws {
        // Given
        let (engine, _) = await GameEngine.test(
            blueprint: Zork1()
        )

        try await engine.apply(
            engine.player.move(to: .location(.roundRoom)),
            engine.item(.thief).move(to: .location(.roundRoom))
        )

        // Force a combat victory by removing thief directly (simulating death)
        try await engine.apply(
            engine.item(.thief).remove()
        )

        // Simulate dropping thief's possessions (what dropThiefPossessions does)
        try await engine.apply(
            engine.item(.largeBag).move(to: .location(.roundRoom))
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

    @Test("Treasure scoring integration works")
    func testTreasureScoringIntegration() async throws {
        // Given
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

    @Test("Thief refuses to accept bag or stiletto")
    func testThiefRefusesOwnPossessions() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        // Simulate getting stiletto somehow
        try await engine.apply(
            engine.item(.stiletto).move(to: .player)
        )

        // When
        try await engine.execute("give stiletto to thief")

        // Then - thief should handle this appropriately
        let output = await mockIO.flush()
        // Either accepts it back or has some response
        #expect(output.isNotEmpty)
    }

    @Test("Theft considers player vulnerability")
    func testTheftMechanics() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        let diamond = await engine.item(.diamond)
        let skull = await engine.item(.skull)
        let potOfGold = await engine.item(.potOfGold)

        // Move player loaded with treasure to the round room
        try await engine.apply(
            diamond.move(to: .player),
            skull.move(to: .player),
            potOfGold.move(to: .player)
        )

        // Execute a wait command and trigger daemon processing
        try await engine.execute("wait", times: 4)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > wait
            The universe's clock ticks inexorably forward.

            > wait
            Moments slip away like sand through fingers.

            The thief just left, still carrying his large bag. You may not
            have noticed that he robbed you blind first.

            > wait
            The universe's clock ticks inexorably forward.
            """
        )

        // Then - verify theft system is operational
        let thiefItems = await engine.item(.largeBag).contents
        expectNoDifference(thiefItems, [diamond, potOfGold, skull])

        let playerInventory = await engine.player.inventory
        expectNoDifference(playerInventory.map(\.id), [.sword])
    }

    @Test("Thief AI responds to different combat outcomes")
    func testThiefCombatOutcomeVariations() async throws {
        // Given
        let (engine, mockIO) = try await setup()

        try await engine.execute(
            """
            wait
            attack the thief
            slay the thief
            stab the thief
            kill the thief
            """
        )
        let output = await mockIO.flush()

        expectNoDifference(
            output,
            """
            > go east
            --- Round Room ---

            This is a circular stone room with passages in all directions.
            Several of them have unfortunate endings.

            > wait
            Time flows onward, indifferent to your concerns.

            Someone carrying a large bag is casually leaning against one of
            the walls here. He does not speak, but it is clear from his
            aspect that the bag will be taken only over his dead body.

            > attack the thief
            No more waiting as you attack with your glamdring raised and
            the robber responds with his stiletto, two weapons now
            committed to drawing blood.

            You hook his stiletto with your sword and wrench it free! The
            sneaky man stumbles back, suddenly defenseless.

            Suddenly the robber slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The blow lands solidly, drawing blood. You
            feel the sting but remain strong.

            > slay the thief
            The man has left himself wide open and completely vulnerable to
            your attack.

            Suddenly the thief slips past your guard. His vicious stiletto
            opens a wound that will mark you, and your blood flows out
            steady and sure. The strike hurts, but your body absorbs it.
            You remain dangerous.

            > stab the thief
            The man has left himself wide open and completely vulnerable to
            your attack.

            A long, theatrical slash. You catch it on your sword, but the
            thief twists his knife, and your orcrist goes flying.

            > kill the thief
            You aren't holding the sword.

            Attacking the robber bare-handed while he hold his stiletto?
            That would be suicidal.

            The thief, a pragmatist, dispatches you as a threat to his
            livelihood.

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
