import Testing
import CustomDump
@testable import GnustoEngine

@Suite("DeflateActionHandler Tests")
struct DeflateActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DEFLATE syntax works")
    func testDeflateSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let raft = Item(
            id: "raft",
            .name("inflatable raft"),
            .description("A rubber raft, currently inflated."),
            .in(.location("testRoom")),
            .custom(key: "inflatable", value: .bool(true)),
            .custom(key: "inflated", value: .bool(true))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate raft
            You deflate the inflatable raft.
            """)

        let finalState = try await engine.item("raft")
        #expect(try finalState.attribute(.bool("inflated")) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot deflate without specifying target")
    func testCannotDeflateWithoutTarget() async throws {
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
        try await engine.execute("deflate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate
            What do you want to deflate?
            """)
    }

    @Test("Cannot deflate item not in scope")
    func testCannotDeflateItemNotInScope() async throws {
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

        let remoteRaft = Item(
            id: "remoteRaft",
            .name("remote raft"),
            .custom(key: "inflatable", value: .bool(true)),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRaft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate raft
            You can't see any such thing.
            """)
    }

    @Test("Requires light to deflate items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
        )

        let raft = Item(
            id: "raft",
            .name("inflatable raft"),
            .custom(key: "inflatable", value: .bool(true)),
            .custom(key: "inflated", value: .bool(true)),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate raft
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot deflate an item that is not inflatable")
    func testCannotDeflateNonInflatableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate rock
            You can't deflate that.
            """)
    }

    @Test("Cannot deflate an item that is already deflated")
    func testCannotDeflateAlreadyDeflatedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let raft = Item(
            id: "raft",
            .name("inflatable raft"),
            .custom(key: "inflatable", value: .bool(true)),
            .custom(key: "inflated", value: .bool(false)), // Already deflated
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate raft
            It is already deflated.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.verbs.contains(.deflate))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.requiresLight == true)
    }
}
