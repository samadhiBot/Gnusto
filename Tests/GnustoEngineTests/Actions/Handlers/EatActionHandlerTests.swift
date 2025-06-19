import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EatActionHandler Tests")
struct EatActionHandlerTests {
    let handler = EatActionHandler()

    @Test("Eat validates missing direct object")
    func testEatValidatesMissingDirectObject() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .eat, rawInput: "eat")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Eat what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Eat validates item not found")
    func testEatValidatesItemNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .eat, directObject: .item("nonexistent"), rawInput: "eat nonexistent")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Eat validates item not reachable")
    func testEatValidatesItemNotReachable() async throws {
        // Given
        let distantApple = Item(
            id: "distant_apple",
            .name("distant apple"),
            .in(.nowhere),
            .isEdible
        )

        let game = MinimalGame(items: [distantApple])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("distant_apple"), rawInput: "eat distant apple")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_apple")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Eat edible item succeeds")
    func testEatEdibleItemSucceeds() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("apple"),
            .in(.location(.startRoom)),
            .isEdible
        )

        let game = MinimalGame(items: [apple])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("apple"), rawInput: "eat apple")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You eat the apple. It's quite satisfying."))
    }

    @Test("Eat non-edible item fails")
    func testEatNonEdibleItemFails() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("rock"), rawInput: "eat rock")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't eat the rock."))
    }

    @Test("Eat from container succeeds")
    func testEatFromContainerSucceeds() async throws {
        // Given
        let lunchBox = Item(
            id: "lunch_box",
            .name("lunch box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )

        let sandwich = Item(
            id: "sandwich",
            .name("sandwich"),
            .in(.item("lunch_box")),
            .isEdible
        )

        let game = MinimalGame(items: [lunchBox, sandwich])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("lunch_box"), rawInput: "eat lunch box")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You eat the sandwich from the lunch box."))
    }

    @Test("Eat from empty container fails")
    func testEatFromEmptyContainerFails() async throws {
        // Given
        let emptyBox = Item(
            id: "empty_box",
            .name("empty box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isDrinkable
        )

        let water = Item(
            id: "water",
            .name("water"),
            .in(.item("empty_box")),
            .isDrinkable
        )

        let game = MinimalGame(items: [emptyBox, water])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("empty_box"), rawInput: "eat empty box")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("There's nothing to eat in the empty box."))
    }

    @Test("Eat item and check state changes")
    func testEatItemAndCheckStateChanges() async throws {
        // Given
        let apple = Item(
            id: "apple",
            .name("apple"),
            .in(.location(.startRoom)),
            .isEdible
        )

        let game = MinimalGame(items: [apple])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .eat, directObject: .item("apple"), rawInput: "eat apple")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Apply the state changes to the engine
        for change in result.changes {
            try await engine.apply(change)
        }

        // Then - Check that the item was removed (moved to .nowhere) and touched
        #expect(result.changes.count >= 2)

        // Check that apple was consumed (removed from game)
        let finalApple = try await engine.item("apple")
        #expect(finalApple.parent == .nowhere)
    }
}
