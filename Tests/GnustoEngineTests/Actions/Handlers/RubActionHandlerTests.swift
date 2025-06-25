import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RubActionHandler Tests")
struct RubActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("RUB DIRECTOBJECT syntax works")
    func testRubDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub lamp
            You rub the brass lamp, but nothing happens.
            """)

        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("RUB DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testRubWithIndirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let cloth = Item(
            id: "cloth",
            .name("cleaning cloth"),
            .description("A soft cleaning cloth."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, cloth
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub table with cloth")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub table with cloth
            Rubbing the wooden table doesn’t accomplish anything.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("POLISH syntax works")
    func testPolishSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mirror = Item(
            id: "mirror",
            .name("silver mirror"),
            .description("A polished silver mirror."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mirror
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("polish mirror")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > polish mirror
            Rubbing the silver mirror doesn’t accomplish anything.
            """)
    }

    @Test("CLEAN syntax works")
    func testCleanSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let window = Item(
            id: "window",
            .name("dirty window"),
            .description("A window covered in grime."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: window
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("clean window")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > clean window
            Rubbing the dirty window doesn’t accomplish anything.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot rub without specifying what")
    func testCannotRubWithoutTarget() async throws {
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
        try await engine.execute("rub")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub
            Rub what?
            """)
    }

    @Test("Cannot rub non-existent item")
    func testCannotRubNonExistentItem() async throws {
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
        try await engine.execute("rub nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot rub item not in reach")
    func testCannotRubItemNotInReach() async throws {
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
            .name("distant statue"),
            .description("A statue in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: distantItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub statue
            You can’t see any such thing.
            """)
    }

    @Test("Cannot rub non-item")
    func testCannotRubNonItem() async throws {
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
        try await engine.execute("rub me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub me
            You can’t rub that.
            """)
    }

    @Test("Requires light to rub")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A carved stone statue."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub statue
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Rub character gives appropriate message")
    func testRubCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub wizard
            The old wizard might not like that.
            """)

        let finalState = try await engine.item("wizard")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub light source gives special message")
    func testRubLightSource() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lantern = Item(
            id: "lantern",
            .name("magical lantern"),
            .description("A mystical lantern."),
            .isLightSource,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub lantern
            You rub the magical lantern, but nothing happens.
            """)

        let finalState = try await engine.item("lantern")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub takable object")
    func testRubTakableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub coin
            Rubbing the gold coin doesn’t accomplish anything.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub generic object")
    func testRubGenericObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wall
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub wall
            Rubbing the stone wall doesn’t accomplish anything.
            """)

        let finalState = try await engine.item("wall")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub held item")
    func testRubHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A polished silver ring."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub ring")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub ring
            Rubbing the silver ring doesn’t accomplish anything.
            """)

        let finalState = try await engine.item("ring")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Rub with indirect object")
    func testRubWithIndirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let rag = Item(
            id: "rag",
            .name("old rag"),
            .description("A worn cleaning rag."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: vase, rag
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("rub vase with rag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > rub vase with rag
            Rubbing the ceramic vase doesn’t accomplish anything.
            """)

        let finalState = try await engine.item("vase")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = RubActionHandler()
        // RubActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = RubActionHandler()
        #expect(handler.verbs.contains(.rub))
        #expect(handler.verbs.contains(.polish))
        #expect(handler.verbs.contains(.clean))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = RubActionHandler()
        #expect(handler.requiresLight == true)
    }
}
