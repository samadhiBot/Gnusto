import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("READ DIRECTOBJECT syntax works")
    func testReadDirectObjectSyntax() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("magic book"),
            .description("A book full of ancient spells."),
            .isReadable,
            .in(.startRoom),
            .readText("The book contains powerful incantations.")
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read book")

        // Then
        await mockIO.expectOutput(
            """
            > read book
            The book contains powerful incantations.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot read without specifying target")
    func testCannotReadWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read")

        // Then
        await mockIO.expectOutput(
            """
            > read
            Read what?
            """
        )
    }

    @Test("Cannot read target not in scope")
    func testCannotReadTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBook = Item(
            id: "remoteBook",
            .name("remote book"),
            .description("A book in another room."),
            .isReadable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read book")

        // Then
        await mockIO.expectOutput(
            """
            > read book
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot read non-readable item")
    func testCannotReadNonReadableItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A massive boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read rock")

        // Then
        await mockIO.expectOutput(
            """
            > read rock
            The large rock stubbornly resists your attempts to read it.
            """
        )
    }

    @Test("Requires light to read")
    func testRequiresLight() async throws {
        // Given: Dark room with readable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let book = Item(
            id: "book",
            .name("mysterious book"),
            .description("A book with strange symbols."),
            .isReadable,
            .in("darkRoom"),
            .readText("Ancient runes glow faintly in the darkness.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read book")

        // Then
        await mockIO.expectOutput(
            """
            > read book
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Read item with text")
    func testReadItemWithText() async throws {
        // Given
        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("A weathered parchment scroll."),
            .isReadable,
            .in(.startRoom),
            .readText("Here lies the wisdom of the ancients.")
        )

        let game = MinimalGame(
            items: scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read scroll")

        // Then
        await mockIO.expectOutput(
            """
            > read scroll
            Here lies the wisdom of the ancients.
            """
        )
    }

    @Test("Read item with no text")
    func testReadItemWithNoText() async throws {
        // Given
        let blankCard = Item(
            id: "blankCard",
            .name("blank card"),
            .description("A completely blank index card."),
            .isReadable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: blankCard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read card")

        // Then
        await mockIO.expectOutput(
            """
            > read card
            The blank card bears no inscription, message, or literary
            content whatsoever.
            """
        )
    }

    @Test("Read item with empty text")
    func testReadItemWithEmptyText() async throws {
        // Given
        let emptyNote = Item(
            id: "emptyNote",
            .name("empty note"),
            .description("A note that appears blank."),
            .isReadable,
            .in(.startRoom),
            .readText("")
        )

        let game = MinimalGame(
            items: emptyNote
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read note")

        // Then
        await mockIO.expectOutput(
            """
            > read note
            The empty note bears no inscription, message, or literary
            content whatsoever.
            """
        )
    }

    @Test("Read held item")
    func testReadHeldItem() async throws {
        // Given
        let letter = Item(
            id: "letter",
            .name("personal letter"),
            .description("A letter addressed to you."),
            .isReadable,
            .isTakable,
            .in(.player),
            .readText("Dear friend, I hope this letter finds you well.")
        )

        let game = MinimalGame(
            items: letter
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read letter")

        // Then
        await mockIO.expectOutput(
            """
            > read letter
            Dear friend, I hope this letter finds you well.
            """
        )
    }

    @Test("Read takable item auto-takes first")
    func testReadTakableItemAutoTakes() async throws {
        // Given
        let leaflet = Item(
            id: "leaflet",
            .name("promotional leaflet"),
            .description("A colorful promotional leaflet."),
            .isReadable,
            .isTakable,
            .in(.startRoom),
            .readText("Visit the Grand Underground Adventure!")
        )

        let game = MinimalGame(
            items: leaflet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read leaflet")

        // Then
        await mockIO.expectOutput(
            """
            > read leaflet
            (Taken)

            Visit the Grand Underground Adventure!
            """
        )

        let finalState = await engine.item("leaflet")
        #expect(await finalState.playerIsHolding)
    }

    @Test("Read non-takable item doesn't auto-take")
    func testReadNonTakableItemDoesntAutoTake() async throws {
        // Given
        let sign = Item(
            id: "sign",
            .name("wooden sign"),
            .description("A large wooden sign."),
            .isReadable,
            .in(.startRoom),
            .readText("Welcome to the enchanted forest.")
        )

        let game = MinimalGame(
            items: sign
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read sign")

        // Then
        await mockIO.expectOutput(
            """
            > read sign
            Welcome to the enchanted forest.
            """
        )

        let finalState = await engine.item("sign")
        let startRoom = await engine.location(.startRoom)
        #expect(await finalState.parent == .location(startRoom))
    }

    @Test("Reading sets isTouched flag")
    func testReadingSetsTouchedFlag() async throws {
        // Given
        let manuscript = Item(
            id: "manuscript",
            .name("old manuscript"),
            .description("A yellowed old manuscript."),
            .isReadable,
            .in(.startRoom),
            .readText("These are the chronicles of ages past.")
        )

        let game = MinimalGame(
            items: manuscript
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read manuscript")

        // Then
        let finalState = await engine.item("manuscript")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Read item in open container")
    func testReadItemInOpenContainer() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let recipe = Item(
            id: "recipe",
            .name("recipe card"),
            .description("A handwritten recipe card."),
            .isReadable,
            .isTakable,
            .in(.item("box")),
            .readText("Mix flour, eggs, and milk. Bake for 30 minutes.")
        )

        let game = MinimalGame(
            items: box, recipe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read recipe")

        // Then
        await mockIO.expectOutput(
            """
            > read recipe
            (Taken)

            Mix flour, eggs, and milk. Bake for 30 minutes.
            """
        )
    }

    @Test("Read multiple readable items")
    func testReadMultipleReadableItems() async throws {
        // Given
        let journal = Item(
            id: "journal",
            .name("travel journal"),
            .description("A well-worn travel journal."),
            .isReadable,
            .in(.startRoom),
            .readText("Day 1: Started the journey today.")
        )

        let note = Item(
            id: "note",
            .name("sticky note"),
            .description("A yellow sticky note."),
            .isReadable,
            .in(.startRoom),
            .readText("Don't forget to feed the cat!")
        )

        let game = MinimalGame(
            items: journal, note
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read journal")
        try await engine.execute("read note")

        // Then
        await mockIO.expectOutput(
            """
            > read journal
            Day 1: Started the journey today.

            > read note
            Don't forget to feed the cat!
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ReadActionHandler()
        #expect(handler.synonyms.contains(.read))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ReadActionHandler()
        #expect(handler.requiresLight == true)
    }
}
