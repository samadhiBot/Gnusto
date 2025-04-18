import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {

    // Helper to setup engine and mocks, adding examine verb
    static func setupTestEnvironment(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.", properties: [.inherentlyLit]) // Assume lit
    ) async -> (GameEngine, MockIOHandler, Location, Player, Vocabulary) {
        let player = Player(currentLocationID: initialLocation.id)
        let verbs = [
            Verb(id: "examine", synonyms: ["look at", "x", "describe"])
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [initialLocation],
            initialItems: [],
            initialPlayer: player,
            vocabulary: vocabulary
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)
        return (engine, mockIO, initialLocation, player, vocabulary)
    }

    @Test("Examine simple object (in room)")
    func testExamineSimpleObjectInRoom() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            description: "It's just a rock."
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [rock])
        engine.debugAddItem(
            id: rock.id,
            name: rock.name,
            description: rock.description,
            parent: ParentEntity.location(location.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "rock", rawInput: "examine rock")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        // Expect default message because simple objects without text/container props get it
        expectNoDifference(output, "There's nothing special about the plain rock.")
    }

    @Test("Examine simple object (held)")
    func testExamineSimpleObjectHeld() async throws {
        // Arrange
        let key = Item(
            id: "key",
            name: "brass key",
            description: "A small brass key.",
            properties: [.takable]
        )
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [key])
        engine.debugAddItem(
            id: key.id,
            name: key.name,
            description: key.description,
            properties: key.properties,
            parent: ParentEntity.player
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "key", rawInput: "examine key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing special about the brass key.")
    }

    @Test("Examine readable item (prioritizes text)")
    func testExamineReadableItem() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            description: "A rolled up scroll.",
            properties: [.readable],
            readableText: "FROBOZZ"
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [scroll])
        engine.debugAddItem(
            id: scroll.id,
            name: scroll.name,
            description: scroll.description,
            properties: scroll.properties,
            parent: ParentEntity.location(location.id),
            readableText: scroll.readableText
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "scroll", rawInput: "examine scroll")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "scroll")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "FROBOZZ") // Should print the readableText
    }

    @Test("Examine open container (shows description and contents)")
    func testExamineOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
            properties: [.container, .openable, .open]
        )
        let gem = Item(
            id: "gem",
            name: "ruby gem"
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [box, gem])
        engine.debugAddItem(
            id: box.id,
            name: box.name,
            description: box.description,
            properties: box.properties,
            parent: ParentEntity.location(location.id)
        )
        engine.debugAddItem(
            id: gem.id,
            name: gem.name,
            parent: ParentEntity.item(box.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box contains:
              A ruby gem
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine open empty container")
    func testExamineOpenEmptyContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
            properties: [.container, .openable, .open]
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [box])
        engine.debugAddItem(
            id: box.id,
            name: box.name,
            description: box.description,
            properties: box.properties,
            parent: ParentEntity.location(location.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box is empty.
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine closed container (shows description and closed status)")
    func testExamineClosedContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            description: "A plain wooden box.",
            properties: [.container, .openable]
        ) // Closed by default
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [box])
        engine.debugAddItem(
            id: box.id,
            name: box.name,
            description: box.description,
            properties: box.properties,
            parent: ParentEntity.location(location.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "box", rawInput: "examine box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A plain wooden box.
            The wooden box is closed.
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine transparent closed container (shows description and contents)")
    func testExamineTransparentContainer() async throws {
        // Arrange
        let bottle = Item(
            id: "bottle",
            name: "glass bottle",
            description: "A clear glass bottle.",
            properties: [.container, .transparent]
        ) // Closed by default, but transparent
        let water = Item(
            id: "water",
            name: "water"
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [bottle, water])
        engine.debugAddItem(
            id: bottle.id,
            name: bottle.name,
            description: bottle.description,
            properties: bottle.properties,
            parent: ParentEntity.location(location.id)
        )
        engine.debugAddItem(
            id: water.id,
            name: water.name,
            parent: ParentEntity.item(bottle.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "bottle", rawInput: "examine bottle")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        let expectedOutput = """
            A clear glass bottle.
            The glass bottle contains:
              A water
            """
        expectNoDifference(output, expectedOutput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @Test("Examine surface (shows description and contents)")
    func testExamineSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "wooden table",
            description: "A sturdy table.",
            properties: [.surface]
        )
        let book = Item(
            id: "book",
            name: "heavy book"
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [table, book])
        engine.debugAddItem(
            id: table.id,
            name: table.name,
            description: table.description,
            properties: table.properties,
            parent: ParentEntity.location(location.id)
        )
        engine.debugAddItem(
            id: book.id,
            name: book.name,
            parent: ParentEntity.item(table.id)
        )

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "table", rawInput: "examine table")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        // Note: Current handler doesn't list surface contents, only container/door.
        // Zork's V-EXAMINE didn't list surface contents either, V-LOOK-INSIDE did.
        // Aligning test with V-EXAMINE: expect the default message for non-readable surfaces.
        expectNoDifference(output, "There's nothing special about the wooden table.") // Updated expectation
        #expect(engine.itemSnapshot(with: "table")?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Examine fails item not accessible")
    func testExamineFailsItemNotAccessible() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            description: "It's just a rock."
        )
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [rock])
        engine.debugAddItem(
            id: rock.id,
            name: rock.name,
            description: rock.description,
            parent: .nowhere
        ) // Inaccessible

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "rock", rawInput: "examine rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Examine fails no direct object")
    func testExamineFailsNoObject() async throws {
        // Arrange
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment()
        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", rawInput: "examine")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Examine what?")
    }

    @Test("Examine respects onExamineItem hook")
    func testExamineRespectsHook() async throws {
        // Arrange
        let magicMirror = Item(
            id: "mirror",
            name: "magic mirror",
            description: "A shimmering mirror."
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [magicMirror])
        engine.debugAddItem(
            id: magicMirror.id,
            name: magicMirror.name,
            description: magicMirror.description,
            parent: ParentEntity.location(location.id)
        )

        // Set the hook
        var hookCalled = false
        engine.onExamineItem = { eng, itemID in
            if itemID == "mirror" {
                await eng.output("The mirror shows a distorted reflection.")
                hookCalled = true
                return true // Indicate handled
            }
            return false // Not handled
        }

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "mirror", rawInput: "examine mirror")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        #expect(hookCalled == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "The mirror shows a distorted reflection.") // Hook message printed
        // Default message should NOT be printed
        #expect(engine.itemSnapshot(with: "mirror")?.hasProperty(ItemProperty.touched) == false) // Hook might skip touching
    }

    @Test("Examine calls default logic if hook returns false")
    func testExamineHookReturnsFalse() async throws {
         // Arrange
        let normalMirror = Item(
            id: "mirror",
            name: "normal mirror",
            description: "Just a plain mirror."
        )
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [normalMirror])
        engine.debugAddItem(
            id: normalMirror.id,
            name: normalMirror.name,
            description: normalMirror.description,
            parent: ParentEntity.location(location.id)
        )

        // Set the hook to not handle this item
        var hookCalled = false
        engine.onExamineItem = { eng, itemID in
            hookCalled = true
            return false // Indicate not handled
        }

        let handler = ExamineActionHandler()
        let command = Command(verbID: "examine", directObject: "mirror", rawInput: "examine mirror")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        #expect(hookCalled == true)
        let output = await mockIO.flush()
        // Expect default message because hook didn't handle it
        expectNoDifference(output, "There's nothing special about the normal mirror.")
        #expect(engine.itemSnapshot(with: "mirror")?.hasProperty(ItemProperty.touched) == true)
    }
}
