import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BREATHE syntax works")
    func testBreatheSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe
            You fill your lungs with purpose.
            """
        )
    }

    @Test("BREATHE ON DIRECTOBJECT syntax works")
    func testBreatheOnDirectObjectSyntax() async throws {
        // Given
        let flower = Item(
            id: "flower",
            .name("red flower"),
            .description("A beautiful red flower."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe on flower")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe on flower
            You breathe on the red flower. Nothing happens.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot breathe with direct object")
    func testCannotBreatheWithDirectObject() async throws {
        // Given
        let mist = Item(
            id: "mist",
            .name("fresh mist"),
            .description("The mist around you."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mist
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe mist")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe mist
            Your ambition to breathe that must remain unfulfilled.
            """
        )
    }

    @Test("Cannot breathe with indirect object")
    func testCannotBreatheWithIndirectObject() async throws {
        // Given
        let mask = Item(
            id: "mask",
            .name("gas mask"),
            .description("A protective gas mask."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mask
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe with mask")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe with mask
            I'm stumped by 'with mask' in this context.
            """
        )
    }

    @Test("Can breathe on universal air")
    func testCanBreatheOnUniversalAir() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe on air")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe on air
            You fill your lungs with purpose.
            """
        )
    }

    @Test("Breathe works in dark rooms")
    func testBreatheWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for breathing)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe
            You fill your lungs with purpose.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.synonyms.contains(.breathe))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler supports air universal")
    func testHandlesUniversal() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("breathe the air")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > breathe the air
            You fill your lungs with purpose.
            """
        )
    }
}
