import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DROP DIRECTOBJECTS syntax works")
    func testDropDirectObjectsSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop book
            Released.
            """
        )

        let finalState = await engine.item("book")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalState.parent == .location(startRoom))
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("DISCARD syntax works")
    func testDiscardSyntax() async throws {
        // Given
        let trash = Item(
            id: "trash",
            .name("crumpled paper"),
            .description("A crumpled piece of paper."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: trash
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("discard paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > discard paper
            Released.
            """
        )
    }

    @Test("DROP ALL syntax works when player has items")
    func testDropAllSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop all
            You drop the leather book and the gold coin.
            """
        )

        let bookState = await engine.item("book")
        let coinState = await engine.item("coin")
        let startRoom = await engine.location(.startRoom)
        #expect(await bookState.parent == .location(startRoom))
        #expect(await coinState.parent == .location(startRoom))
    }

    // MARK: - Validation Testing

    @Test("Cannot drop without specifying target")
    func testCannotDropWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop
            Drop what?
            """
        )
    }

    @Test("Cannot drop item not held")
    func testCannotDropItemNotHeld() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop book
            You aren't holding the leather book.
            """
        )
    }

    @Test("Cannot drop non-droppable item")
    func testCannotDropNonDroppableItem() async throws {
        // Given
        let cursedItem = Item(
            id: "cursedItem",
            .name("cursed ring"),
            .description("A ring that won't come off."),
            .omitDescription,  // Makes it non-droppable
            .in(.player)
        )

        let game = MinimalGame(
            items: cursedItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop ring")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop ring
            The universe denies your request to drop the cursed ring.
            """
        )
    }

    @Test("Requires light to drop")
    func testRequiresLight() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop book
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Drop single item successfully")
    func testDropSingleItem() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop sword
            Released.
            """
        )

        let finalState = await engine.item("sword")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalState.parent == .location(startRoom))
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Drop multiple items successfully")
    func testDropMultipleItems() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass oil lamp."),
            .isTakable,
            .in(.player)
        )

        let key = Item(
            id: "key",
            .name("rusty key"),
            .description("An old rusty key."),
            .isTakable,
            .in(.player)
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A coil of thick rope."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: lamp, key, rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop lamp and key and rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop lamp and key and rope
            You drop the rusty key, the brass lamp, and the thick rope.
            """
        )

        let lampState = await engine.item("lamp")
        let keyState = await engine.item("key")
        let ropeState = await engine.item("rope")
        let startRoom = await engine.location(.startRoom)
        #expect(await lampState.parent == .location(startRoom))
        #expect(await keyState.parent == .location(startRoom))
        #expect(await ropeState.parent == .location(startRoom))
    }

    @Test("Drop all when player has nothing")
    func testDropAllWhenEmpty() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop all
            You carry nothing but your own thoughts.
            """
        )
    }

    @Test("Drop clears worn flag")
    func testDropClearsWornFlag() async throws {
        // Given
        let hat = Item(
            id: "hat",
            .name("woolen hat"),
            .description("A warm woolen hat."),
            .isTakable,
            .isWorn,
            .in(.player)
        )

        let game = MinimalGame(
            items: hat
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop hat")

        // Then
        let finalState = await engine.item("hat")
        #expect(await finalState.hasFlag(.isWorn) == false)
        let startRoom = await engine.location(.startRoom)
        #expect(await finalState.parent == .location(startRoom))
    }

    @Test("Drop sets isTouched flag")
    func testDropSetsTouchedFlag() async throws {
        // Given
        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful sparkling gem."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: gem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop gem")

        // Then
        let finalState = await engine.item("gem")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Drop all skips non-droppable items")
    func testDropAllSkipsNonDroppableItems() async throws {
        // Given
        let droppableItem = Item(
            id: "droppableItem",
            .name("normal book"),
            .description("A normal book."),
            .isTakable,
            .in(.player)
        )

        let nonDroppableItem = Item(
            id: "nonDroppableItem",
            .name("cursed item"),
            .description("An item that can't be dropped."),
            .omitDescription,  // Makes it non-droppable
            .in(.player)
        )

        let game = MinimalGame(
            items: droppableItem, nonDroppableItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > drop all
            You drop the normal book.
            """
        )

        let droppableState = await engine.item("droppableItem")
        let nonDroppableState = await engine.item("nonDroppableItem")
        let startRoom = await engine.location(.startRoom)
        #expect(await droppableState.parent == .location(startRoom))
        #expect(await nonDroppableState.playerIsHolding)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DropActionHandler()
        #expect(handler.synonyms.contains(.drop))
        #expect(handler.synonyms.contains(.discard))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DropActionHandler()
        #expect(handler.requiresLight == true)
    }
}
