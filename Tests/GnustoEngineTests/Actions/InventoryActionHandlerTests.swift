import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {
    @Test("Inventory shows items held")
    func testInventoryShowsItemsHeld() async throws {
        let game = MinimalGame(
            items: [
                Item(id: "key", name: "brass key", parent: .player),
                Item(id: "lamp", name: "brass lamp", parent: .player),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = InventoryActionHandler()
        let command = Command(verbID: "inventory", rawInput: "inventory")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You are carrying:
              A brass key
              A brass lamp
            """
        )
    }

    @Test("Inventory shows empty message")
    func testInventoryShowsEmptyMessage() async throws {
        let game = MinimalGame(
            items: [
                Item(id: "key", name: "brass key", parent: .location("startRoom")),
                Item(id: "lamp", name: "brass lamp", parent: .location("startRoom")),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = InventoryActionHandler()
        let command = Command(verbID: "inventory", rawInput: "inventory")

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You are empty-handed.")
    }
}
