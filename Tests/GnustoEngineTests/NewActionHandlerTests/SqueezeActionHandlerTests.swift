import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SqueezeActionHandler Tests")
struct SqueezeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SQUEEZE DIRECTOBJECT syntax works")
    func testSqueezeDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let sponge = Item(
            id: "sponge",
            .name("wet sponge"),
            .description("A soggy wet sponge."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sponge
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze sponge")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze sponge
            You squeeze the wet sponge.
            """)

        let finalState = try await engine.item("sponge")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("COMPRESS syntax works")
    func testCompressSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bellows = Item(
            id: "bellows",
            .name("leather bellows"),
            .description("A set of leather bellows."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bellows
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("compress bellows")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > compress bellows
            You squeeze the leather bellows.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot squeeze without specifying what")
    func testCannotSqueezeWithoutTarget() async throws {
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
        try await engine.execute("squeeze")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze
            Squeeze what?
            """)
    }

    @Test("Cannot squeeze non-existent item")
    func testCannotSqueezeNonExistentItem() async throws {
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
        try await engine.execute("squeeze nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot squeeze item not in reach")
    func testCannotSqueezeItemNotInReach() async throws {
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

        let distantItem = Item(
            id: "distantItem",
            .name("distant pillow"),
            .description("A pillow in another room."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze pillow")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze pillow
            You can't see any such thing.
            """)
    }

    @Test("Cannot squeeze non-item")
    func testCannotSqueezeNonItem() async throws {
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
        try await engine.execute("squeeze me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze me
            You can't squeeze that.
            """)
    }

    @Test("Requires light to squeeze")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let cushion = Item(
            id: "cushion",
            .name("soft cushion"),
            .description("A soft, squishy cushion."),
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: cushion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze cushion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze cushion
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Squeeze character gives appropriate message")
    func testSqueezeCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .description("A soft, fluffy cat."),
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
        try await engine.execute("squeeze cat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze cat
            The fluffy cat probably wouldn't like that.
            """)

        let finalState = try await engine.item("cat")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze generic item")
    func testSqueezeGenericItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A squishy rubber ball."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze ball
            You squeeze the rubber ball.
            """)

        let finalState = try await engine.item("ball")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze held item")
    func testSqueezeHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let toy = Item(
            id: "toy",
            .name("squeaky toy"),
            .description("A small squeaky toy."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: toy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze toy")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze toy
            You squeeze the squeaky toy.
            """)

        let finalState = try await engine.item("toy")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze fixed object")
    func testSqueezeFixedObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A solid marble statue."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze statue
            You squeeze the marble statue.
            """)

        let finalState = try await engine.item("statue")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze container")
    func testSqueezeContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A soft leather bag."),
            .isTakable,
            .isContainer,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze bag
            You squeeze the leather bag.
            """)

        let finalState = try await engine.item("bag")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze multiple items sequentially")
    func testSqueezeMultipleItemsSequentially() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let pillow1 = Item(
            id: "pillow1",
            .name("red pillow"),
            .description("A soft red pillow."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let pillow2 = Item(
            id: "pillow2",
            .name("blue pillow"),
            .description("A soft blue pillow."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pillow1, pillow2
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - squeeze first pillow
        try await engine.execute("squeeze red pillow")

        // Then - verify first pillow was squeezed
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > squeeze red pillow
            You squeeze the red pillow.
            """)

        let finalPillow1 = try await engine.item("pillow1")
        #expect(finalPillow1.hasFlag(.isTouched) == true)

        // When - squeeze second pillow
        try await engine.execute("squeeze blue pillow")

        // Then - verify second pillow was squeezed
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > squeeze blue pillow
            You squeeze the blue pillow.
            """)

        let finalPillow2 = try await engine.item("pillow2")
        #expect(finalPillow2.hasFlag(.isTouched) == true)
    }

    @Test("Squeeze light source")
    func testSqueezeLightSource() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let torch = Item(
            id: "torch",
            .name("burning torch"),
            .description("A brightly burning torch."),
            .isTakable,
            .isLightSource,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze torch
            You squeeze the burning torch.
            """)

        let finalState = try await engine.item("torch")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = SqueezeActionHandler()
        // SqueezeActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = SqueezeActionHandler()
        #expect(handler.verbs.contains(.squeeze))
        #expect(handler.verbs.contains(.compress))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = SqueezeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
