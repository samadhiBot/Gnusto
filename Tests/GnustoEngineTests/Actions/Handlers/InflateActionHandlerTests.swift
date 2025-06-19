import CustomDump
import Testing

import GnustoEngine

@Suite("InflateActionHandler")
struct InflateActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let inflatedBalloon = Item(
            id: "inflatedBalloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .isInflated,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: [balloon, inflatedBalloon, coin]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        let engine = await GameEngine.test(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("INFLATE command on inflatable item")
    func testInflateCommand() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(
            verb: .inflate,
            directObject: .item("balloon"),
            rawInput: "inflate balloon"
        )

        // Check initial state
        let initialState = try await engine.hasFlag(.isInflated, on: "balloon")
        print("Initial inflate state: \(initialState)")

        // Execute the command through the engine to properly apply state changes
        await engine.execute(command: command)

        // Check output
        let output = await mockIO.flush()
        expectNoDifference(output, "You inflate the balloon.")

        // Verify balloon is now inflated
        #expect(try await engine.hasFlag(.isInflated, on: "balloon") == true)
    }

    @Test("INFLATE command on already inflated item")
    func testInflateAlreadyInflatedItem() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(
            verb: .inflate,
            directObject: .item("inflatedBalloon"),
            rawInput: "inflate balloon"
        )

        // Execute the command through the engine to properly apply state changes
        await engine.execute(command: command)

        // Check output
        let output = await mockIO.flush()
        expectNoDifference(output, "The balloon is already inflated.")
    }

    @Test("INFLATE command without direct object")
    func testInflateWithoutObject() async throws {
        let (engine, _) = await createTestEngine()
        let handler = InflateActionHandler()
        let command = Command(
            verb: .inflate,
            rawInput: "inflate"
        )
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
        let (engine, _) = await createTestEngine()
        let handler = InflateActionHandler()
        let command = Command(
            verb: .inflate,
            directObject: .item("coin"),
            rawInput: "inflate coin"
        )
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
