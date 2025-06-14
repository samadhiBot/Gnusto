import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ShakeActionHandler Tests")
struct ShakeActionHandlerTests {
    let handler = ShakeActionHandler()

    @Test("Shake validates missing direct object")
    func testShakeValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, rawInput: "shake")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Shake what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Shake container shows rattle message")
    func testShakeContainerShowsRattleMessage() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTakable
        )

        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("box"), rawInput: "shake box")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You shake the wooden box and hear something rattling inside."))
    }

    @Test("Shake bottle shows slosh message")
    func testShakeBottleShowsSloshMessage() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [bottle])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("bottle"), rawInput: "shake bottle")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You shake the glass bottle and hear liquid sloshing inside."))
    }

    @Test("Shake vial shows slosh message")
    func testShakeVialShowsSloshMessage() async throws {
        // Given
        let vial = Item(
            id: "vial",
            .name("small vial"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [vial])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("vial"), rawInput: "shake vial")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You shake the small vial and hear liquid sloshing inside."))
    }

    @Test("Shake fixed object shows different message")
    func testShakeFixedObjectShowsDifferentMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [wall])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("wall"), rawInput: "shake wall")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't shake the stone wall - it's firmly in place."))
    }

    @Test("Shake takable object shows appropriate message")
    func testShakeTakableObjectShowsAppropriateMessage() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("old book"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("book"), rawInput: "shake book")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You shake the old book vigorously, but nothing happens."))
    }

    @Test("Shake updates state correctly")
    func testShakeUpdatesStateCorrectly() async throws {
        // Given
        let jar = Item(
            id: "jar",
            .name("jar"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTakable
        )

        let game = MinimalGame(items: [jar])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("jar"), rawInput: "shake jar")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.changes.contains(where: { change in
            change.entityID == .item("jar") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Shake integration test")
    func testShakeIntegrationTest() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("container"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTakable
        )

        let game = MinimalGame(items: [container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .shake, directObject: .item("container"), rawInput: "shake container")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You shake the container and hear something rattling inside.")
    }
}
