import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BREATHE syntax works")
    func testBreatheSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe
            Your respiratory system continues its thankless work.
            """)
    }

    @Test("BREATHE ON DIRECTOBJECT syntax works")
    func testBreatheOnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flower = Item(
            id: "flower",
            .name("red flower"),
            .description("A beautiful red flower."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe on flower")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe on flower
            You exhale intimately upon the red flower and achieve
            maximum awkwardness.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot breathe with direct object")
    func testCannotBreatheWithDirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let air = Item(
            id: "air",
            .name("fresh air"),
            .description("The air around you."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: air
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe air")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe air
            We’re flattered you think we’re smart enough to parse that.
            """)
    }

    @Test("Cannot breathe with indirect object")
    func testCannotBreatheWithIndirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mask = Item(
            id: "mask",
            .name("gas mask"),
            .description("A protective gas mask."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mask
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe with mask")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe with mask
            We’re flattered you think we’re smart enough to parse that.
            """)
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
        expectNoDifference(output, """
            > breathe
            Your respiratory system continues its thankless work.
            """)
    }

    // MARK: - Processing Testing

    @Test("Breathe provides atmospheric response")
    func testBreatheAtmosphericResponse() async throws {
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
        try await engine.execute("breathe", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe
            Your respiratory system continues its thankless work.

            > breathe
            Breathing? How terribly… Functional.

            > breathe
            Air enters, air departs. The cycle continues unabated.
            """)
    }

    @Test("Breathe on Direct Object provides atmospheric response")
    func testBreatheOnAtmosphericResponse() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let flower = Item(
            id: "flower",
            .name("red flower"),
            .description("A beautiful red flower."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("breathe on flower", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe on flower
            You exhale intimately upon the red flower and achieve
            maximum awkwardness.

            > breathe on flower
            How wonderfully direct. The red flower receives your breath
            with stoic grace.

            > breathe on flower
            The engagement between your lungs and the red flower yields
            atmospheric intimacy.
            """)
    }


    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = BreatheActionHandler()
        // BreatheActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.verbs.contains(.breathe))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.requiresLight == false)
    }
}
