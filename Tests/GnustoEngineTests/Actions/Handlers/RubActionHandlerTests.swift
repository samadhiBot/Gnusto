import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RubActionHandler Tests")
struct RubActionHandlerTests {
    let handler = RubActionHandler()

    @Test("Rub validates missing direct object")
    func testRubValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, rawInput: "rub")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Rub what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Rub validates item not reachable")
    func testRubValidatesItemNotReachable() async throws {
        // Given
        let distantSphere = Item(
            id: "distant_sphere",
            .name("distant sphere"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: [distantSphere])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("distant_sphere"), rawInput: "rub distant sphere")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_sphere")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Rub character shows appropriate message")
    func testRubCharacterShowsAppropriateMessage() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("cat"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [cat])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("cat"), rawInput: "rub cat")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("I don't think the cat would appreciate being rubbed."))
    }

    @Test("Rub clean item shows already clean message")
    func testRubCleanItemShowsAlreadyCleanMessage() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("mirror"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [mirror])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("mirror"), rawInput: "rub mirror")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("The mirror is already clean."))
    }

    @Test("Rub lamp shows djinn message")
    func testRubLampShowsDjinnMessage() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("lamp"), rawInput: "rub lamp")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Rubbing the brass lamp doesn't seem to do anything. No djinn appears."))
    }

    @Test("Rub lantern shows djinn message")
    func testRubLanternShowsDjinnMessage() async throws {
        // Given
        let lantern = Item(
            id: "lantern",
            .name("old lantern"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [lantern])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("lantern"), rawInput: "rub lantern")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Rubbing the old lantern doesn't seem to do anything. No djinn appears."))
    }

    @Test("Rub takable object shows smooth touch message")
    func testRubTakableObjectShowsSmoothTouchMessage() async throws {
        // Given
        let stone = Item(
            id: "stone",
            .name("smooth stone"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [stone])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("stone"), rawInput: "rub stone")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You rub the smooth stone. It feels smooth to the touch."))
    }

    @Test("Rub fixed object shows nothing happens message")
    func testRubFixedObjectShowsNothingHappensMessage() async throws {
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

        let command = Command(verb: .rub, directObject: .item("wall"), rawInput: "rub wall")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You rub the stone wall, but nothing interesting happens."))
    }

    @Test("Rub updates state correctly")
    func testRubUpdatesStateCorrectly() async throws {
        // Given
        let orb = Item(
            id: "orb",
            .name("crystal orb"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [orb])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("orb"), rawInput: "rub orb")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.stateChanges.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.stateChanges.contains(where: { change in
            change.entityID == .item("orb") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Rub integration test")
    func testRubIntegrationTest() async throws {
        // Given
        let crystal = Item(
            id: "crystal",
            .name("crystal"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [crystal])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .rub, directObject: .item("crystal"), rawInput: "rub crystal")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("You rub the crystal. It feels smooth to the touch."))
    }
}
