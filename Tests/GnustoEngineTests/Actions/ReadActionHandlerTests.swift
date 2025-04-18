import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {

    // Helper to setup engine and mocks, adding a read verb
    static func setupTestEnvironment(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.", properties: [.inherentlyLit]) // Assume lit by default
    ) async -> (GameEngine, MockIOHandler, Location, Player, Vocabulary) {
        let player = Player(currentLocationID: initialLocation.id)
        let verbs = [
            Verb(id: "read")
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [initialLocation], // Use potentially modified location
            initialItems: [],
            initialPlayer: player,
            vocabulary: vocabulary
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)
        return (engine, mockIO, initialLocation, player, vocabulary)
    }

    @Test("Read item successfully (held)")
    func testReadItemSuccessfullyHeld() async throws {
        // Arrange
        let book = Item(id: "book", name: "dusty book", properties: [.takable, .readable], readableText: "It reads: \"Beware the Grue!\"")
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [book])
        engine.debugAddItem(id: book.id, name: book.name, properties: book.properties, parent: .player, readableText: book.readableText)

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "book", rawInput: "read book")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "book")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "It reads: \"Beware the Grue!\"")
    }

    @Test("Read item successfully (in lit room)")
    func testReadItemSuccessfullyInLitRoom() async throws {
        // Arrange
        let sign = Item(id: "sign", name: "warning sign", properties: [.readable], readableText: "DANGER AHEAD")
        let litRoom = Location(id: "litRoom", name: "Bright Room", description: "It's bright here.", properties: [.inherentlyLit])
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [sign], initialLocation: litRoom)
        engine.debugAddItem(id: sign.id, name: sign.name, properties: sign.properties, parent: .location(litRoom.id), readableText: sign.readableText)

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "sign", rawInput: "read sign")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "sign")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "DANGER AHEAD")
    }

    @Test("Read fails with no direct object")
    func testReadFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment()
        let handler = ReadActionHandler()
        let command = Command(verbID: "read", rawInput: "read")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Read what?")
    }

    @Test("Read fails item not accessible")
    func testReadFailsItemNotAccessible() async throws {
        // Arrange
        let scroll = Item(id: "scroll", name: "ancient scroll", properties: [.readable], readableText: "Secrets within")
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [scroll])
        engine.debugAddItem(id: scroll.id, name: scroll.name, properties: scroll.properties, parent: .nowhere, readableText: scroll.readableText)

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "scroll", rawInput: "read scroll")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("scroll")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Read fails item not readable")
    func testReadFailsItemNotReadable() async throws {
        // Arrange
        let rock = Item(id: "rock", name: "plain rock", properties: []) // No .readable
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [rock])
        engine.debugAddItem(id: rock.id, name: rock.name, properties: rock.properties, parent: .location(location.id))

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "rock", rawInput: "read rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotReadable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Read fails in dark room (item not lit)")
    func testReadFailsInDarkRoom() async throws {
        // Arrange
        let map = Item(id: "map", name: "folded map", properties: [.takable, .readable], readableText: "X marks the spot")
        let darkRoom = Location(id: "darkRoom", name: "Pitch Black Room", description: "It's dark.") // No .inherentlyLit
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [map], initialLocation: darkRoom)
        engine.debugAddItem(id: map.id, name: map.name, properties: map.properties, parent: .player, readableText: map.readableText) // Held by player

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "map", rawInput: "read map")

        // Act & Assert
        await #expect(throws: ActionError.roomIsDark) {
            try await handler.perform(command: command, engine: engine)
        }
    }

     @Test("Read readable item with no text")
    func testReadReadableItemWithNoText() async throws {
        // Arrange
        let blankPaper = Item(id: "paper", name: "blank paper", properties: [.takable, .readable], readableText: "") // Readable but empty string
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [blankPaper])
        engine.debugAddItem(id: blankPaper.id, name: blankPaper.name, properties: blankPaper.properties, parent: .player, readableText: blankPaper.readableText)

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "paper", rawInput: "read paper")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "paper")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the blank paper.")
    }

    @Test("Read lit item successfully in dark room")
    func testReadLitItemInDarkRoom() async throws {
        // Arrange
        let glowingTablet = Item(id: "tablet", name: "glowing tablet", properties: [.lightSource, .on, .readable], readableText: "Ancient Runes")
        let darkRoom = Location(id: "darkRoom", name: "Pitch Black Room", description: "It's dark.")
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [glowingTablet], initialLocation: darkRoom)
        engine.debugAddItem(id: glowingTablet.id, name: glowingTablet.name, properties: glowingTablet.properties, parent: .player, readableText: glowingTablet.readableText)

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "tablet", rawInput: "read tablet")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "tablet")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "Ancient Runes")
    }
}
