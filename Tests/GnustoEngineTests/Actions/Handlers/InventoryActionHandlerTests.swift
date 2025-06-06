import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {
    @Test("Inventory shows items held")
    func testInventoryShowsItemsHeld() async throws {
        let game = MinimalGame(
            items: [
                Item(
                    id: "brassKey",
                    .name("brass key"),
                    .in(.player)
                ),
                Item(
                    id: "antiqueLamp",
                    .name("antique lamp"),
                    .in(.player)
                ),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .inventory,
            rawInput: "inventory"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You are carrying:
            - An antique lamp
            - A brass key
            """
        )
    }

    @Test("Inventory shows empty message")
    func testInventoryShowsEmptyMessage() async throws {
        let game = MinimalGame(
            items: [
                Item(
                    id: "key",
                    .name("brass key"),
                    .in(.location(.startRoom))
                ),
                Item(
                    id: "lamp",
                    .name("brass lamp"),
                    .in(.location(.startRoom))
                ),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .inventory,
            rawInput: "inventory"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You are empty-handed.")
    }
}
