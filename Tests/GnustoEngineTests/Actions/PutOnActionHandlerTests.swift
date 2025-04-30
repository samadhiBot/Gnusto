import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("PutOnActionHandler Tests")
struct PutOnActionHandlerTests {

    // --- Test Setup ---
    let book = Item(
        id: "book",
        name: "heavy book",
        properties: .takable
    )

    let table = Item(
        id: "table",
        name: "sturdy table",
        properties: .surface // It's a surface
    )

    // --- Helper ---
    private func expectedPutOnChanges(
        itemToPutID: ItemID,
        surfaceID: ItemID,
        oldItemProps: Set<ItemProperty>,
        oldSurfaceProps: Set<ItemProperty>
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: Item parent
        changes.append(StateChange(
            entityId: .item(itemToPutID),
            propertyKey: .itemParent,
            oldValue: .parentEntity(.player),
            newValue: .parentEntity(.item(surfaceID))
        ))

        // Change 2: Item touched
        if !oldItemProps.contains(.touched) {
            var newItemProps = oldItemProps
            newItemProps.insert(.touched)
            changes.append(StateChange(
                entityId: .item(itemToPutID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldItemProps),
                newValue: .itemProperties(newItemProps)
            ))
        }

        // Change 3: Surface touched
        if !oldSurfaceProps.contains(.touched) {
            var newSurfaceProps = oldSurfaceProps
            newSurfaceProps.insert(.touched)
            changes.append(StateChange(
                entityId: .item(surfaceID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldSurfaceProps),
                newValue: .itemProperties(newSurfaceProps)
            ))
        }

        // Change 4: Pronoun "it"
        changes.append(StateChange(
            entityId: .global, // Pronoun is global
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemToPutID])
        ))

        return changes
    }

    // --- Tests ---

    @Test("Put item on surface successfully")
    func testPutOnItemSuccessfully() async throws {
        // Arrange: Player holds book, table is reachable
        let initialBook = Item(id: "book", name: "heavy book", properties: .takable, parent: .player)
        let initialTable = Item(id: "table", name: "sturdy table", properties: .surface, parent: .location("startRoom"))
        let initialBookProps = initialBook.properties
        let initialTableProps = initialTable.properties

        let game = MinimalGame(items: [initialBook, initialTable])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "book", indirectObject: "table", preposition: "on", rawInput: "put book on table")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the heavy book on the sturdy table.")

        // Assert Final State
        guard let finalBookState = engine.itemSnapshot(with: "book") else {
            Issue.record("Final book snapshot was nil")
            return
        }
        #expect(finalBookState.parent == .item("table"), "Book should be on the table")
        #expect(finalBookState.hasProperty(.touched) == true, "Book should be touched")

        guard let finalTableState = engine.itemSnapshot(with: "table") else {
            Issue.record("Final table snapshot was nil")
            return
        }
        #expect(finalTableState.hasProperty(.touched) == true, "Table should be touched")

        // Assert Pronoun
        #expect(engine.getPronounReference(pronoun: "it") == ["book"])

        // Assert Change History
        let expectedChanges = expectedPutOnChanges(
            itemToPutID: "book",
            surfaceID: "table",
            oldItemProps: initialBookProps,
            oldSurfaceProps: initialTableProps
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("PutOn fails with no direct object")
    func testPutOnFailsNoDirectObject() async throws {
        // Arrange: Table is reachable
        let table = Item(id: "table", name: "table", properties: .surface, parent: .location("startRoom"))
        let game = MinimalGame(items: [table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", indirectObject: "table", preposition: "on", rawInput: "put on table") // No DO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Put what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails with no indirect object")
    func testPutOnFailsNoIndirectObject() async throws {
        // Arrange: Player holds book
        let book = Item(id: "book", name: "book", parent: .player)
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "book", preposition: "on", rawInput: "put book on") // No IO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Put the book on what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when item not held")
    func testPutOnFailsItemNotHeld() async throws {
        // Arrange: Book is on the floor, table is reachable
        let book = Item(id: "book", name: "heavy book", parent: .location("startRoom"))
        let table = Item(id: "table", name: "sturdy table", properties: .surface, parent: .location("startRoom"))
        let game = MinimalGame(items: [book, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "book", indirectObject: "table", preposition: "on", rawInput: "put book on table")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the heavy book.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when target not reachable")
    func testPutOnFailsTargetNotReachable() async throws {
        // Arrange: Table is in another room, player holds book
        let book = Item(id: "book", name: "heavy book", parent: .player)
        let table = Item(id: "table", name: "sturdy table", properties: .surface, parent: .location("otherRoom"))
        let room1 = Location(id: "startRoom", name: "Start", properties: .inherentlyLit)
        let room2 = Location(id: "otherRoom", name: "Other", properties: .inherentlyLit)
        let game = MinimalGame(locations: [room1, room2], items: [book, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "book", indirectObject: "table", preposition: "on", rawInput: "put book on table")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when target not a surface")
    func testPutOnFailsTargetNotSurface() async throws {
        // Arrange: Target is a box (not surface), player holds book
        let book = Item(id: "book", name: "heavy book", parent: .player)
        let box = Item(id: "box", name: "box", properties: .container, parent: .location("startRoom")) // Not a surface
        let game = MinimalGame(items: [book, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "book", indirectObject: "box", preposition: "on", rawInput: "put book on box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things on the box.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails self-insertion")
    func testPutOnFailsSelfInsertion() async throws {
        // Arrange: Player holds table
        let table = Item(id: "table", name: "table", properties: .surface, .takable, parent: .player)
        let game = MinimalGame(items: [table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "puton", directObject: "table", indirectObject: "table", preposition: "on", rawInput: "put table on table")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put something on itself.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails recursive insertion")
    func testPutOnFailsRecursiveInsertion() async throws {
        // Arrange: Player holds tray, tray is on table
        let tray = Item(id: "tray", name: "silver tray", properties: .surface, .takable, parent: .player)
        let table = Item(id: "table", name: "table", properties: .surface, parent: .item("tray")) // Table is *on* tray (setup for recursive fail)
        let game = MinimalGame(items: [tray, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Try to put the tray onto the table (which is on the tray)
        let command = Command(verbID: "puton", directObject: "tray", indirectObject: "table", preposition: "on", rawInput: "put tray on table")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        // Note: The error message uses "inside" due to the way the check works, might need refinement
        expectNoDifference(output, "You can't put the table inside the silver tray like that.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    // TODO: Add capacity check test when implemented
}
