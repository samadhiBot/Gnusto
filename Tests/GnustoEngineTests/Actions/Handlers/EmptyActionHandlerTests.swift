import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("EmptyActionHandler Tests")
struct EmptyActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EMPTY DIRECTOBJECT syntax works")
    func testEmptyDirectObjectSyntax() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
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
            You empty the wooden box, and a gold coin falls to the ground.
            """
        )

        let finalBoxState = await engine.item("box")
        let finalCoinState = await engine.item("coin")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalBoxState.hasFlag(.isTouched) == true)
        #expect(await finalCoinState.parent == .location(startRoom))
    }

    @Test("EMPTY DIRECTOBJECT INTO INDIRECTOBJECT syntax works")
    func testEmptyIntoContainerSyntax() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let basket = Item(
            id: "basket",
            .name("wicker basket"),
            .description("A wicker basket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("red gem"),
            .description("A red gem."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
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
            You empty a red gem from the leather bag into the wicker
            basket.
            """
        )

        let finalGemState = await engine.item("gem")
        #expect(await finalGemState.parent == .item(basket.proxy(engine)))
    }

    @Test("EMPTY OUT DIRECTOBJECT syntax works")
    func testEmptyOutDirectObjectSyntax() async throws {
        // Given
        let sack = Item(
            id: "sack",
            .name("burlap sack"),
            .description("A burlap sack."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.item("sack"))
        )

        let game = MinimalGame(
            items: sack, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty out the sack")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty out the sack
            You empty the burlap sack, and a brass key falls to the ground.
            """
        )

        let finalKeyState = await engine.item("key")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalKeyState.parent == .location(startRoom))
    }

    @Test("DUMP syntax works")
    func testDumpSyntax() async throws {
        // Given
        let bucket = Item(
            id: "bucket",
            .name("metal bucket"),
            .description("A metal bucket."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A small pebble."),
            .isTakable,
            .in(.item("bucket"))
        )

        let game = MinimalGame(
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
            You empty the metal bucket, and a small pebble falls to the
            ground.
            """
        )
    }

    @Test("POUR syntax uses pour action handler")
    func testPourSyntax() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let sand = Item(
            id: "sand",
            .name("fine sand"),
            .description("Fine sand."),
            .isTakable,
            .in(.item("bottle"))
        )

        let game = MinimalGame(
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
            Pour the glass bottle on what?
            """
        )
    }

    @Test("POUR OUT syntax works")
    func testPourOutSyntax() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let sand = Item(
            id: "sand",
            .name("fine sand"),
            .description("Fine sand."),
            .isTakable,
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            items: bottle, sand
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour out bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour out bottle
            You empty the glass bottle, and a fine sand falls to the
            ground.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot empty without specifying target")
    func testCannotEmptyWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
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
            """
        )
    }

    @Test("Cannot empty target not in scope")
    func testCannotEmptyTargetNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot empty non-container")
    func testCannotEmptyNonContainer() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            You can't put things in the large rock.
            """
        )
    }

    @Test("Cannot empty closed container")
    func testCannotEmptyClosedContainer() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A locked treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)
        )

        let treasure = Item(
            id: "treasure",
            .name("gold treasure"),
            .description("Gold treasure."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
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
            """
        )
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
            .in("darkRoom")
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
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Empty already empty container")
    func testEmptyAlreadyEmptyContainer() async throws {
        // Given
        let emptyBox = Item(
            id: "emptyBox",
            .name("empty box"),
            .description("An empty box."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )
    }

    @Test("Empty container with multiple items")
    func testEmptyContainerWithMultipleItems() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("travel bag"),
            .description("A travel bag."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
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
            You empty the travel bag, and an old book, a feather quill, and
            an ancient scroll fall to the ground.
            """
        )

        // Verify all items moved to room
        let finalBookState = await engine.item("book")
        let finalScrollState = await engine.item("scroll")
        let finalQuillState = await engine.item("quill")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalBookState.parent == .location(startRoom))
        #expect(await finalScrollState.parent == .location(startRoom))
        #expect(await finalQuillState.parent == .location(startRoom))
    }

    @Test("Empty container held by player")
    func testEmptyContainerHeldByPlayer() async throws {
        // Given
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
            You empty the leather pouch, and a silver ring falls to the
            ground.
            """
        )

        let finalPouchState = await engine.item("pouch")
        let finalRingState = await engine.item("ring")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalPouchState.playerIsHolding)  // Pouch still held
        #expect(await finalRingState.parent == .location(startRoom))  // Ring dumped to room
    }

    @Test("Empty sets touched flag on container")
    func testEmptySetsTouchedFlag() async throws {
        // Given
        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A glass jar."),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.startRoom)
        )

        let marble = Item(
            id: "marble",
            .name("blue marble"),
            .description("A blue marble."),
            .isTakable,
            .in(.item("jar"))
        )

        let game = MinimalGame(
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty jar")

        // Then: Verify state changes
        let finalJarState = await engine.item("jar")
        let finalMarbleState = await engine.item("marble")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalJarState.hasFlag(.isTouched) == true)
        #expect(await finalMarbleState.parent == .location(startRoom))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > empty jar
            You empty the glass jar, and a blue marble falls to the ground.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.synonyms.contains(.empty))
        #expect(handler.synonyms.contains(.dump))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.requiresLight == true)
    }
}
