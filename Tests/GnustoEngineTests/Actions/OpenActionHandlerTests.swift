import CustomDump
import Testing

@testable import GnustoEngine

@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
    // Helper function for expected state changes during a successful open
    private func expectedOpenChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]?
    ) -> [StateChange] {
        var changes: [StateChange] = []
        
        // Change 1: isOpen becomes true
        changes.append(
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isOpen),
                oldValue: initialAttributes?[.isOpen], // Check initial state
                newValue: true,
            )
        )
        
        // Change 2: Item touched (if needed)
        if initialAttributes?[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: initialAttributes?[.isTouched],
                    newValue: true,
                )
            )
        }
        
        // Change 3: Pronoun "it"
        changes.append(
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil, // Assume no prior "it" for simplicity
                newValue: .itemIDSet([itemID])
            )
        )
        
        return changes
    }
    
    @Test("Open item successfully")
    func testOpenItemSuccessfully() async throws {
        // Arrange
        let closedBox = Item(
            id: "box",
            name: "wooden box",
            .in(.location("startRoom")),
            .isContainer,
            .isOpenable
            // Starts closed (no .isOpen attribute)
        )
        
        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        
        // Initial state check
        let initialBoxState = await engine.item("box")
        #expect(!initialBoxState!.hasFlag(.isOpen), "Box should start closed")
        #expect(!initialBoxState!.hasFlag(.isTouched), "Box should start untouched")
        #expect(await engine.gameState.changeHistory.isEmpty == true)
        
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")
        
        // Act: Call the engine's execute method
        await engine.execute(command: command)
        
        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")
        
        // Assert Change History
        let expectedChanges = expectedOpenChanges(
            itemID: "box",
            initialAttributes: initialBoxState?.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
        
        // Optional: Verify final state via snapshot if needed for complex scenarios,
        // but primarily rely on change history for handler correctness.
        let finalBoxState = await engine.item("box")
        #expect(finalBoxState?.hasFlag(.isOpen) == true, "Box should be open")
        #expect(finalBoxState?.hasFlag(.isTouched) == true, "Box should be touched")
    }
    
    @Test("Open item that is already touched")
    func testOpenItemAlreadyTouched() async throws {
        // Arrange: Item is openable, closed, and already touched
        let closedBox = Item(
            id: "box",
            name: "wooden box",
            .in(.location("startRoom")),
            .isContainer,
            .isOpenable,
            .isTouched // Already touched
        )
        
        let game = MinimalGame(items: [closedBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        
        // Initial state check
        let initialBoxState = await engine.item("box")
        #expect(!initialBoxState!.hasFlag(.isOpen), "Box should start closed")
        #expect(initialBoxState!.hasFlag(.isTouched), "Box should start touched")
        #expect(await engine.gameState.changeHistory.isEmpty == true)
        
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")
        
        // Act: Call the engine's execute method
        await engine.execute(command: command)
        
        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")
        
        // Assert Change History
        let expectedChanges = expectedOpenChanges(itemID: "box", initialAttributes: initialBoxState?.attributes)
        // Should not include .isTouched change as it was already true
        #expect(expectedChanges.count == 2) // isOpen + pronoun
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
        
        // Optional: Verify final state
        let finalBoxState = await engine.item("box")
        #expect(finalBoxState?.hasFlag(.isOpen) == true, "Box should be open")
        #expect(finalBoxState?.hasFlag(.isTouched) == true, "Box should still be touched")
    }
    
    @Test("Open fails with no direct object")
    func testOpenFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
    
    @Test("Open fails item not accessible")
    func testOpenFailsItemNotAccessible() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "box",
            .in(.nowhere),
            .isOpenable
            // Don't need .isOpen here, it's not reachable anyway
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")
        
        // Act
        await engine.execute(command: command)
        
        // Assert Output
        let output = await mockIO.flush()
        // Updated expected message for inaccessible items
        expectNoDifference(output, "You can't see any such thing.")
        
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
    
    @Test("Open fails item not openable")
    func testOpenFailsItemNotOpenable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "heavy rock",
            .in(.location("startRoom"))
        ) // No .openable
        
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
    
    @Test("Open fails item already open")
    func testOpenFailsItemAlreadyOpen() async throws {
        // Arrange
        let openBox = Item(
            id: "box",
            name: "wooden box",
            .in(.location("startRoom")),
            .isContainer,
            .isOpenable,
            .isOpen // Already open
        )
        
        let game = MinimalGame(items: [openBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
    
    @Test("Open fails item is locked")
    func testOpenFailsItemIsLocked() async throws {
        // Arrange
        let lockedChest = Item(
            id: "chest",
            name: "iron chest",
            .in(.location("startRoom")),
            .isContainer,
            .isOpenable,
            .isLocked // Locked
        ) // Locked
        
        let game = MinimalGame(items: [lockedChest])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}
