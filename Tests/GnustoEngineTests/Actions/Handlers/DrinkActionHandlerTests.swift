import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DrinkActionHandler Tests")
struct DrinkActionHandlerTests {
    let handler = DrinkActionHandler()

    @Test("Drink validates missing direct object")
    func testDrinkValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, rawInput: "drink")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Drink what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Drink validates item not found")
    func testDrinkValidatesItemNotFound() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, directObject: .item("nonexistent"), rawInput: "drink nonexistent")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Drink validates item not reachable")
    func testDrinkValidatesItemNotReachable() async throws {
        // Given
        let distantWater = Item(
            id: "distant_water",
            .name("distant water"),
            .in(.nowhere),
            .isDrinkable
        )

        let game = MinimalGame(items: [distantWater])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, directObject: .item("distant_water"), rawInput: "drink distant water")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_water")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Drink drinkable item succeeds")
    func testDrinkDrinkableItemSucceeds() async throws {
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

        let command = Command(verb: .drink, directObject: .item("water"), rawInput: "drink water")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You drink the water. It's quite refreshing."))
    }

    @Test("Drink non-drinkable item fails")
    func testDrinkNonDrinkableItemFails() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, directObject: .item("rock"), rawInput: "drink rock")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't drink the rock."))
    }

    @Test("Drink from container succeeds")
    func testDrinkFromContainerSucceeds() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("bottle"),
            .in(.location(.startRoom)),
            .isContainer,
            .isDrinkable,
            .isOpen
        )

        let wine = Item(
            id: "wine",
            .name("wine"),
            .in(.item("bottle")),
            .isDrinkable
        )

        let game = MinimalGame(items: [bottle, wine])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, directObject: .item("bottle"), rawInput: "drink bottle")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You drink the wine from the bottle. Refreshing!"))
    }

    @Test("Drink from closed container fails")
    func testDrinkFromClosedContainerFails() async throws {
        // Given
        let closedBottle = Item(
            id: "closed_bottle",
            .name("closed bottle"),
            .in(.location(.startRoom)),
            .isContainer,
            .isDrinkable
        )

        let juice = Item(
            id: "juice",
            .name("juice"),
            .in(.item("closed_bottle")),
            .isDrinkable
        )

        let game = MinimalGame(items: [closedBottle, juice])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .drink, directObject: .item("closed_bottle"), rawInput: "drink closed bottle")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't drink the closed bottle."))
    }

    @Test("Drink item and check state changes")
    func testDrinkItemAndCheckStateChanges() async throws {
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

        let command = Command(verb: .drink, directObject: .item("water"), rawInput: "drink water")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Apply the state changes to the engine
        for change in result.changes {
            try await engine.apply(change)
        }

        // Then - Check that the item was removed (moved to .nowhere) and touched
        #expect(result.changes.count >= 2)

        // Check that water was consumed (removed from game)
        let finalWater = try await engine.item("water")
        #expect(finalWater.parent == .nowhere)
    }
}
