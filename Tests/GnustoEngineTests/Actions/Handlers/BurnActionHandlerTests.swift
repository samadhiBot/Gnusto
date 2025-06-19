import CustomDump
import GnustoEngine
import Testing

@Suite("BurnActionHandler")
struct BurnActionHandlerTests {
    @Test("BURN without object uses MessageProvider for error")
    func testBurnWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let handler = BurnActionHandler()
        let command = Command(
            verb: .burn,
            rawInput: "burn"
        )
        let context = ActionContext(command: command, engine: engine)

        await #expect(throws: ActionResponse.self) {
            try await handler.validate(context: context)
        }

        do {
            try await handler.validate(context: context)
        } catch let error as ActionResponse {
            if case .prerequisiteNotMet(let message) = error {
                #expect(message == "Burn what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error")
            }
        }
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
        try await engine.execute("burn pebble", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            """)
    }

}
