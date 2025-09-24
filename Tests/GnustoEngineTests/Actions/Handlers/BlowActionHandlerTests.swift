import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("BlowActionHandler Tests")
struct BlowActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BLOW DIRECTOBJECT syntax works")
    func testBlowDirectObjectSyntax() async throws {
        // Given
        let feather = Item(
            id: "feather",
            .name("fluffy feather"),
            .description("A fluffy feather."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: feather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow feather
            Blowing on the fluffy feather accomplishes nothing of note.
            """
        )

        let finalState = await engine.item("feather")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot blow on item not in scope")
    func testCannotBlowOnItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteFeather = Item(
            id: "remoteFeather",
            .name("remote feather"),
            .description("A feather in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteFeather
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow feather
            Any such thing remains frustratingly inaccessible.
            """
        )
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
            .in("darkRoom")
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
        expectNoDifference(
            output,
            """
            > blow feather
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Blow without an object gives a general message")
    func testBlowWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow
            You blow air with great purpose but little effect.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BlowActionHandler()
        #expect(handler.synonyms.contains(.blow))
        #expect(handler.synonyms.contains(.puff))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = BlowActionHandler()
        #expect(handler.requiresLight == true)
    }
}
