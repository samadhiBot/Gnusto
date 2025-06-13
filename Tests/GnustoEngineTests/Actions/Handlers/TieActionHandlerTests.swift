import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TieActionHandler Tests")
struct TieActionHandlerTests {
    let handler = TieActionHandler()

    @Test("Tie validates missing direct object")
    func testTieValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .tie, rawInput: "tie")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Tie what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Tie rope alone shows knot message")
    func testTieRopeAloneShowsKnotMessage() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [rope])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .tie, directObject: .item("rope"), rawInput: "tie rope")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You tie a knot in the rope."))
    }

    @Test("Tie integration test")
    func testTieIntegrationTest() async throws {
        // Given
        let cord = Item(
            id: "cord",
            .name("cord"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [cord])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .tie, directObject: .item("cord"), rawInput: "tie cord")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("You tie a knot in the cord."))
    }
}
