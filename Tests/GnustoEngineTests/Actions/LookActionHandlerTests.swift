import Testing
import CustomDump

@testable import GnustoEngine

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    // No handler instance needed for engine.execute tests

    // Helper to create the expected StateChange array for examining an item
    private func expectedLookChanges(
        itemID: ItemID,
        initialAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        // Only expect a change if .isTouched wasn’t already true
        guard initialAttributes[.isTouched] != true else { return [] }

        return [
            StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isTouched),
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(itemID)])
            )
        ]
    }

    @Test("LOOK in lit room describes room and lists items")
    func testLookInLitRoom() async throws {
        // Arrange
        let litRoom = Location(
            id: "litRoom",
            .name("Bright Room"),
            .description("A brightly lit room."),
            .inherentlyLit,
            .localGlobals("ceiling")
        )
        let item1 = Item(
            id: "table",
            .name("wooden table"),
            .in(.location("litRoom")),
            .isSurface
        )
        let item2 = Item(
            id: "rug",
            .name("woven rug"),
            .in(.location("litRoom"))
        )
        let item3 = Item(
            id: "chair",
            .name("modern looking chair"),
            .in(.location("litRoom"))
        )
        let item4 = Item(
            id: "ceiling",
            .name("vaulted ceiling"),
            .isScenery
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom],
            items: [item1, item2, item3, item4]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(output, """
            — Bright Room —

            A brightly lit room.
            You can see a modern looking chair, a woven rug, and a wooden table here.
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
            .name("Test Room"),
            .description("A basic room."),
            .inherentlyLit
        )
        let item1 = Item(
            id: "apple",
            .in(.location("litRoom"))
        )
        let item2 = Item(
            id: "banana",
            .in(.location("litRoom"))
        )
        let item3 = Item(
            id: "pear",
            .in(.location("litRoom"))
        )
        let item4 = Item(
            id: "orange",
            .in(.location("litRoom"))
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

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(output, """
            — Test Room —

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
            .name("Dark Room"),
            .description("You see nothing.") // inherentlyLit defaults false
        )
        let item1 = Item(
            id: "shadow",
            .in(.location("darkRoom"))
        )

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

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

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
            .name("Dark Room"),
            .description("A dark, damp room.")
        )
        let activeLamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .in(.player),
            .isLightSource,
            .isOn
        )
        let item1 = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(darkRoom.id))
        )

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

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output (lit by player)
        expectNoDifference(output, """
            — Dark Room —

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
            .name("Plain Room"),
            // No description provided - should be nil by default
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom]
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output (Uses default description from engine.describe)
        let output = await mockIO.flush()
        // Corrected Expectation: Default description with title
        expectNoDifference(output, """
            — Plain Room —

            You are in a nondescript location.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK with dynamic location description closure")
    func testLookWithDynamicLocationDescription() async throws {
        // Arrange
        let globalID: GlobalID = "special_flag"

        let dynamicRoom = Location(
            id: "dynamicRoom",
            .name("Magic Room"),
            // Provide a default description; dynamic logic will override
            .description("The room seems normal."),
            .inherentlyLit
        )

        // MinimalGame takes flags as variadic arguments
        let game = MinimalGame(
            player: Player(in: "dynamicRoom"),
            locations: [dynamicRoom],
            globalState: [globalID: true]
        )

        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        // Register dynamic compute handler for the location's long description
        await engine.registerLocationCompute(key: .description) { location, gameState in
            let isFlagOn = gameState.globalState[globalID] == true
            let text = isFlagOn ? "The room *sparkles* brightly via registry." :
            "The room seems normal via registry."
            return .string(text)
        }

        let command = Command(
            verb: .look,
            rawInput: "look"
        )

        // Act 1: Flag is ON
        await engine.execute(command: command)

        // Assert Output 1 (Should show sparkling description)
        let output1 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(output1, """
            — Magic Room —

            The room *sparkles* brightly via registry.
            """
        )

        // Act 2: Turn flag OFF and LOOK again
        await engine.clearFlag(globalID) // Use new helper and GlobalID
        await engine.execute(command: command)

        // Assert Output 2 (Should show normal description)
        let output2 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(output2, """
            — Magic Room —

            The room seems normal via registry.
            """
        )
    }

    // — LOOK AT / EXAMINE Tests —

    @Test("LOOK AT item shows description and marks touched")
    func testLookAtItem() async throws {
        // Arrange
        let item = Item(
            id: "rock",
            .name("grey rock"),
            .description("Just a plain rock."),
            .in(.location(.startRoom))
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
        #expect(try await engine.item("rock").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("rock"),
            rawInput: "x rock"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Just a plain rock.")

        // Assert Final State
        let finalItemState = try await engine.item("rock")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should be marked touched")

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
            .name("smooth pebble"),
            .in(.location(.startRoom)),
            .firstDescription("You notice a small pebble.")
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
        #expect(try await engine.item("pebble").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .look,
            directObject: .item("pebble"),
            rawInput: "l pebble"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You see nothing special about the smooth pebble.")

        // Assert Final State
        let finalItemState = try await engine.item("pebble")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should be marked touched")

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
            .name("chipped stone"),
            .description("A worn stone."),
            .in(.location(.startRoom)),
            .firstDescription("This shouldn’t appear."),
            .isTouched
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
        #expect(try await engine.item("stone").hasFlag(.isTouched) == true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("stone"),
            rawInput: "x stone"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A worn stone.")

        // Only change is pronoun change
        #expect(await engine.gameState.changeHistory == [
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item("stone")])
            )
        ])
        #expect(await engine.gameState.changeHistory.count == 1)

        // Assert Final State (remains touched)
        let finalItemState = try await engine.item("stone")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should still be marked touched")

        // Assert Change History (Should be empty)
        let expectedChanges = expectedLookChanges(itemID: "stone", initialAttributes: initialAttributes)
        #expect(expectedChanges.isEmpty == true)
        #expect(await engine.gameState.changeHistory.count == 1)
    }

    // TODO: Add tests for LOOK AT container (open/closed/transparent) and surface

    @Test("LOOK AT open container shows description, contents, and marks touched")
    func testLookAtOpenContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .description("On its lid is a rough carving of a skull."),
            .isContainer,
            .isOpenable,
            .isOpen
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("box")),
            .isTakable
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
        #expect(try await engine.item("box").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("box"),
            rawInput: "x box"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "On its lid is a rough carving of a skull. The wooden box contains a gold coin."
        )

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("box")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

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
            .description("On its lid is a rough carving of a skull."),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .name("wooden box"),
        )
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("box")),
            .isTakable
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
        #expect(try await engine.item("box").hasFlag(.isTouched) == false)
        #expect(try await engine.item("box").attributes["isOpen"] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("box"),
            rawInput: "x box"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Closed Message)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "On its lid is a rough carving of a skull. The wooden box is closed."
        )

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("box")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

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
            .name("glass jar"),
            .in(.location(.startRoom)),
            .description("An old canning jar, probably from the 1940s."),
            .isContainer,
            .isOpenable,
            .isTransparent
        )
        let fly = Item(
            id: "fly",
            .name("dead fly"),
            .in(.item("jar"))
        )
        let initialAttributes = jar.attributes

        let game = MinimalGame(items: [jar, fly])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("jar").hasFlag(.isTouched) == false)
        #expect(try await engine.item("jar").attributes["isOpen"] == nil)
        #expect(try await engine.item("jar").attributes["isTransparent"] == true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("jar"),
            rawInput: "x jar"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Contents because transparent)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "An old canning jar, probably from the 1940s. The glass jar contains a dead fly."
        )

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("jar")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

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
            .name("kitchen table"),
            .description("A shabby wooden table, worn from years of use."),
            .in(.location(.startRoom)),
            .isSurface
        )
        let book = Item(
            id: "book",
            .name("dusty book"),
            .in(.item("table"))
        )
        let candle = Item(
            id: "candle",
            .name("lit candle"),
            .in(.item("table")),
            .isLightSource,
            .isOn
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
        #expect(try await engine.item("table").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("table"),
            rawInput: "x table"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Description + Surface Contents)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            A shabby wooden table, worn from years of use. \
            On the kitchen table is a dusty book and a lit candle.
            """
        )

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("table")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(itemID: "table", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT item not reachable fails")
    func testLookAtItemNotReachable() async throws {
        // Arrange: Item exists but is in another room
        let artifact = Item(
            id: "artifact",
            .name("glowing artifact"),
            .in(.location("otherRoom"))
        )
        let room1 = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let room2 = Location(
            id: "otherRoom",
            .description("A very dark room.")
        ) // inherentlyLit defaults false

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: [room1, room2],
            items: [artifact]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("artifact") == artifact)
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        #expect(!reachableItems.contains("artifact")) // Not reachable
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .examine,
            directObject: .item("artifact"),
            rawInput: "x artifact"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Error message)
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        // Assert Final State (Item remains untouched and where it was)
        let finalItemState = try await engine.item("artifact")
        #expect(finalItemState.hasFlag(.isTouched) == false)
        #expect(finalItemState.parent == .location("otherRoom"))

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("LOOK AT item in room shows description and sets touched")
    func testLookAtItemInRoom() async throws {
        // Arrange
        let itemID: ItemID = "desk"
        let roomID: LocationID = "office"
        let desk = Item(
            id: itemID,
            .name("large wooden desk"),
            .description("A large, imposing wooden desk."),
            .in(.location(roomID))
        )
        let office = Location(
            id: roomID,
            .name("Office"),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: roomID),
            locations: [office],
            items: [desk]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Command for LOOK AT (often parsed as EXAMINE with DO)
        let command = Command(
            verb: .look, // Could also be .examine depending on parser aliasing
            directObject: .item(itemID),
            rawInput: "look at desk"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A large, imposing wooden desk.")

        // Assert State Change
        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedLookChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT item held shows description and sets touched")
    func testLookAtItemHeld() async throws {
        // Arrange
        let itemID: ItemID = "note"
        let note = Item(
            id: itemID,
            .name("crumpled note"),
            .description("A note with faint writing."),
            .in(.player)
        )
        let game = MinimalGame(items: [note])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verb: .look, // or .examine
            directObject: .item(itemID),
            rawInput: "look at note"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "A note with faint writing.")

        // Assert State Change
        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedLookChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("LOOK AT non-existent item")
    func testLookAtNonExistentItem() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .look, // or .examine
            directObject: .item("unicorn"),
            rawInput: "look at unicorn"
        )

        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("LOOK AT item not in scope")
    func testLookAtItemNotInScope() async throws {
        let item = Item(id: "artifact", .name("ancient artifact"), .in(.nowhere))
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .look, // or .examine
            directObject: .item("artifact"),
            rawInput: "look at artifact"
        )

        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
