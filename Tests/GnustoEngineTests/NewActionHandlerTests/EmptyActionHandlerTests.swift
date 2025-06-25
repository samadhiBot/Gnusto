import Testing
import CustomDump
@testable import GnustoEngine

@Suite("EmptyActionHandler Tests")
struct EmptyActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EMPTY syntax works")
    func testEmptySyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .in(.location("testRoom"))
        )

        let water = Item(
            id: "water",
            .name("quantity of water"),
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty bottle
            The glass bottle is now empty.
            """)

        #expect((try await engine.item("water")).parent == .location("testRoom"))
        #expect((try await engine.item("bottle")).hasFlag(.isTouched))
    }

    @Test("POUR FROM syntax works")
    func testPourFromSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)

        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A glass bottle."),
            .isContainer,
            .in(.location("testRoom"))
        )

        let water = Item(
            id: "water",
            .name("quantity of water"),
            .in(.item("bottle"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour from bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pour from bottle
            The glass bottle is now empty.
            """)

        #expect((try await engine.item("water")).parent == .location("testRoom"))
    }


    // MARK: - Validation Testing

    @Test("Cannot empty without specifying target")
    func testCannotEmptyWithoutTarget() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty
            What do you want to empty?
            """)
    }

    @Test("Cannot empty item not in scope")
    func testCannotEmptyItemNotInScope() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let anotherRoom = Location(id: "anotherRoom", .name("Another Room"), .inherentlyLit)
        let remoteBottle = Item(id: "remoteBottle", .name("remote bottle"), .isContainer, .in(.location("anotherRoom")))
        let water = Item(id: "water", .name("water"), .in(.item("remoteBottle")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBottle, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty bottle
            You can't see any such thing.
            """)
    }

    @Test("Requires light to empty items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let bottle = Item(id: "bottle", .name("glass bottle"), .isContainer, .in(.location("darkRoom")))
        let water = Item(id: "water", .name("water"), .in(.item("bottle")))

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: bottle, water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty bottle
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot empty a non-container")
    func testCannotEmptyNonContainer() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let rock = Item(id: "rock", .name("heavy rock"), .in(.location("testRoom")))

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
        expectNoDifference(output, """
            > empty rock
            The heavy rock isn't a container.
            """)
    }

    @Test("Cannot empty an item that is already empty")
    func testCannotEmptyAlreadyEmptyItem() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let bottle = Item(id: "bottle", .name("glass bottle"), .isContainer, .in(.location("testRoom")))
        // No contents in bottle

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty bottle
            The glass bottle is already empty.
            """)
    }

    @Test("Cannot empty an open container")
    func testCannotEmptyOpenContainer() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .isContainer,
            .isOpen, // Can't empty if open
            .in(.location("testRoom"))
        )
        let water = Item(id: "water", .name("water"), .in(.item("bottle")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, water
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("empty bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty bottle
            The glass bottle isn't open, so you can't empty it.
            """)
    }


    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.verbs.contains(.empty))
        #expect(handler.verbs.contains(.pourFrom))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EmptyActionHandler()
        #expect(handler.requiresLight == true)
    }
}
