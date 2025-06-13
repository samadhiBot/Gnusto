import CustomDump
import Foundation
import GnustoEngine
import Testing

@Suite("BlowActionHandler")
struct BlowActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> GameEngine {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isTakable,
            .in(.player)
        )

        let candle = Item(
            id: "candle",
            .name("candle"),
            .isLightSource,
            .isLit,
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing blow commands.")
        )

        let game = MinimalGame(
            locations: [testRoom],
            items: [balloon, candle]
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

    @Test("BLOW command without object")
    func testBlowCommandNoObject() async throws {
        let engine = await createTestEngine()
        let handler = BlowActionHandler()
        let command = Command(verb: .blow, rawInput: "blow")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide general blowing message
        let result = try await handler.process(context: context)
        #expect(result.message == "You blow air around. Nothing happens.")
    }

    @Test("BLOW command on object")
    func testBlowCommandOnObject() async throws {
        let engine = await createTestEngine()
        let handler = BlowActionHandler()
        let command = Command(verb: .blow, directObject: "balloon", rawInput: "blow balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide object-specific blowing message
        let result = try await handler.process(context: context)
        #expect(result.message?.contains("You blow on the balloon") == true)

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))
    }

    @Test("BLOW command on lit light source")
    func testBlowOnLitLightSource() async throws {
        let engine = await createTestEngine()
        let handler = BlowActionHandler()
        let command = Command(verb: .blow, directObject: "candle", rawInput: "blow candle")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide light source specific message
        let result = try await handler.process(context: context)
        #expect(result.message?.contains("You blow on the candle, but it doesn't go out") == true)

        // Verify candle is marked as touched
        let candleAfter = try await engine.item("candle")
        #expect(candleAfter.hasFlag(.isTouched))
    }

    @Test("BLOW command on flammable object")
    func testBlowOnFlammableObject() async throws {
        let engine = await createTestEngine()

        // Add a flammable item
        let paper = Item(
            id: "paper",
            .name("paper"),
            .isFlammable,
            .isTakable,
            .in(.location("testRoom"))
        )

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addItem(paper),
            oldValue: nil,
            newValue: true
        ))

        let handler = BlowActionHandler()
        let command = Command(verb: .blow, directObject: "paper", rawInput: "blow paper")
        let context = ActionContext(command: command, engine: engine)

        // Should validate successfully
        try await handler.validate(context: context)

        // Should provide flammable item specific message
        let result = try await handler.process(context: context)
        #expect(result.message?.contains("Blowing on the paper has no effect") == true)

        // Verify paper is marked as touched
        let paperAfter = try await engine.item("paper")
        #expect(paperAfter.hasFlag(.isTouched))
    }

    @Test("BLOW command on inaccessible item")
    func testBlowInaccessibleItem() async throws {
        let engine = await createTestEngine()

        // Add an item in another location
        let distantBalloon = Item(
            id: "distantBalloon",
            .name("distant balloon"),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .description("A distant room.")
        )

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addLocation(anotherRoom),
            oldValue: nil,
            newValue: true
        ))

        try await engine.apply(StateChange(
            entityID: .global,
            attribute: .addItem(distantBalloon),
            oldValue: nil,
            newValue: true
        ))

        let handler = BlowActionHandler()
        let command = Command(verb: .blow, directObject: "distantBalloon", rawInput: "blow distant balloon")
        let context = ActionContext(command: command, engine: engine)

        // Should fail validation due to item not being accessible
        do {
            try await handler.validate(context: context)
            Issue.record("Expected validation to fail for inaccessible item")
        } catch let response as ActionResponse {
            if case .itemNotAccessible(let itemID) = response {
                #expect(itemID.rawValue == "distantBalloon")
            } else {
                Issue.record("Expected itemNotAccessible error, got: \(response)")
            }
        }
    }
}
