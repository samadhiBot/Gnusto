import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DrinkActionHandler Tests")
struct DrinkActionHandlerTests {

    @Test("Drink validates missing direct object")
    func testDrinkValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("drink")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink
            Drink what?
            """)
    }

    @Test("Drink validates item not found")
    func testDrinkValidatesItemNotFound() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("drink nonexistent")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink nonexistent
            You can’t see any nonexistent here.
            """)
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

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: distantWater)
        )

        // When / Then
        try await engine.execute("drink distant water")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink distant water
            You can’t see any distant water here.
            """)
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

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: water)
        )

        // When
        try await engine.execute("drink water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink water
            You drink the water. It's quite refreshing.
            """)
    }

    @Test("Drink non-drinkable item fails")
    func testDrinkNonDrinkableItemFails() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: rock)
        )

        // When
        try await engine.execute("drink rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink rock
            You can’t drink the rock.
            """)
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

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: bottle, wine)
        )

        // When
        try await engine.execute("drink bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink bottle
            You drink the wine from the bottle. Refreshing!
            """)
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

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: closedBottle, juice)
        )

        // When
        try await engine.execute("drink closed bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink closed bottle
            You can’t drink from the closed bottle while it's closed.
            """)
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

        let (engine, mockIO) = await GameEngine.test(
            blueprint: MinimalGame(items: water)
        )

        // When
        try await engine.execute("drink water")

        // Then - Check that the item was consumed (removed from game)
        let finalWater = try await engine.item("water")
        #expect(finalWater.parent == .nowhere)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink water
            You drink the water. It's quite refreshing.
            """)
    }
}
