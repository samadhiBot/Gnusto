import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {

    // Helper (adapted from previous tests)
    @MainActor
    static func createTestData(itemsToAdd: [Item] = [], initialLocations: [Location] = [], initialPlayerLocationID: LocationID? = nil) -> (items: [Item], locations: [Location], player: Player, vocab: Vocabulary) {
        var locations = initialLocations
        if locations.isEmpty {
            locations.append(Location(id: "room1", name: "Room 1", description: "First room."))
        }
        let playerLocation = initialPlayerLocationID ?? locations[0].id
        let player = Player(currentLocationID: playerLocation)

        // Add movement verbs to vocab
        let verbs = [
            Verb(id: "go"), // Assuming "go" itself is a verb
            Verb(id: "north", synonyms: ["n"]),
            Verb(id: "south", synonyms: ["s"]),
            Verb(id: "east", synonyms: ["e"]),
            Verb(id: "west", synonyms: ["w"])
            // Add other directions/verbs as needed
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        return (items: itemsToAdd, locations: locations, player: player, vocab: vocabulary)
    }

    @Test("Go successfully changes location")
    @MainActor
    func testGoSuccessfullyChangesLocation() async throws {
        // Arrange: Create two locations with an exit connecting them
        let loc1 = Location(
            id: "start",
            name: "Start Room",
            description: "You are here.",
            properties: [.inherentlyLit]
        )
        let loc2 = Location(
            id: "end",
            name: "End Room",
            description: "You went there.",
            properties: [.inherentlyLit]
        )
        loc1.exits[.north] = Exit(destination: "end")

        let testData = Self.createTestData(initialLocations: [loc1, loc2], initialPlayerLocationID: "start")

        // Arrange: Engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: testData.locations,
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = GoActionHandler()
        // Command representing "go north" or just "north"
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check player location changed
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "end", "Player should be in the end room")

        // Check new location was described
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- End Room ---
            You went there.
            """
        )
    }

    @Test("Go fails for invalid direction")
    @MainActor
    func testGoFailsInvalidDirection() async throws {
        // Arrange: Location with no exit to the south
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        #expect(loc1.exits[.south] == nil) // Verify no south exit

        let testData = Self.createTestData(initialLocations: [loc1], initialPlayerLocationID: "start")

        // Arrange: Engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: testData.locations,
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = GoActionHandler()
        let command = Command(verbID: "south", direction: .south, rawInput: "south")

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.invalidDirection) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start", "Player should still be in the start room")
    }

    @Test("Go fails for closed door")
    @MainActor
    func testGoFailsClosedDoor() async throws {
        // Arrange: Locations with a closed door exit
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        loc1.exits[.north] = Exit(destination: "end", isDoor: true, isOpen: false) // Door, explicitly closed

        let testData = Self.createTestData(initialLocations: [loc1, loc2], initialPlayerLocationID: "start")

        // Arrange: Engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: testData.locations,
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error
        // Check the error message includes the direction
        await #expect(throws: ActionError.directionIsBlocked("The north door is closed.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    @Test("Go fails for locked door")
    @MainActor
    func testGoFailsLockedDoor() async throws {
        // Arrange: Locations with a locked (but potentially open) door exit
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        // Note: A door can be locked but technically open (e.g., gate)
        loc1.exits[.north] = Exit(destination: "end", isDoor: true, isOpen: true, isLocked: true)

        let testData = Self.createTestData(initialLocations: [loc1, loc2], initialPlayerLocationID: "start")

        // Arrange: Engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: testData.locations,
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.directionIsBlocked("The north door seems to be locked.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    @Test("Go fails with specific blocked message")
    @MainActor
    func testGoFailsBlockedMessage() async throws {
        // Arrange: Locations with an exit having a blockedMessage
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        let blockMsg = "A chasm blocks your path."
        loc1.exits[.north] = Exit(destination: "end", blockedMessage: blockMsg)

        let testData = Self.createTestData(initialLocations: [loc1, loc2], initialPlayerLocationID: "start")

        // Arrange: Engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: testData.locations,
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error with the custom message
        await #expect(throws: ActionError.directionIsBlocked(blockMsg)) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    // Add more tests here...
}
