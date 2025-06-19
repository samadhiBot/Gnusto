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

    @Test("Pour water on fire extinguishes flames")
    func testPourWaterOnFireExtinguishesFlames() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )
        let torch = Item(
            id: "torch",
            .name("torch"),
            .in(.location(.startRoom)),
            .isFlammable,
            .isLit
        )

        let game = MinimalGame(items: water, torch)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pour water on torch
            You pour the water on the torch. The flames are extinguished with a hissing sound.
            """)
    }

    @Test("Pour water on plant")
    func testPourWaterOnPlant() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )
        let flower = Item(
            id: "flower",
            .name("flower"),
            .in(.location(.startRoom)),
            .isPlant
        )

        let game = MinimalGame(items: water, flower)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on flower")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > pour water on flower
            You pour the water on the flower. It looks refreshed.
            """)
    }
}
