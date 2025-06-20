import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RaiseActionHandler Tests")
struct RaiseActionHandlerTests {
    @Test("Raise item gives default response")
    func testRaiseItemGivesDefaultResponse() async throws {
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.location(.startRoom)),
            .isTakable
        )
        let game = MinimalGame(items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        let initialBook = try await engine.item("book")
        #expect(initialBook.attributes[.isTouched] == nil)

        // Act
        try await engine.execute("raise book")

        // Assert State Change
        let finalBook = try await engine.item("book")
        #expect(finalBook.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> raise book\n\nYou can't lift the heavy book.")
    }

    @Test("Raise fails if item not accessible")
    func testRaiseFailsIfNotAccessible() async throws {
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.nowhere),
            .isTakable
        )
        let game = MinimalGame(items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("raise book")

        let output = await mockIO.flush()
        expectNoDifference(output, "> raise book\n\nYou can't see any heavy book here.")
    }

    @Test("Raise fails with no direct object")
    func testRaiseFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("raise")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> raise\n\nRaise what?")
    }

    @Test("Raise fails with non-item target")
    func testRaiseFailsWithNonItemTarget() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("raise room")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> raise room\n\nYou can only raise items.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Raise fails if item not reachable")
    func testRaiseFailsIfNotReachable() async throws {
        let box = Item(
            id: "box",
            .name("locked box"),
            .in(.location(.startRoom)),
            .isContainer
            // Not open, so contents not reachable
        )
        let book = Item(
            id: "book",
            .name("hidden book"),
            .in(.item("box")),
            .isTakable
        )
        let game = MinimalGame(items: box, book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("raise book")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> raise book\n\nYou can't see any hidden book here.")
    }

    @Test("Raise works on player inventory items")
    func testRaiseWorksOnInventoryItems() async throws {
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("raise coin")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> raise coin\n\nYou can't lift the gold coin.")

        // Assert State Change
        let finalCoin = try await engine.item("coin")
        #expect(finalCoin.attributes[.isTouched] == true)
    }
}
