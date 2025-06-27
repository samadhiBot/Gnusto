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
            You inhale slowly, appreciating the universe’s decision to
            include breathable air.
            """)
    }

    @Test("BREATHE ON DIRECTOBJECT syntax provides atmospheric response")
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
        try await engine.execute("breathe on flower", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe on flower
            You exhale on the red flower with an unshakable faith in the
            communicative power of respiration.

            > breathe on flower
            You direct your breath at the red flower with full confidence
            in your respiratory technique.

            > breathe on flower
            You breathe on the red flower with refreshing honesty about
            your breathing priorities.
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
            I don’t understand that sentence.
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
            I don’t understand that sentence.
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
            You inhale slowly, appreciating the universe’s decision to
            include breathable air.
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
            You inhale slowly, appreciating the universe’s decision to
            include breathable air.

            > breathe
            You breathe with great purpose, although breathing tends to
            happen anyway.

            > breathe
            You take a breath, tasting hints of adventure and
            poor ventilation.
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
