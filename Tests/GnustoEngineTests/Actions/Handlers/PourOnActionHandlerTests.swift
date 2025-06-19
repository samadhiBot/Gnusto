import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PourOnActionHandler Tests")
struct PourOnActionHandlerTests {
    let handler = PourOnActionHandler()

    @Test("Pour validates missing direct object")
    func testPourValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .pourOn, rawInput: "pour")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Pour what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Pour validates missing indirect object")
    func testPourValidatesMissingIndirectObject() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )

        let game = MinimalGame(items: [water])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .pourOn, directObject: .item("water"), rawInput: "pour water")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Pour the water on what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Pour water on fire extinguishes flames")
    func testPourWaterOnFireExtinguishesFlames() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )
        let torch = Item(
            id: "torch",
            .name("torch"),
            .in(.location(.startRoom)),
            .isFlammable,
            .isLit
        )

        let game = MinimalGame(items: [water, torch])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .pourOn,
            directObject: .item("water"),
            indirectObject: .item("torch"),
            rawInput: "pour water on torch"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You pour the water on the torch. The flames are extinguished with a hissing sound."))
    }

    @Test("Pour integration test")
    func testPourIntegrationTest() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("water"),
            .in(.location(.startRoom)),
            .isDrinkable
        )
        let flower = Item(
            id: "flower",
            .name("flower"),
            .in(.location(.startRoom)),
            .isPlant
        )

        let game = MinimalGame(items: [water, flower])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .pourOn,
            directObject: .item("water"),
            indirectObject: .item("flower"),
            rawInput: "pour water on flower"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("You pour the water on the flower. It looks refreshed."))
    }
}
