import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("READ DIRECTOBJECT syntax works")
    func testReadDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("magic book"),
            .description("A book full of ancient spells."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("The book contains powerful incantations.")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read book
            The book contains powerful incantations.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot read without specifying target")
    func testCannotReadWithoutTarget() async throws {
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
        try await engine.execute("read")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read
            Read what?
            """)
    }

    @Test("Cannot read target not in scope")
    func testCannotReadTargetNotInScope() async throws {
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

        let remoteBook = Item(
            id: "remoteBook",
            .name("remote book"),
            .description("A book in another room."),
            .isReadable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read book
            You can’t see any such thing.
            """)
    }

    @Test("Cannot read non-readable item")
    func testCannotReadNonReadableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A massive boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read rock
            You can’t read the large rock.
            """)
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
            .in(.location("darkRoom")),
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
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read book
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Read item with text")
    func testReadItemWithText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("A weathered parchment scroll."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("Here lies the wisdom of the ancients.")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read scroll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read scroll
            Here lies the wisdom of the ancients.
            """)
    }

    @Test("Read item with no text")
    func testReadItemWithNoText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let blankCard = Item(
            id: "blankCard",
            .name("blank card"),
            .description("A completely blank index card."),
            .isReadable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: blankCard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read card")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read card
            There's nothing written on the blank card.
            """)
    }

    @Test("Read item with empty text")
    func testReadItemWithEmptyText() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let emptyNote = Item(
            id: "emptyNote",
            .name("empty note"),
            .description("A note that appears blank."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: emptyNote
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read note")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read note
            There's nothing written on the empty note.
            """)
    }

    @Test("Read held item")
    func testReadHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: letter
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read letter")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read letter
            Dear friend, I hope this letter finds you well.
            """)
    }

    @Test("Read takable item auto-takes first")
    func testReadTakableItemAutoTakes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let leaflet = Item(
            id: "leaflet",
            .name("promotional leaflet"),
            .description("A colorful promotional leaflet."),
            .isReadable,
            .isTakable,
            .in(.location("testRoom")),
            .readText("Visit the Grand Underground Adventure!")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: leaflet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read leaflet")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read leaflet
            (Taken)

            Visit the Grand Underground Adventure!
            """)

        let finalState = try await engine.item("leaflet")
        #expect(finalState.parent == .player)
    }

    @Test("Read non-takable item doesn’t auto-take")
    func testReadNonTakableItemDoesntAutoTake() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sign = Item(
            id: "sign",
            .name("wooden sign"),
            .description("A large wooden sign."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("Welcome to the enchanted forest.")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sign
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read sign")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read sign
            Welcome to the enchanted forest.
            """)

        let finalState = try await engine.item("sign")
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("Reading sets isTouched flag")
    func testReadingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let manuscript = Item(
            id: "manuscript",
            .name("old manuscript"),
            .description("A yellowed old manuscript."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("These are the chronicles of ages past.")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: manuscript
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read manuscript")

        // Then
        let finalState = try await engine.item("manuscript")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Read item in open container")
    func testReadItemInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden storage box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
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
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, recipe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read recipe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read recipe
            (Taken)

            Mix flour, eggs, and milk. Bake for 30 minutes.
            """)
    }

    @Test("Read multiple readable items")
    func testReadMultipleReadableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let journal = Item(
            id: "journal",
            .name("travel journal"),
            .description("A well-worn travel journal."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("Day 1: Started the journey today.")
        )

        let note = Item(
            id: "note",
            .name("sticky note"),
            .description("A yellow sticky note."),
            .isReadable,
            .in(.location("testRoom")),
            .readText("Don’t forget to feed the cat!")
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: journal, note
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("read journal")
        try await engine.execute("read note")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > read journal
            Day 1: Started the journey today.
            > read note
            Don’t forget to feed the cat!
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ReadActionHandler()
        // ReadActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ReadActionHandler()
        #expect(handler.verbs.contains(.read))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ReadActionHandler()
        #expect(handler.requiresLight == true)
    }
}
