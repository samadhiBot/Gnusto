import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CutActionHandler Tests")
struct CutActionHandlerTests {
    let handler = CutActionHandler()

    @Test("Cut validates missing direct object")
    func testCutValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .cut, rawInput: "cut")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Cut what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Cut validates item not found")
    func testCutValidatesItemNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .cut, directObject: .item("nonexistent"), rawInput: "cut nonexistent")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Cut validates item not reachable")
    func testCutValidatesItemNotReachable() async throws {
        // Given
        let distantRope = Item(
            id: "distant_rope",
            .name("distant rope"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: [distantRope])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .cut, directObject: .item("distant_rope"), rawInput: "cut distant rope")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_rope")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Cut with tool validates tool not held")
    func testCutWithToolValidatesToolNotHeld() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let knife = Item(
            id: "knife",
            .name("knife"),
            .in(.location(.startRoom)),
            .isWeapon
        )

        let game = MinimalGame(items: [rope, knife])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .cut,
            directObject: .item("rope"),
            indirectObject: .item("knife"),
            rawInput: "cut rope with knife"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotHeld("knife")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Cut rope with knife")
    func testCutRopeWithKnife() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let knife = Item(
            id: "knife",
            .name("knife"),
            .in(.player),
            .isWeapon
        )

        let game = MinimalGame(items: [rope, knife])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .cut,
            directObject: .item("rope"),
            indirectObject: .item("knife"),
            rawInput: "cut rope with knife"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You cut the rope with the knife."))
    }

    @Test("Cut with tool")
    func testCutWithTool() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let scissors = Item(
            id: "scissors",
            .name("scissors"),
            .in(.player),
            .isTool
        )

        let game = MinimalGame(items: [rope, scissors])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .cut,
            directObject: .item("rope"),
            indirectObject: .item("scissors"),
            rawInput: "cut rope with scissors"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You cut the rope with the scissors."))
    }

    @Test("Cut without tool auto-detects")
    func testCutWithoutToolAutoDetects() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let knife = Item(
            id: "knife",
            .name("knife"),
            .in(.player),
            .isWeapon
        )

        let game = MinimalGame(items: [rope, knife])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .cut, directObject: .item("rope"), rawInput: "cut rope")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You cut the rope with the knife."))
    }

    @Test("Cut without appropriate tool")
    func testCutWithoutAppropriateTool() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.player)
        )

        let game = MinimalGame(items: [rope, lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .cut, directObject: .item("rope"), rawInput: "cut rope")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You have no suitable cutting tool."))
    }

    @Test("Cut updates state correctly")
    func testCutUpdatesStateCorrectly() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("rope"),
            .in(.location(.startRoom))
        )

        let knife = Item(
            id: "knife",
            .name("knife"),
            .in(.player),
            .isWeapon
        )

        let game = MinimalGame(items: [rope, knife])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .cut,
            directObject: .item("rope"),
            indirectObject: .item("knife"),
            rawInput: "cut rope with knife"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Find the state change that marks the rope as touched
        let touchedStateChange = result.changes.first { change in
            change.attribute == .itemAttribute(.isTouched)
        }
        #expect(touchedStateChange != nil)
    }
}
