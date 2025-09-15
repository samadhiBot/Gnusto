import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("OPEN DIRECTOBJECT syntax works")
    func testOpenDirectObjectSyntax() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isContainer,
            .isOpenable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open chest
            You open the wooden chest with a satisfying sense of purpose.
            """
        )

        let finalState = try await engine.item("chest")
        #expect(await finalState.hasFlag(.isOpen) == true)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot open without specifying target")
    func testCannotOpenWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open
            Open what?
            """
        )
    }

    @Test("Cannot open target not in scope")
    func testCannotOpenTargetNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open door
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot open non-openable item")
    func testCannotOpenNonOpenableItem() async throws {
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
        try await engine.execute("open rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open rock
            The large rock stubbornly resists your attempts to open it.
            """
        )
    }

    @Test("Cannot open locked item")
    func testCannotOpenLockedItem() async throws {
        // Given
        let lockedBox = Item(
            id: "lockedBox",
            .name("locked box"),
            .description("A box with a sturdy lock."),
            .isOpenable,
            .isLocked,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lockedBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open box
            The locked box is locked.
            """
        )
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
            .in("darkRoom")
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
        expectNoDifference(
            output,
            """
            > open chest
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Open closed openable item succeeds")
    func testOpenClosedOpenableItem() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isContainer,
            .isOpenable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open box
            You open the cardboard box with a satisfying sense of purpose.
            """
        )

        let finalState = try await engine.item("box")
        #expect(await finalState.hasFlag(.isOpen) == true)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Open already open item gives appropriate message")
    func testOpenAlreadyOpenItem() async throws {
        // Given
        let openChest = Item(
            id: "openChest",
            .name("open chest"),
            .description("A chest that is already open."),
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: openChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open chest
            The open chest is already open.
            """
        )
    }

    @Test("Open container with contents reveals items")
    func testOpenContainerWithContents() async throws {
        // Given
        let mailbox = Item(
            id: "mailbox",
            .name("small mailbox"),
            .description("A small metal mailbox."),
            .isContainer,
            .isOpenable,
            .in(.startRoom)
        )

        let leaflet = Item(
            id: "leaflet",
            .name("leaflet"),
            .description("A promotional leaflet."),
            .in(.item("mailbox"))
        )

        let game = MinimalGame(
            items: mailbox, leaflet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open mailbox")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open mailbox
            As the small mailbox opens, it reveals a leaflet within.
            """
        )

        let finalState = try await engine.item("mailbox")
        #expect(await finalState.hasFlag(.isOpen) == true)
    }

    @Test("Open empty container gives simple message")
    func testOpenEmptyContainer() async throws {
        // Given
        let emptyBox = Item(
            id: "emptyBox",
            .name("empty box"),
            .description("An empty storage box."),
            .isContainer,
            .isOpenable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: emptyBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open box
            You open the empty box with a satisfying sense of purpose.
            """
        )
    }

    @Test("Open container with multiple items lists all contents")
    func testOpenContainerWithMultipleItems() async throws {
        // Given
        let trunk = Item(
            id: "trunk",
            .name("old trunk"),
            .description("A weathered old trunk."),
            .isContainer,
            .isOpenable,
            .in(.startRoom)
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
            items: trunk, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open trunk")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open trunk
            As the old trunk opens, it reveals a leather book and a white
            candle within.
            """
        )
    }

    @Test("Opening sets isTouched flag")
    func testOpeningSetsTouchedFlag() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("metal container"),
            .description("A metal storage container."),
            .isOpenable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open container")

        // Then
        let finalState = try await engine.item("container")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Open non-container openable item")
    func testOpenNonContainerOpenableItem() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .isOpenable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("open door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > open door
            You open the wooden door with a satisfying sense of purpose.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = OpenActionHandler()
        #expect(handler.synonyms.contains(.open))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = OpenActionHandler()
        #expect(handler.requiresLight == true)
    }
}
