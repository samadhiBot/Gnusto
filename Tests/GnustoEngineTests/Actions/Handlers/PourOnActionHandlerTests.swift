import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PourOnActionHandler Tests")
struct PourOnActionHandlerTests {

    @Test("Pour validates missing direct object")
    func testPourValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("pour")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pour
            Pour what?
            """)
    }

    @Test("Pour validates missing indirect object")
    func testPourValidatesMissingIndirectObject() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )

        let game = MinimalGame(items: water)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("pour water")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pour water
            Pour the water on what?
            """)
    }
}
