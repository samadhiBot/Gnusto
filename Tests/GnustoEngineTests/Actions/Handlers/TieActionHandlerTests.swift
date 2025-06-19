import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TieActionHandler Tests")
struct TieActionHandlerTests {

    @Test("Tie validates missing direct object")
    func testTieValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("tie")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie
            Tie what?
            """)
    }

    @Test("Tie rope alone shows knot message")
    func testTieRopeAloneShowsKnotMessage() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom)),
            .isTakable,
            .isRope
        )

        let game = MinimalGame(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie rope
            You tie a knot in the rope.
            """)
    }

    @Test("Tie integration test")
    func testTieIntegrationTest() async throws {
        // Given
        let cord = Item(
            id: "cord",
            .name("cord"),
            .in(.location(.startRoom)),
            .isTakable,
            .isRope
        )

        let game = MinimalGame(items: cord)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tie cord")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tie cord
            You tie a knot in the cord.
            """)
    }
}
