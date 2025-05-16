import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PutOnActionHandler Tests")
struct PutOnActionHandlerTests {

    // — Test Setup —
    let book = Item(
        id: "book",
        .name("heavy book"),
        .isTakable
    )

    let table = Item(
        id: "table",
        .name("sturdy table"),
        .isSurface
    )

    // — Helper —
    private func expectedPutOnChanges(
        itemToPutID: ItemID,
        surfaceID: ItemID,
        oldItemAttributes: [AttributeID: StateValue],
        oldSurfaceAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: Item parent
        changes.append(
            StateChange(
                entityID: .item(itemToPutID),
                attributeKey: .itemParent,
                oldValue: .parentEntity(.player),
                newValue: .parentEntity(.item(surfaceID))
            )
        )

        // Change 2: Item touched (if needed)
        if oldItemAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemToPutID),
                    attributeKey: .itemAttribute(.isTouched),
                        newValue: true,
                )
            )
        }

        // Change 3: Surface touched (if needed)
        if oldSurfaceAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(surfaceID),
                    attributeKey: .itemAttribute(.isTouched),
                        newValue: true,
                )
            )
        }

        // Change 4: Pronoun "it"
        changes.append(
            StateChange(
                entityID: .global, // Pronoun is global
                attributeKey: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(itemToPutID)])
            )
        )

        return changes
    }

    // — Tests —

    @Test("Put item on surface successfully")
    func testPutOnItemSuccessfully() async throws {
        // Arrange: Player holds book, table is reachable
        let initialBook = Item(
            id: "book",
            .name("heavy book"),
            .in(.player),
            .isTakable
        )
        let initialTable = Item(
            id: "table",
            .name("sturdy table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let initialBookAttributes = initialBook.attributes
        let initialTableAttributes = initialTable.attributes

        let game = MinimalGame(items: [initialBook, initialTable])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("book")),
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put book on table"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the heavy book on the sturdy table.")

        // Assert Final State
        let finalBookState = try await engine.item("book")
        #expect(finalBookState.parent == .item("table"), "Book should be on the table")
        #expect(finalBookState.hasFlag(.isTouched), "Book should be touched")

        let finalTableState = try await engine.item("table")
        #expect(finalTableState.hasFlag(.isTouched), "Table should be touched")

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == [.item(ItemID("book"))])

        // Assert Change History
        let expectedChanges = expectedPutOnChanges(
            itemToPutID: "book",
            surfaceID: "table",
            oldItemAttributes: initialBookAttributes,
            oldSurfaceAttributes: initialTableAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("PutOn fails with no direct object")
    func testPutOnFailsNoDirectObject() async throws {
        // Arrange: Table is reachable
        let table = Item(
            id: "table",
            .name("table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let game = MinimalGame(items: [table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put on table"
        ) // No DO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Put what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails with no indirect object")
    func testPutOnFailsNoIndirectObject() async throws {
        // Arrange: Player holds book
        let book = Item(
            id: "book",
            .name("book"),
            .in(.player)
        )
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("book")),
            preposition: "on",
            rawInput: "put book on"
        ) // No IO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Put the book on what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when item not held")
    func testPutOnFailsItemNotHeld() async throws {
        // Arrange: Book is on the floor, table is reachable
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.location(.startRoom))
        )
        let table = Item(
            id: "table",
            .name("sturdy table"),
            .in(.location(.startRoom)),
            .isSurface
        )
        let game = MinimalGame(items: [book, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("book")),
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put book on table"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren’t holding the heavy book.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when target not reachable")
    func testPutOnFailsTargetNotReachable() async throws {
        // Arrange: Table is in another room, player holds book
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.player)
        )
        let table = Item(
            id: "table",
            .name("sturdy table"),
            .in(.location("otherRoom")),
            .isSurface
        )
        let room1 = Location(
            id: .startRoom,
            .name("Start"),
            .inherentlyLit
        )
        let room2 = Location(
            id: "otherRoom",
            .name("Other"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [room1, room2], items: [book, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("book")),
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put book on table"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails when target not a surface")
    func testPutOnFailsTargetNotSurface() async throws {
        // Arrange: Target is a box (not surface), player holds book
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.player)
        )
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isContainer // Not a surface
        )
        let game = MinimalGame(items: [book, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("book")),
            indirectObject: .item(ItemID("box")),
            preposition: "on",
            rawInput: "put book on box"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t put things on the box.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails self-insertion")
    func testPutOnFailsSelfInsertion() async throws {
        // Arrange: Player holds table
        let table = Item(
            id: "table",
            .name("table"),
            .in(.player),
            .isSurface,
        )
        let game = MinimalGame(items: [table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("table")),
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put table on table"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t put something on itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("PutOn fails recursive insertion")
    func testPutOnFailsRecursiveInsertion() async throws {
        // Arrange: Player holds tray, tray is on table
        let tray = Item(
            id: "tray",
            .name("silver tray"),
            .in(.player),
            .isSurface,
            .isTakable
        )
        let table = Item(
            id: "table",
            .name("table"),
            .in(.item("tray")),
            .isSurface // Table is also a surface
        )
        let game = MinimalGame(items: [tray, table])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Try to put the tray onto the table (which is on the tray)
        let command = Command(
            verb: .putOn,
            directObject: .item(ItemID("tray")),
            indirectObject: .item(ItemID("table")),
            preposition: "on",
            rawInput: "put tray on table"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        // Note: The error message uses "inside" due to the way the check works, might need refinement
        expectNoDifference(output, "You can’t put the table inside the silver tray like that.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    // TODO: Add capacity check test when implemented
}
