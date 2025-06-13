import CustomDump
import Foundation
import GnustoEngine
import Testing

@Suite("InflateActionHandler")
struct InflateActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> GameEngine {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing inflate commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [balloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    private func createTestEngineWithInflatedBalloon() async -> GameEngine {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .isInflated,
            .in(.player)
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing inflate commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [balloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    // MARK: - Tests

    @Test("INFLATE command on inflatable item")
    func testInflateCommand() async throws {
        let engine = await createTestEngine()
        let handler = InflateActionHandler()
        let command = Command(verb: .inflate, directObject: .item("balloon"), rawInput: "inflate balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should inflate the balloon
        let result = try await handler.process(context: context)
        #expect(result.message == "You inflate the balloon.")

        // Verify balloon is now inflated
        #expect(try await engine.hasFlag(.isInflated, on: "balloon"))
    }

    @Test("INFLATE command on already inflated item")
    func testInflateAlreadyInflatedItem() async throws {
        let engine = await createTestEngineWithInflatedBalloon()

        let handler = InflateActionHandler()
        let command = Command(verb: .inflate, directObject: .item("balloon"), rawInput: "inflate balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide "already inflated" message
        let result = try await handler.process(context: context)
        #expect(result.message == "The balloon is already inflated.")
    }

    @Test("INFLATE command without direct object")
    func testInflateWithoutObject() async throws {
        let engine = await createTestEngine()
        let handler = InflateActionHandler()
        let command = Command(verb: .inflate, rawInput: "inflate")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for inflate without object")
        } catch let response as ActionResponse {
            if case .prerequisiteNotMet(let message) = response {
                #expect(message == "Inflate what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error, got: \(response)")
            }
        }
    }

    @Test("INFLATE command on non-inflatable item")
    func testInflateNonInflatableItem() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.player)
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing inflate commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [balloon, coin]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = InflateActionHandler()
        let command = Command(verb: .inflate, directObject: .item("coin"), rawInput: "inflate coin")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for non-inflatable item")
        } catch let response as ActionResponse {
            if case .prerequisiteNotMet(let message) = response {
                #expect(message == "You can't inflate the coin.")
            } else {
                Issue.record("Expected prerequisiteNotMet error, got: \(response)")
            }
        }
    }
}
