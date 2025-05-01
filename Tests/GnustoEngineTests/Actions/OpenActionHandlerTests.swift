import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
    let handler = OpenActionHandler()

    @Test("Open item successfully")
    func testOpenItemSuccessfully() async throws {
        // Arrange
        let initialProperties: Set<ItemProperty> = [.container, .openable]
        var closedBox = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom")
        )
        closedBox.properties = initialProperties

        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Initial state check
        #expect(engine.item(with: "box")?.hasProperty(.open) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act: Call the engine's execute method to use the full enhanced pipeline
        await engine.execute(command: command)

        // Assert State Change
        let finalItemState = engine.item(with: "box")
        let expectedProperties: Set<ItemProperty> = [.container, .openable, .open, .touched]
        #expect(finalItemState?.properties == expectedProperties, "Item should gain .open and .touched properties")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")

        // Assert Change History
        #expect(engine.gameState.changeHistory.count == 1)
        let recordedChange = engine.gameState.changeHistory.first
        let expectedChange = StateChange(
            entityId: .item("box"),
            propertyKey: .itemProperties,
            oldValue: .itemProperties(initialProperties),
            newValue: .itemProperties(expectedProperties)
        )
        expectNoDifference(recordedChange, expectedChange)
    }

    @Test("Open item that is already touched")
    func testOpenItemAlreadyTouched() async throws {
        // Arrange: Item is openable, closed, and already touched
        let initialProperties: Set<ItemProperty> = [.container, .openable, .touched]
        var closedBox = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom")
        )
        closedBox.properties = initialProperties

        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Initial state check
        #expect(engine.item(with: "box")?.hasProperty(.open) == false)
        #expect(engine.item(with: "box")?.hasProperty(.touched) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act: Call the engine's execute method
        await engine.execute(command: command)

        // Assert State Change
        let finalItemState = engine.item(with: "box")
        let expectedProperties: Set<ItemProperty> = [.container, .openable, .open, .touched]
        #expect(finalItemState?.properties == expectedProperties, "Item should gain .open property and retain .touched")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")

        // Assert Change History
        #expect(engine.gameState.changeHistory.count == 1)
        let recordedChange = engine.gameState.changeHistory.first
        let expectedChange = StateChange(
            entityId: .item("box"),
            propertyKey: .itemProperties,
            oldValue: .itemProperties(initialProperties),
            newValue: .itemProperties(expectedProperties)
        )
        // Change should still happen because .open is added
        expectNoDifference(recordedChange, expectedChange)
    }

    @Test("Open fails with no direct object")
    func testOpenFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "open", rawInput: "open")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Open what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Open fails item not accessible")
    func testOpenFailsItemNotAccessible() async throws {
        // Arrange
        let box = Item(id: "box", name: "box", properties: .openable, parent: .nowhere)
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Open fails item not openable")
    func testOpenFailsItemNotOpenable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
        ) // No .openable

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "rock", rawInput: "open rock")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't open the heavy rock.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Open fails item already open")
    func testOpenFailsItemAlreadyOpen() async throws {
        // Arrange
        let openBox = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .open, // Starts open
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [openBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is already open.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Open fails item is locked")
    func testOpenFailsItemIsLocked() async throws {
        // Arrange
        let lockedChest = Item(
            id: "chest",
            name: "iron chest",
            properties: .container, .openable, .locked,
            parent: .location("startRoom")
        ) // Locked

        let game = MinimalGame(items: [lockedChest])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "open", directObject: "chest", rawInput: "open chest")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The iron chest is locked.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
