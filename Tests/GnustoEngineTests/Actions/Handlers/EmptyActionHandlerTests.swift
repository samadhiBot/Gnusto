import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EmptyActionHandler Tests")
struct EmptyActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EMPTY DIRECTOBJECT syntax works")
    func testEmptyDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty box
            You empty the wooden box: a gold coin.
            """)

        let finalBoxState = try await engine.item("box")
        let finalCoinState = try await engine.item("coin")
        #expect(finalBoxState.hasFlag(.isTouched) == true)
        #expect(finalCoinState.parent == .location("testRoom"))
    }

    @Test("EMPTY DIRECTOBJECT INTO INDIRECTOBJECT syntax works")
    func testEmptyIntoContainerSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let basket = Item(
            id: "basket",
            .name("wicker basket"),
            .description("A wicker basket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("red gem"),
            .description("A red gem."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, basket, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bag into basket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty bag into basket
            You empty the leather bag: a red gem.
            """)

        let finalGemState = try await engine.item("gem")
        #expect(finalGemState.parent == .location("testRoom"))
    }

    @Test("EMPTY OUT DIRECTOBJECT syntax works")
    func testEmptyOutDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sack = Item(
            id: "sack",
            .name("burlap sack"),
            .description("A burlap sack."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.item("sack"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sack, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty out sack")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty out sack
            You empty the burlap sack: a brass key.
            """)

        let finalKeyState = try await engine.item("key")
        #expect(finalKeyState.parent == .location("testRoom"))
    }

    @Test("DUMP syntax works")
    func testDumpSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A small pebble."),
            .isTakable,
            .in(.item("bucket"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bucket, pebble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dump bucket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > dump bucket
            You empty the metal bucket: a small pebble.
            """)
    }

    @Test("POUR syntax works")
    func testPourSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let sand = Item(
            id: "sand",
            .name("fine sand"),
            .description("Fine sand."),
            .isTakable,
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, sand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour bottle
            You empty the glass bottle: fine sand.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot empty without specifying target")
    func testCannotEmptyWithoutTarget() async throws {
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
        try await engine.execute("empty")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty
            Empty what?
            """)
    }

    @Test("Cannot empty target not in scope")
    func testCannotEmptyTargetNotInScope() async throws {
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

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .isContainer,
            .isOpen,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty box
            You can’t see any such thing.
            """)
    }

    @Test("Cannot empty non-container")
    func testCannotEmptyNonContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty rock
            The large rock is not a container.
            """)
    }

    @Test("Cannot empty closed container")
    func testCannotEmptyClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A locked treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("gold treasure"),
            .description("Gold treasure."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty chest
            The treasure chest is closed.
            """)
    }

    @Test("Requires light to empty")
    func testRequiresLight() async throws {
        // Given: Dark room with container
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty box
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Empty already empty container")
    func testEmptyAlreadyEmptyContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let emptyBox = Item(
            id: "emptyBox",
            .name("empty box"),
            .description("An empty box."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: emptyBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty box
            The empty box is already empty.
            """)

        let finalState = try await engine.item("emptyBox")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Empty container with multiple items")
    func testEmptyContainerWithMultipleItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("travel bag"),
            .description("A travel bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old book."),
            .isTakable,
            .in(.item("bag"))
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient scroll."),
            .isTakable,
            .in(.item("bag"))
        )

        let quill = Item(
            id: "quill",
            .name("feather quill"),
            .description("A feather quill."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, book, scroll, quill
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bag")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty bag
            You empty the travel bag: an old book, an ancient scroll, and a feather quill.
            """)

        // Verify all items moved to room
        let finalBookState = try await engine.item("book")
        let finalScrollState = try await engine.item("scroll")
        let finalQuillState = try await engine.item("quill")
        #expect(finalBookState.parent == .location("testRoom"))
        #expect(finalScrollState.parent == .location("testRoom"))
        #expect(finalQuillState.parent == .location("testRoom"))
    }

    @Test("Empty container held by player")
    func testEmptyContainerHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let pouch = Item(
            id: "pouch",
            .name("leather pouch"),
            .description("A leather pouch."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.player)
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.item("pouch"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pouch, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty pouch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty pouch
            You empty the leather pouch: a silver ring.
            """)

        let finalPouchState = try await engine.item("pouch")
        let finalRingState = try await engine.item("ring")
        #expect(finalPouchState.parent == .player)  // Pouch still held
        #expect(finalRingState.parent == .location("testRoom"))  // Ring dumped to room
    }

    @Test("Empty sets touched flag on container")
    func testEmptySetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A glass jar."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let marble = Item(
            id: "marble",
            .name("blue marble"),
            .description("A blue marble."),
            .isTakable,
            .in(.item("jar"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty jar")

        // Then: Verify state changes
        let finalJarState = try await engine.item("jar")
        let finalMarbleState = try await engine.item("marble")
        #expect(finalJarState.hasFlag(.isTouched) == true)
        #expect(finalMarbleState.parent == .location("testRoom"))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty jar
            You empty the glass jar: a blue marble.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = EmptyActionHandler()
        // EmptyActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.verbs.contains(.empty))
        #expect(handler.verbs.contains(.dump))
        #expect(handler.verbs.contains(.pour))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.requiresLight == true)
    }
}
