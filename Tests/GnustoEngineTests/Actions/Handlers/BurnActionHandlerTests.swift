import CustomDump
import GnustoEngine
import Testing

@Suite("BurnActionHandler")
struct BurnActionHandlerTests {
    func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        return (engine, mockIO)
    }

    @Test("BURN without object uses MessageProvider for error")
    func testBurnWithoutObject() async throws {
        let (engine, _) = await createTestEngine()
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
        let (engine, mockIO) = await createTestEngine()
        let command = Command(
            verb: .dance,
            directObject: .item(.startItem),
            rawInput: "burn pebble"
        )

        // Act
        try await engine.execute("burn pebble")
        try await engine.execute("burn pebble")
        try await engine.execute("burn pebble")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You dance an adorable little jig.
            
            You dance with wild abandon. Bravo!
            
            You perform a modern interpretive dance.
            """)
    }

}
