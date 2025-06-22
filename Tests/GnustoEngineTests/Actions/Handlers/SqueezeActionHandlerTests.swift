import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SqueezeActionHandler Tests")
struct SqueezeActionHandlerTests {

    @Test("Squeeze validates missing direct object")
    func testSqueezeValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("squeeze")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze
            Squeeze what?
            """)
    }

    @Test("Squeeze character shows appropriate message")
    func testSqueezeCharacterMessage() async throws {
        // Given
        let sponge = Item(
            id: "chimpanzee",
            .name("angry chimp"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the angry chimp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze the angry chimp
            You squeeze the angry chimp with an impressive dedication to
            interpersonal closeness.
            """)
    }

    @Test("Squeeze item message")
    func testSqueezeItemMessage() async throws {
        // Given
        let tube = Item(
            id: "tube",
            .name("toothpaste tube"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: tube)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze the tube")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze the tube
            You give the toothpaste tube a testing squeeze with impressive
            tactile prowess.
            """)
    }

    @Test("Squeeze updates state correctly")
    func testSqueezeUpdatesStateCorrectly() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("sponge"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze sponge")

        // Then - Check state was updated
        let finalSponge = try await engine.item("sponge")
        #expect(finalSponge.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze sponge
            You give the sponge a testing squeeze with impressive
            tactile prowess.
            """)
    }
}
