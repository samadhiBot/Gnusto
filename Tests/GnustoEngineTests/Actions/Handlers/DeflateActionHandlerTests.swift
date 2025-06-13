import CustomDump
import Foundation
import GnustoEngine
import Testing

@Suite("DeflateActionHandler")
struct DeflateActionHandlerTests {
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
            .description("A room for testing deflate commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [balloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        return GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )
    }

    // MARK: - Tests

    @Test("DEFLATE command on inflated item")
    func testDeflateCommand() async throws {
        let engine = await createTestEngine()

        // First inflate the balloon
        try await engine.apply(StateChange(
            entityID: .item("balloon"),
            attribute: .setFlag(.isInflated),
            oldValue: nil,
            newValue: true
        ))

        let handler = DeflateActionHandler()
        let command = Command(verb: .deflate, directObject: "balloon", rawInput: "deflate balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should deflate the balloon
        let result = try await handler.process(context: context)
        #expect(result.message == "You deflate the balloon.")

        // Verify balloon is no longer inflated
        let balloonAfter = try await engine.item("balloon")
        #expect(!balloonAfter.hasFlag(.isInflated))
    }

    @Test("DEFLATE command on non-inflated item")
    func testDeflateNotInflatedItem() async throws {
        let engine = await createTestEngine()
        let handler = DeflateActionHandler()
        let command = Command(verb: .deflate, directObject: "balloon", rawInput: "deflate balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide "not inflated" message
        let result = try await handler.process(context: context)
        #expect(result.message == "The balloon is not inflated.")
    }

    @Test("DEFLATE command without direct object")
    func testDeflateWithoutObject() async throws {
        let engine = await createTestEngine()
        let handler = DeflateActionHandler()
        let command = Command(verb: .deflate, rawInput: "deflate")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for deflate without object")
        } catch let response as ActionResponse {
            if case .prerequisiteNotMet(let message) = response {
                #expect(message == "Deflate what?")
            } else {
                Issue.record("Expected prerequisiteNotMet error, got: \(response)")
            }
        }
    }

    @Test("DEFLATE command on non-inflatable item")
    func testDeflateNonInflatableItem() async throws {
        let engine = await createTestEngine()

        // Add a non-inflatable item
        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.player)
        )

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addItem(coin),
            oldValue: nil,
            newValue: true
        ))

        let handler = DeflateActionHandler()
        let command = Command(verb: .deflate, directObject: "coin", rawInput: "deflate coin")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for non-inflatable item")
        } catch let response as ActionResponse {
            if case .prerequisiteNotMet(let message) = response {
                #expect(message == "You can't deflate the coin.")
            } else {
                Issue.record("Expected prerequisiteNotMet error, got: \(response)")
            }
        }
    }
}
