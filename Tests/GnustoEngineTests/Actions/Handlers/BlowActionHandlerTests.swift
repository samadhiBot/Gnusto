import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BlowActionHandler Tests")
struct BlowActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BLOW DIRECTOBJECT syntax works")
    func testBlowDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let feather = Item(
            id: "feather",
            .name("fluffy feather"),
            .description("A fluffy feather."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: feather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow feather
            You blow on the fluffy feather, but nothing
            interesting happens.
            """)

        let finalState = try await engine.item("feather")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("BLOW ON DIRECTOBJECT syntax works")
    func testBlowOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dust = Item(
            id: "dust",
            .name("pile of dust"),
            .description("A small pile of dust."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dust
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow on dust")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow on dust
            You blow on the pile of dust, but nothing interesting happens.
            """)
    }

    @Test("PUFF syntax works")
    func testPuffSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let card = Item(
            id: "card",
            .name("playing card"),
            .description("A single playing card."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: card
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("puff card")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > puff card
            You blow on the playing card, but nothing interesting happens.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot blow on item not in scope")
    func testCannotBlowOnItemNotInScope() async throws {
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

        let remoteFeather = Item(
            id: "remoteFeather",
            .name("remote feather"),
            .description("A feather in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteFeather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow feather
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to blow on items")
    func testRequiresLight() async throws {
        // Given: Dark room with an item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let feather = Item(
            id: "feather",
            .name("fluffy feather"),
            .description("A fluffy feather."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: feather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow feather
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Blow without an object gives a general message")
    func testBlowWithoutObject() async throws {
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
        try await engine.execute("blow")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow
            You blow the air around, but nothing interesting happens.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = BlowActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BlowActionHandler()
        #expect(handler.verbs.contains(.blow))
        #expect(handler.verbs.contains(.puff))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = BlowActionHandler()
        #expect(handler.requiresLight == true)
    }
}
