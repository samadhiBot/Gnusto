import CustomDump
import GnustoEngine
import Testing

@Suite("BurnActionHandler")
struct BurnActionHandlerTests {
    @Test("BURN without object")
    func testBurnWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("burn")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn
            Burn what?
            """)
    }

    @Test("BURN command")
    func testBurn() async throws {
        let advertisement = Item(
            id: "advertisement",
            .name("leaflet"),
            .isFlammable,
            .in(.player)
        )
        let game = MinimalGame(items: advertisement)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("burn leaflet", times: 2)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn leaflet
            The leaflet catches fire and burns to ashes.

            > burn leaflet
            You can’t see the leaflet.
            """)
    }
}
