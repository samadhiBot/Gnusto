import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SqueezeActionHandler Tests")
struct SqueezeActionHandlerTests {
    let handler = SqueezeActionHandler()

    @Test("Squeeze validates missing direct object")
    func testSqueezeValidatesMissingDirectObject() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, rawInput: "squeeze")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Squeeze what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Squeeze sponge shows water drip message")
    func testSqueezeSpongeShowsWaterDripMessage() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("wet sponge"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSponge
        )

        let game = MinimalGame(items: [sponge])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("sponge"), rawInput: "squeeze sponge")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the wet sponge and water drips out."))
    }

    @Test("Squeeze tube shows ooze message")
    func testSqueezeeTubeShowsOozeMessage() async throws {
        // Given
        let tube = Item(
            id: "tube",
            .name("toothpaste tube"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: [tube])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("tube"), rawInput: "squeeze tube")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the toothpaste tube and some of its contents ooze out."))
    }

    @Test("Squeeze bottle shows ooze message")
    func testSqueezeBottleShowsOozeMessage() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("plastic bottle"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: [bottle])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("bottle"), rawInput: "squeeze bottle")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the plastic bottle and some of its contents ooze out."))
    }

    @Test("Squeeze pillow shows soft message")
    func testSqueezePillowShowsSoftMessage() async throws {
        // Given
        let pillow = Item(
            id: "pillow",
            .name("soft pillow"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSoft
        )

        let game = MinimalGame(items: [pillow])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("pillow"), rawInput: "squeeze pillow")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the soft pillow. It feels soft and yielding."))
    }

    @Test("Squeeze cushion shows soft message")
    func testSqueezeCushionShowsSoftMessage() async throws {
        // Given
        let cushion = Item(
            id: "cushion",
            .name("cushion"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [cushion])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("cushion"), rawInput: "squeeze cushion")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the cushion as hard as you can, but it doesn't give."))
    }

    @Test("Squeeze hard object shows appropriate message")
    func testSqueezeHardObjectShowsAppropriateMessage() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("hard rock"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [rock])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("rock"), rawInput: "squeeze rock")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You squeeze the hard rock as hard as you can, but it doesn't give."))
    }

    @Test("Squeeze updates state correctly")
    func testSqueezeUpdatesStateCorrectly() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("sponge"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSponge
        )

        let game = MinimalGame(items: [sponge])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("sponge"), rawInput: "squeeze sponge")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.changes.contains(where: { change in
            change.entityID == .item("sponge") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Squeeze integration test")
    func testSqueezeIntegrationTest() async throws {
        // Given
        let tube = Item(
            id: "tube",
            .name("tube"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: [tube])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .squeeze, directObject: .item("tube"), rawInput: "squeeze tube")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You squeeze the tube and some of its contents ooze out.")
    }
}
