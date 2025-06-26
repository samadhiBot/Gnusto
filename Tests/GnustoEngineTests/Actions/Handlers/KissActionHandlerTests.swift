import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KISS DIRECTOBJECT syntax works")
    func testKissDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let princess = Item(
            id: "princess",
            .name("beautiful princess"),
            .description("A beautiful princess."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: princess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss princess")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss princess
            I don’t think the beautiful princess would like that.
            """)

        let finalState = try await engine.item("princess")
        #expect(finalState.hasFlag(.isTouched))
    }

    // MARK: - Validation Testing

    @Test("Cannot kiss without specifying target")
    func testCannotKissWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss
            Kiss what?
            """)
    }

    @Test("Cannot kiss target not in scope")
    func testCannotKissTargetNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remotePrincess = Item(
            id: "remotePrincess",
            .name("distant princess"),
            .description("A princess in another room."),
            .isCharacter,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remotePrincess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss princess")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss princess
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to kiss")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let stranger = Item(
            id: "stranger",
            .name("mysterious stranger"),
            .description("A mysterious stranger."),
            .isCharacter,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: stranger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss stranger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss stranger
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Kiss self gives appropriate message")
    func testKissSelfGivesAppropriateMessage() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss me
            If you insist.
            """)
    }

    @Test("Kiss friendly character")
    func testKissFriendlyCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let friend = Item(
            id: "friend",
            .name("old friend"),
            .description("A dear old friend."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: friend
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss friend")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss friend
            I don’t think the old friend would like that.
            """)

        let finalState = try await engine.item("friend")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Kiss hostile character")
    func testKissHostileCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let enemy = Item(
            id: "enemy",
            .name("angry troll"),
            .description("An angry troll."),
            .isCharacter,
            .isFighting,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: enemy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss troll
            I don’t think the angry troll would appreciate that.
            """)

        let finalState = try await engine.item("enemy")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Kiss inanimate object")
    func testKissInanimateObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A beautiful marble statue."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss statue
            How romantic!
            """)

        let finalState = try await engine.item("statue")
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Kiss sets touched flag on target")
    func testKissSetsTouchedFlagOnTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .description("A fluffy cat."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss cat")

        // Then: Verify state changes
        let finalState = try await engine.item("cat")
        #expect(finalState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss cat
            I don’t think the fluffy cat would like that.
            """)
    }

    @Test("Kiss multiple different targets")
    func testKissMultipleDifferentTargets() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let knight = Item(
            id: "knight",
            .name("brave knight"),
            .description("A brave knight."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let flower = Item(
            id: "flower",
            .name("red rose"),
            .description("A beautiful red rose."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: knight, flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss character
        try await engine.execute("kiss knight")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > kiss knight
            I don’t think the brave knight would like that.
            """)

        // When: Kiss object
        try await engine.execute("kiss rose")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > kiss rose
            How romantic!
            """)

        // Verify both items were touched
        let knightState = try await engine.item("knight")
        let flowerState = try await engine.item("flower")
        #expect(knightState.hasFlag(.isTouched))
        #expect(flowerState.hasFlag(.isTouched))
    }

    @Test("Kiss item held by player")
    func testKissItemHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let locket = Item(
            id: "locket",
            .name("golden locket"),
            .description("A golden locket."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: locket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss locket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss locket
            How romantic!
            """)

        let finalState = try await engine.item("locket")
        #expect(finalState.parent == .player)  // Still held by player
        #expect(finalState.hasFlag(.isTouched))
    }

    @Test("Kiss different character types")
    func testKissDifferentCharacterTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let dragon = Item(
            id: "dragon",
            .name("fierce dragon"),
            .description("A fierce dragon."),
            .isCharacter,
            .isFighting,
            .in(.location("testRoom"))
        )

        let fairy = Item(
            id: "fairy",
            .name("woodland fairy"),
            .description("A woodland fairy."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: merchant, dragon, fairy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss friendly character
        try await engine.execute("kiss merchant")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > kiss merchant
            I don’t think the traveling merchant would like that.
            """)

        // When: Kiss hostile character
        try await engine.execute("kiss dragon")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > kiss dragon
            I don’t think the fierce dragon would appreciate that.
            """)

        // When: Kiss another friendly character
        try await engine.execute("kiss fairy")

        // Then
        let output3 = await mockIO.flush()
        expectNoDifference(
            output3,
            """
            > kiss fairy
            I don’t think the woodland fairy would like that.
            """)

        // Verify all characters were touched
        let merchantState = try await engine.item("merchant")
        let dragonState = try await engine.item("dragon")
        let fairyState = try await engine.item("fairy")
        #expect(merchantState.hasFlag(.isTouched))
        #expect(dragonState.hasFlag(.isTouched))
        #expect(fairyState.hasFlag(.isTouched))
    }

    @Test("Kiss various objects gives romantic message")
    func testKissVariousObjectsGivesRomanticMessage() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mirror = Item(
            id: "mirror",
            .name("magic mirror"),
            .description("A magic mirror."),
            .in(.location("testRoom"))
        )

        let painting = Item(
            id: "painting",
            .name("beautiful painting"),
            .description("A beautiful painting."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mirror, painting
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss mirror
        try await engine.execute("kiss mirror")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > kiss mirror
            How romantic!
            """)

        // When: Kiss painting
        try await engine.execute("kiss painting")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > kiss painting
            How romantic!
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = KissActionHandler()
        // KissActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = KissActionHandler()
        #expect(handler.verbs.contains(.kiss))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KissActionHandler()
        #expect(handler.requiresLight == true)
    }
}
