import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {
    let handler = InventoryActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    // MARK: - Syntax Rule Testing

    @Test("INVENTORY syntax works")
    func testInventorySyntax() async throws {
        let lamp = Item(id: "lamp", .name("brass lantern"), .in(.player))
        let game = MinimalGame(player: Player(in: "room"), items: [lamp])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("inventory")
        let output = await mockIO.flush()
        #expect(output.contains("You are carrying:"))
        #expect(output.contains("A brass lantern"))
    }

    @Test("I alias works")
    func testIAlias() async throws {
        let lamp = Item(id: "lamp", .name("brass lantern"), .in(.player))
        let game = MinimalGame(player: Player(in: "room"), items: [lamp])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("i")
        let output = await mockIO.flush()
        #expect(output.contains("You are carrying:"))
    }

    // MARK: - Processing Testing

    @Test("Shows correct message when inventory is empty")
    func testProcessEmptyInventory() async throws {
        let game = MinimalGame(player: Player(in: "room"))
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("inventory")
        let output = await mockIO.flush()
        #expect(output.contains("You are empty-handed."))
    }

    @Test("Shows a sorted list of items")
    func testProcessShowsSortedItems() async throws {
        let lamp = Item(id: "lamp", .name("brass lantern"), .in(.player))
        let book = Item(id: "book", .name("book"), .in(.player))
        let apple = Item(id: "apple", .name("apple"), .in(.player))

        let game = MinimalGame(player: Player(in: "room"), items: [lamp, book, apple])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("inventory")
        let output = await mockIO.flush()

        let expectedOrder = """
            You are carrying:
              - An apple
              - A book
              - A brass lantern
            """

        // Normalize whitespace and compare
        let normalizedOutput = output.split(whereSeparator: \.isNewline).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")
        let normalizedExpected = expectedOrder.split(whereSeparator: \.isNewline).map {
            $0.trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")

        #expect(normalizedOutput.contains(normalizedExpected))
    }

    // MARK: - ActionID Testing

    @Test("INVENTORY action resolves to InventoryActionHandler")
    func testInventoryActionID() async throws {
        let game = MinimalGame(player: Player(in: "room"))
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        let parser = StandardParser()
        let command = try parser.parse("inventory")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is InventoryActionHandler)
    }
}
