import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    // No handler instance needed for engine.execute tests

    // Helper to create the expected StateChange array for examining an item
    private func expectedLookChanges(
        itemID: ItemID,
        initialAttributes: [ItemAttributeID: StateValue]
    ) -> [StateChange] {
        // Only expect a change if .isTouched wasn't already true
        guard initialAttributes[.isTouched] != true else { return [] }

        return [
            StateChange(
                entityID: .item(itemID),
                attribute: .itemAttribute(.isTouched),
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(itemID)])
            ),
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
            .omitDescription
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: litRoom,
            items: item1, item2, item3, item4
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("look")

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(
            output,
            """
            > look

            — Bright Room —

            A brightly lit room.

            There are a modern looking chair, a woven rug, and a wooden
            table here.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
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
            locations: litRoom,
            items: item4, item3, item2, item1  // Include all 4 items, in reverse order
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("look")

        // Assert Output (primary check for LOOK)
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output
        expectNoDifference(
            output,
            """
            > look

            — Test Room —

            A basic room.

            There are an apple, a banana, an orange, and a pear here.
            """
        )

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("LOOK in dark room prints darkness message")
    func testLookInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("You see nothing.")  // inherentlyLit defaults false
        )
        let item1 = Item(
            id: "shadow",
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: item1
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("look")

        // Assert Output
        let output = await mockIO.flush()
        // Corrected Expectation: Darkness message
        expectNoDifference(output, "> look\n\nIt is pitch black. You can't see a thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
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
            player: Player(in: darkRoom.id),
            locations: darkRoom,
            items: activeLamp, item1
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("look")

        // Assert Output
        let output = await mockIO.flush()
        // Corrected Expectation: Full formatted output (lit by player)
        expectNoDifference(
            output,
            """
            > look

            — Dark Room —

            A dark, damp room.

            There is a wooden table here.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
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
            locations: litRoom
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("look")

        // Assert Output (Uses default description from engine.describe)
        let output = await mockIO.flush()
        // Corrected Expectation: Default description with title
        expectNoDifference(
            output,
            """
            > look

            — Plain Room —

            You are in a nondescript location.
            """
        )
        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("LOOK with dynamic location description closure")
    func testLookWithDynamicLocationDescription() async throws {
        // Arrange
        let specialFlag: GlobalID = "specialFlag"

        let dynamicRoom = Location(
            id: "dynamicRoom",
            .name("Magic Room"),
            // Provide a default description; dynamic logic will override
            .description("The room seems normal."),
            .inherentlyLit
        )

        // MinimalGame takes flags as variadic arguments
        let game = MinimalGame(
            player: Player(in: dynamicRoom.id),
            locations: dynamicRoom,
            locationComputers: [
                dynamicRoom.id: LocationComputer { attributeID, gameState in
                    let isFlagOn = gameState.globalState[specialFlag] == true
                    let text =
                        isFlagOn
                        ? "The room *sparkles* brightly via registry."
                        : "The room seems normal via registry."
                    return .string(text)
                }
            ]
        )

        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            globalState: [specialFlag: true],
            parser: MockParser()
        )

        // Act 1: Flag is ON
        try await engine.execute("look")

        // Assert Output 1 (Should show sparkling description)
        let output1 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(
            output1,
            """
            > look

            — Magic Room —

            The room *sparkles* brightly via registry.
            """
        )

        // Act 2: Turn flag OFF and LOOK again
        try await engine.apply(
            StateChange(
                entityID: .global,
                attribute: .globalState(attributeID: specialFlag),
                oldValue: true,
                newValue: false
            )
        )
        try await engine.execute("look")

        // Assert Output 2 (Should show normal description)
        let output2 = await mockIO.flush()
        // Corrected Expectation: Dynamic description with title
        expectNoDifference(
            output2,
            """
            > look

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

        let game = MinimalGame(items: item)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("rock").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("look at rock")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> look at rock\n\nJust a plain rock.")

        // Assert Final State
        let finalItemState = try await engine.item("rock")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "rock", initialAttributes: initialAttributes)
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

        let game = MinimalGame(items: item)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("pebble").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("l pebble")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> l pebble\n\nYou see nothing special about the smooth pebble.")

        // Assert Final State
        let finalItemState = try await engine.item("pebble")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "pebble", initialAttributes: initialAttributes)
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
            .firstDescription("This shouldn't appear."),
            .isTouched
        )
        let initialAttributes = item.attributes

        let game = MinimalGame(items: item)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("stone").hasFlag(.isTouched) == true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine stone")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> examine stone\n\nA worn stone.")

        // Only change is pronoun change
        #expect(
            await engine.gameState.changeHistory == [
                StateChange(
                    entityID: .global,
                    attribute: .pronounReference(pronoun: "it"),
                    newValue: .entityReferenceSet([.item("stone")])
                )
            ])
        #expect(await engine.gameState.changeHistory.count == 1)

        // Assert Final State (remains touched)
        let finalItemState = try await engine.item("stone")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should still be marked touched")

        // Assert Change History (Should be empty)
        let expectedChanges = expectedLookChanges(
            itemID: "stone", initialAttributes: initialAttributes)
        #expect(expectedChanges.isEmpty)
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

        let game = MinimalGame(items: box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("box").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine box")

        // Assert Output (Description + Contents)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine box

            On its lid is a rough carving of a skull. The wooden box
            contains a gold coin.
            """)

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("box")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "box", initialAttributes: initialAttributes)
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

        let game = MinimalGame(items: box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("box").hasFlag(.isTouched) == false)
        #expect(try await engine.item("box").attributes["isOpen"] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine box")

        // Assert Output (Description + Closed Message)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine box

            On its lid is a rough carving of a skull. The wooden box is
            closed.
            """)

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("box")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "box", initialAttributes: initialAttributes)
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

        let game = MinimalGame(items: jar, fly)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("jar").hasFlag(.isTouched) == false)
        #expect(try await engine.item("jar").attributes["isOpen"] == nil)
        #expect(try await engine.item("jar").attributes["isTransparent"] == true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine jar")

        // Assert Output (Description + Contents because transparent)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine jar

            An old canning jar, probably from the 1940s. The glass jar
            contains a dead fly.
            """)

        // Assert Final State (Container marked touched)
        let finalItemState = try await engine.item("jar")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Container should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "jar", initialAttributes: initialAttributes)
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

        let game = MinimalGame(items: table, book, candle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("table").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine table")

        // Assert Output (Description + Surface Contents)
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine table

            A shabby wooden table, worn from years of use. On the kitchen
            table are a dusty book and a lit candle.
            """
        )

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("table")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedLookChanges(
            itemID: "table", initialAttributes: initialAttributes)
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
        )  // inherentlyLit defaults false

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: room1, room2,
            items: artifact
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("artifact") == artifact)
        let reachableItems = await engine.scopeResolver.itemsReachableByPlayer()
        #expect(!reachableItems.contains("artifact"))  // Not reachable
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act: Use engine.execute
        try await engine.execute("examine artifact")

        // Assert Output (Error message)
        let output = await mockIO.flush()
        expectNoDifference(output, "> examine artifact\n\nYou can't see any such thing.")

        // Assert Final State (Item remains untouched and where it was)
        let finalItemState = try await engine.item("artifact")
        #expect(finalItemState.hasFlag(.isTouched) == false)
        #expect(finalItemState.parent == .location("otherRoom"))

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty)
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
            locations: office,
            items: desk
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("look at desk")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> look at desk\n\nA large, imposing wooden desk.")

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
        let game = MinimalGame(items: note)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("look at note")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> look at note\n\nA note with faint writing.")

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
        let (engine, mockIO) = await GameEngine.test()

        try await engine.execute("look at unicorn")

        let output = await mockIO.flush()
        expectNoDifference(output, "> look at unicorn\n\nYou can't see any such thing.")
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("LOOK AT item not in scope")
    func testLookAtItemNotInScope() async throws {
        let item = Item(id: "artifact", .name("ancient artifact"), .in(.nowhere))
        let game = MinimalGame(items: item)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look at artifact")

        let output = await mockIO.flush()
        expectNoDifference(output, "> look at artifact\n\nYou can't see any such thing.")
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
