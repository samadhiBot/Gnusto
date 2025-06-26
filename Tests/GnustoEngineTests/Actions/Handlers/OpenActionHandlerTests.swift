import Testing
import CustomDump
@testable import GnustoEngine

@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("OPEN DIRECTOBJECT syntax works")
    func testOpenDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isOpenable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open chest
            You open the wooden chest.
            """)

        let finalState = try await engine.item("chest")
        #expect(finalState.hasFlag(.isOpen) == true)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot open without specifying target")
    func testCannotOpenWithoutTarget() async throws {
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
        try await engine.execute("open")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open
            Open what?
            """)
    }

    @Test("Cannot open target not in scope")
    func testCannotOpenTargetNotInScope() async throws {
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

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("remote door"),
            .description("A door in another room."),
            .isOpenable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open door
            You can’t see any such thing.
            """)
    }

    @Test("Cannot open non-openable item")
    func testCannotOpenNonOpenableItem() async throws {
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
        try await engine.execute("open rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open rock
            You can’t open the large rock.
            """)
    }

    @Test("Cannot open locked item")
    func testCannotOpenLockedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lockedBox = Item(
            id: "lockedBox",
            .name("locked box"),
            .description("A box with a sturdy lock."),
            .isOpenable,
            .isLocked,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lockedBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open box
            The locked box is locked.
            """)
    }

    @Test("Requires light to open")
    func testRequiresLight() async throws {
        // Given: Dark room with openable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isOpenable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open chest
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Open closed openable item succeeds")
    func testOpenClosedOpenableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isOpenable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open box
            You open the cardboard box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isOpen) == true)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Open already open item gives appropriate message")
    func testOpenAlreadyOpenItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let openChest = Item(
            id: "openChest",
            .name("open chest"),
            .description("A chest that is already open."),
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: openChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open chest
            The open chest is already open.
            """)
    }

    @Test("Open container with contents reveals items")
    func testOpenContainerWithContents() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mailbox = Item(
            id: "mailbox",
            .name("small mailbox"),
            .description("A small metal mailbox."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let leaflet = Item(
            id: "leaflet",
            .name("leaflet"),
            .description("A promotional leaflet."),
            .in(.item("mailbox"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mailbox, leaflet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open mailbox")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open mailbox
            Opening the small mailbox reveals a leaflet.
            """)

        let finalState = try await engine.item("mailbox")
        #expect(finalState.hasFlag(.isOpen) == true)
    }

    @Test("Open empty container gives simple message")
    func testOpenEmptyContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let emptyBox = Item(
            id: "emptyBox",
            .name("empty box"),
            .description("An empty storage box."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: emptyBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open box
            You open the empty box.
            """)
    }

    @Test("Open container with multiple items lists all contents")
    func testOpenContainerWithMultipleItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let trunk = Item(
            id: "trunk",
            .name("old trunk"),
            .description("A weathered old trunk."),
            .isContainer,
            .isOpenable,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .in(.item("trunk"))
        )

        let candle = Item(
            id: "candle",
            .name("white candle"),
            .description("A white wax candle."),
            .in(.item("trunk"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: trunk, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open trunk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open trunk
            Opening the old trunk reveals a leather book and a white candle.
            """)
    }

    @Test("Opening sets isTouched flag")
    func testOpeningSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let container = Item(
            id: "container",
            .name("metal container"),
            .description("A metal storage container."),
            .isOpenable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: container
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open container")

        // Then
        let finalState = try await engine.item("container")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Open non-container openable item")
    func testOpenNonContainerOpenableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .isOpenable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > open door
            You open the wooden door.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = OpenActionHandler()
        // OpenActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = OpenActionHandler()
        #expect(handler.verbs.contains(.open))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = OpenActionHandler()
        #expect(handler.requiresLight == true)
    }
}
