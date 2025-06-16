import CustomDump
import Testing

@testable import GnustoEngine

@Suite("WaveActionHandler Tests")
struct WaveActionHandlerTests {
    let handler = WaveActionHandler()

    @Test("Wave validates missing direct object")
    func testWaveValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, rawInput: "wave")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Wave what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Wave validates item not reachable")
    func testWaveValidatesItemNotReachable() async throws {
        // Given
        let distantWand = Item(
            id: "distant_wand",
            .name("distant wand"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: [distantWand])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("distant_wand"), rawInput: "wave distant wand")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_wand")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Wave wand shows magical message")
    func testWaveWandShowsMagicalMessage() async throws {
        // Given
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWand
        )

        let game = MinimalGame(items: [wand])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("wand"), rawInput: "wave wand")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You wave the magic wand dramatically, but nothing magical happens."))
    }

    @Test("Wave staff shows magical message")
    func testWaveStaffShowsMagicalMessage() async throws {
        // Given
        let staff = Item(
            id: "staff",
            .name("wooden staff"),
            .in(.location(.startRoom)),
            .isTakable,
            .isStaff
        )

        let game = MinimalGame(items: [staff])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("staff"), rawInput: "wave staff")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You wave the wooden staff dramatically, but nothing magical happens."))
    }

    @Test("Wave sword shows brandish message")
    func testWaveSwordShowsBrandishMessage() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("sharp sword"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWeapon
        )

        let game = MinimalGame(items: [sword])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("sword"), rawInput: "wave sword")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You brandish the sharp sword menacingly."))
    }

    @Test("Wave blade shows brandish message")
    func testWaveBladeShowsBrandishMessage() async throws {
        // Given
        let blade = Item(
            id: "blade",
            .name("razor blade"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWeapon
        )

        let game = MinimalGame(items: [blade])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("blade"), rawInput: "wave blade")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You brandish the razor blade menacingly."))
    }

    @Test("Wave flag shows appropriate message")
    func testWaveFlagShowsAppropriateMessage() async throws {
        // Given
        let flag = Item(
            id: "flag",
            .name("red flag"),
            .in(.location(.startRoom)),
            .isTakable,
            .isFlag
        )

        let game = MinimalGame(items: [flag])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("flag"), rawInput: "wave flag")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You wave the red flag around. It's not particularly impressive."))
    }

    @Test("Wave fixed object shows different message")
    func testWaveFixedObjectShowsDifferentMessage() async throws {
        // Given
        let tree = Item(
            id: "tree",
            .name("large tree"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [tree])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("tree"), rawInput: "wave tree")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't wave the large tree around - it's not something you can pick up and wave."))
    }

    @Test("Wave updates state correctly")
    func testWaveUpdatesStateCorrectly() async throws {
        // Given
        let wand = Item(
            id: "wand",
            .name("wand"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [wand])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("wand"), rawInput: "wave wand")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.changes.contains(where: { change in
            change.entityID == .item("wand") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Wave integration test")
    func testWaveIntegrationTest() async throws {
        // Given
        let staff = Item(
            id: "staff",
            .name("staff"),
            .in(.location(.startRoom)),
            .isTakable,
            .isStaff
        )

        let game = MinimalGame(items: [staff])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .wave, directObject: .item("staff"), rawInput: "wave staff")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You wave the staff dramatically, but nothing magical happens.")
    }
}
