import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLOSE syntax works")
    func testCloseSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A small wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            You close the wooden box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isOpen) == false)
    }

    @Test("SHUT syntax works")
    func testShutSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("heavy chest"),
            .description("A heavy iron chest."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shut chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shut chest
            You close the heavy chest.
            """)

        let finalState = try await engine.item("chest")
        #expect(finalState.hasFlag(.isOpen) == false)
    }


    // MARK: - Validation Testing

    @Test("Cannot close without specifying target")
    func testCannotCloseWithoutTarget() async throws {
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
        try await engine.execute("close")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close
            What do you want to close?
            """)
    }

    @Test("Cannot close item not in scope")
    func testCannotCloseItemNotInScope() async throws {
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
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            You can't see any such thing.
            """)
    }

    @Test("Requires light to close items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
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
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot close an item that is not a container")
    func testCannotCloseNonContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .description("A heavy, solid rock."),
            // Note: Not a container
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close rock
            You can't close that.
            """)
        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Cannot close an item that is already closed")
    func testCannotCloseAlreadyClosedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A small wooden box."),
            .isContainer,
            // Note: Not .isOpen
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            It's already closed.
            """)
    }


    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CloseActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CloseActionHandler()
        #expect(handler.verbs.contains(.close))
        #expect(handler.verbs.contains(.shut))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CloseActionHandler()
        #expect(handler.requiresLight == true)
    }
}
