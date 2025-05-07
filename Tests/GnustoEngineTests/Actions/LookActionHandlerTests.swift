import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    // No handler instance needed for engine.execute tests

    // Helper to create the expected StateChange array for examining an item
    private func expectedLookChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        // Only expect a change if .isTouched wasn't already true
        guard initialAttributes[.isTouched] != true else { return [] }

        return [
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([itemID])
            )
        ]
    }

    @Test("LOOK in lit room describes room and lists items")
    func testLookInLitRoom() async throws {
        // Arrange
        let litRoom = Location(
            id: "litRoom",
            name: "Bright Room",
            description: "A brightly lit room.",
            isLit: true
        )
        let item1 = Item(
            id: "table",
            name: "wooden table",
            parent: .location("litRoom"),
            attributes: [
                .isSurface: true
            ]
        )
        let item2 = Item(id: "rug", name: "woven rug", parent: .location("litRoom"))

        let game = MinimalGame(player: Player(in: "litRoom"), locations: [litRoom], items: [item1, item2])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(output, """
            --- Bright Room ---
            A brightly lit room.
            You can see a woven rug here.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK in lit room with multiple items lists them correctly")
    func testLookInLitRoomWithMultipleItems() async throws {
        // Arrange
        let litRoom = Location(
            id: "litRoom",
            name: "Test Room",
            description: "A basic room.",
            isLit: true
        )
        let item1 = Item(
            id: "apple",
            name: "apple",
            parent: .location("litRoom")
        )
        let item2 = Item(
            id: "banana",
            name: "banana",
            parent: .location("litRoom")
        )
        let item3 = Item(
            id: "pear",
            name: "pear",
            parent: .location("litRoom")
        )
        let item4 = Item(
            id: "orange",
            name: "orange",
            parent: .location("litRoom")
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom],
            items: [item4, item3, item2, item1] // Include all 4 items, in reverse order
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see an apple, a banana, an orange, and a pear here.
            """
        )

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK in dark room prints darkness message")
    func testLookInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "You see nothing." // inherentlyLit defaults false
        )
        let item1 = Item(id: "shadow", name: "shadow", parent: .location("darkRoom"))

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        // Corrected Expectation: Darkness message
        expectNoDifference(output, "It is pitch black. You are likely to be eaten by a grue.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK in lit room (via player light) describes room and lists items")
    func testLookInRoomLitByPlayer() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "A dark, damp room."
        )
        let activeLamp = Item(
            id: "lamp",
            name: "brass lamp",
            parent: .player,
            attributes: [
                .isLightSource: true,
                .isOn: true
            ]
        )
        let item1 = Item(id: "table", name: "wooden table", parent: .location(darkRoom.id))

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [activeLamp, item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", rawInput: "look")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output (lit by player)
        expectNoDifference(output, """
            --- Dark Room ---
            A dark, damp room.
            You can see a wooden table here.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK with nil location description uses default")
    func testLookWithDefaultLocationDescription() async throws {
        // Arrange
        let litRoom = Location(
            id: "litRoom",
            name: "Plain Room",
            // No longDescription provided - should be nil by default
            isLit: true
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom]
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "look", rawInput: "look")

        // Act
        await engine.execute(command: command)

        // Assert Output (Uses default description from engine.describe)
        let output = await mockIO.flush()
        // Corrected Expectation: Default description with title
        expectNoDifference(output, """
            --- Plain Room ---
            You are in a nondescript location.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK with dynamic location description closure")
    func testLookWithDynamicLocationDescription() async throws {
        // Arrange
        let flagId: FlagID = "special_flag"

        let dynamicRoom = Location(
            id: "dynamicRoom",
            name: "Magic Room",
            // Provide a default description; dynamic logic will override
            description: "The room seems normal.",
            isLit: true
        )

        // MinimalGame takes flags as variadic arguments
        let game = MinimalGame(
            player: Player(in: "dynamicRoom"),
            locations: [dynamicRoom],
            flags: [flagId] // Keep flag initialization
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        // Register dynamic compute handler for the location's long description
        engine.dynamicAttributeRegistry.registerLocationCompute(key: .longDescription) { _, gameEngine in
            // Use the passed engine to check the flag
            let isFlagOn = engine.isFlagSet(flagId)
            let text = isFlagOn ? "The room *sparkles* brightly via registry." : "The room seems normal via registry."
            // Return StateValue.string
            return .string(text)
        }

        let command = Command(verbID: "look", rawInput: "look")

        // Act 1: Flag is ON
        await engine.execute(command: command)

        // Assert Output 1 (Should show sparkling description)
        let output1 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(output1, """
            --- Magic Room ---
            The room *sparkles* brightly via registry.
            """
        )

        // Act 2: Turn flag OFF and LOOK again
        await engine.clearFlag(flagId) // Use new helper and FlagID
        await engine.execute(command: command)

        // Assert Output 2 (Should show normal description)
        let output2 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(output2, """
            --- Magic Room ---
            The room seems normal via registry.
            """
        )
    }

    // --- LOOK AT / EXAMINE Tests ---

    @Test("LOOK AT item shows description and marks touched")
    func testLookAtItem() async throws {
        // Arrange
        let item = Item(
            id: "rock",
            name: "grey rock",
            description: "Just a plain rock.",
            parent: .location("startRoom")
        )
        let initialAttributes = item.attributes

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("rock")?.hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "rock", rawInput: "x rock")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Just a plain rock.")

        // Assert Final State
        let finalItemState = await engine.item("rock")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "rock", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT item with no description shows default message and marks touched")
    func testLookAtItemNoDescription() async throws {
        // Arrange
        let item = Item(
            id: "pebble",
            name: "smooth pebble",
            parent: .location("startRoom"),
            attributes: [
                .firstDescription: "You notice a small pebble."
            ]
        )
        let initialAttributes = item.attributes

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("pebble")?.hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "look", directObject: "pebble", rawInput: "l pebble")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You notice a small pebble.")

        // Assert Final State
        let finalItemState = await engine.item("pebble")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "pebble", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT already touched item shows description, no state change")
    func testLookAtAlreadyTouchedItem() async throws {
        // Arrange
        let item = Item(
            id: "stone",
            name: "chipped stone",
            description: "A worn stone.",
            parent: .location("startRoom"),
            attributes: [
                .firstDescription: "This shouldn't appear.",
                .isTouched: true
            ]
        )
        let initialAttributes = item.attributes

        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("stone")?.hasFlag(.isTouched) == true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "stone", rawInput: "x stone")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A worn stone.")

        // Assert Final State (remains touched)
        let finalItemState = await engine.item("stone")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should still be marked touched")

        // Assert Change History (Should be empty)
        let expectedChanges = expectedLookChanges(itemID: "stone", initialAttributes: initialAttributes)
        #expect(expectedChanges.isEmpty == true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    // TODO: Add tests for LOOK AT container (open/closed/transparent) and surface

    @Test("LOOK AT open container shows description, contents, and marks touched")
    func testLookAtOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true
            ]
        )
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .item("box"),
            attributes: [
                .isTakable: true
            ]
        )
        let initialAttributes = box.attributes

        let game = MinimalGame(items: [box, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("box")?.hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "box", rawInput: "x box")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents)
        let output = await mockIO.flush()
        expectNoDifference(output, "A wooden box. The wooden box contains a gold coin.")

        // Assert Final State (Container marked touched)
        let finalItemState = await engine.item("box")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "box", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT closed container shows description, closed message, and marks touched")
    func testLookAtClosedContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true
            ]
        )
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .item("box"),
            attributes: [
                .isTakable: true
            ]
        )
        let initialAttributes = box.attributes

        let game = MinimalGame(items: [box, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("box")?.hasFlag(.isTouched) == false)
        #expect(engine.item("box")?.attributes["isOpen"] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "box", rawInput: "x box")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Closed Message)
        let output = await mockIO.flush()
        expectNoDifference(output, "A wooden box. The wooden box is closed.")

        // Assert Final State (Container marked touched)
        let finalItemState = await engine.item("box")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "box", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT closed transparent container shows description, contents, and marks touched")
    func testLookAtTransparentContainer() async throws {
        // Arrange
        let jar = Item(
            id: "jar",
            name: "glass jar",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isTransparent: true
            ]
        )
        let fly = Item(id: "fly", name: "dead fly", parent: .item("jar"))
        let initialAttributes = jar.attributes

        let game = MinimalGame(items: [jar, fly])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("jar")?.hasFlag(.isTouched) == false)
        #expect(engine.item("jar")?.attributes["isOpen"] == nil)
        #expect(engine.item("jar")?.attributes["isTransparent"] == true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "jar", rawInput: "x jar")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents because transparent)
        let output = await mockIO.flush()
        expectNoDifference(output, "A glass jar. The glass jar contains a dead fly.")

        // Assert Final State (Container marked touched)
        let finalItemState = await engine.item("jar")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "jar", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT surface shows description, contents, and marks touched")
    func testLookAtSurface() async throws {
        // Arrange
        let table = Item(
            id: "table",
            name: "kitchen table",
            parent: .location("startRoom"),
            attributes: [
                .isSurface: true
            ]
        )
        let book = Item(id: "book", name: "dusty book", parent: .item("table"))
        let candle = Item(
            id: "candle",
            name: "lit candle",
            parent: .item("table"),
            attributes: [
                .isLightSource: true,
                .isOn: true
            ]
        )
        let initialAttributes = table.attributes

        let game = MinimalGame(items: [table, book, candle])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("table")?.hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "table", rawInput: "x table")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Surface Contents)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            A kitchen table. \
            On the kitchen table is a dusty book and a lit candle.
            """
        )

        // Assert Final State (Surface marked touched)
        let finalItemState = await engine.item("table")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "table", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT item not reachable fails")
    func testLookAtItemNotReachable() async throws {
        // Arrange: Item exists but is in another room
        let item = Item(id: "artifact", name: "glowing artifact", parent: .location("otherRoom"))
        let room1 = Location(id: "startRoom", name: "Start Room", isLit: true)
        let room2 = Location(id: "otherRoom", name: "Other Room") // inherentlyLit defaults false

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [room1, room2],
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item("artifact") != nil) // Item exists
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        #expect(!reachableItems.contains("artifact")) // Not reachable
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "examine", directObject: "artifact", rawInput: "x artifact")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Error message)
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert Final State (Item remains untouched and where it was)
        let finalItemState = await engine.item("artifact")
        #expect(finalItemState?.hasFlag(.isTouched) == false)
        #expect(finalItemState?.parent == .location("otherRoom"))

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}
