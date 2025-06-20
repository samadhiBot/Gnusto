import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EatActionHandler Tests")
struct EatActionHandlerTests {

    @Test("Eat validates missing direct object")
    func testEatValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("eat")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat
            Eat what?
            """)
    }

    @Test("Eat validates item not found")
    func testEatValidatesItemNotFound() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("eat nonexistent")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat nonexistent
            You can’t see any nonexistent here.
            """)
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

        let game = MinimalGame(items: distantApple)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("eat distant apple")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat distant apple
            You can’t see any distant apple here.
            """)
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

        let game = MinimalGame(items: apple)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat apple
            You eat the apple. It's quite satisfying.
            """)
    }

    @Test("Eat non-edible item fails")
    func testEatNonEdibleItemFails() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat rock
            You can’t eat the rock.
            """)
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

        let game = MinimalGame(items: lunchBox, sandwich)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat lunch box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat lunch box
            You eat the sandwich from the lunch box.
            """)
    }

    @Test("Eat from empty container fails")
    func testEatFromEmptyContainerFails() async throws {
        // Given
        let emptyBox = Item(
            id: "empty_box",
            .name("empty box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )

        let game = MinimalGame(items: emptyBox)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat empty box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat empty box
            There's nothing to eat in the empty box.
            """)
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

        let game = MinimalGame(items: apple)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then - Check that the item was consumed (removed from game)
        let finalApple = try await engine.item("apple")
        #expect(finalApple.parent == .nowhere)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat apple
            You eat the apple. It's quite satisfying.
            """)
    }
}
