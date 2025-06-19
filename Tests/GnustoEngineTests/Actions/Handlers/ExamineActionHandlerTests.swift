import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ExamineActionHandler Tests")
struct ExamineActionHandlerTests {
    @Test func testExamineSimpleItem() async throws {
        let itemID: ItemID = "pebble"
        let item = Item(
            id: itemID,
            .name("small pebble"),
            .description("A smooth, grey pebble."),
            .in(.player)
        )
        let game = MinimalGame(items: [item])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine pebble"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A smooth, grey pebble.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemWithDetailedDescriptionHandler() async throws {
        let itemID: ItemID = "locket"
        let item = Item(
            id: itemID,
            .name("engraved locket"),
            .description("A small, tarnished silver locket."),
            .in(.player)
        )
        let game = MinimalGame(items: [item])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine locket"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A small, tarnished silver locket.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemInRoom() async throws {
        let itemID: ItemID = "statue"
        let roomID: LocationID = "garden"
        let item = Item(
            id: itemID,
            .name("stone statue"),
            .description("A weathered statue of a grue."),
            .in(.location(roomID))
        )
        let room = Location(
            id: roomID,
            .name("Garden"),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: roomID),
            locations: [room],
            items: [item]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine statue"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "A weathered statue of a grue.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test func testExamineItemNotInScope() async throws {
        let itemID: ItemID = "hiddenGem"
        let item = Item(
            id: itemID,
            .name("hidden gem"),
            .description("Should not see this."),
            .in(.location("farAwayRoom"))
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let farRoom = Location(
            id: "farAwayRoom",
            .name("Far Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom, farRoom],
            items: [item],
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine hidden gem"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let itemState = try await engine.item(itemID)
        #expect(itemState.attributes[.isTouched] != true)
    }

    @Test func testExamineTouchedItemNotInScope() async throws {
        let itemID: ItemID = "hiddenGem"
        let item = Item(
            id: itemID,
            .name("hidden gem"),
            .description("Should not see this."),
            .in(.location("farAwayRoom")),
            .isTouched
        )
        let startRoom = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let farRoom = Location(
            id: "farAwayRoom",
            .name("Far Room"),
            .inherentlyLit
        )
        let game = MinimalGame(
            locations: [startRoom, farRoom],
            items: [item],
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine hidden gem"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see the hidden gem.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let itemState = try await engine.item(itemID)
        #expect(itemState.attributes[.isTouched] == true)
    }

    @Test func testExamineNonExistentItem() async throws {
        let (engine, mockIO) = await GameEngine.test()
        let itemID: ItemID = "ghost"
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine ghost"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineAmbiguousItem() async throws {
        let itemID1: ItemID = "redBall"
        let itemID2: ItemID = "blueBall"
        let item1 = Item(
            id: itemID1,
            .name("red ball"),
            .description("A red ball."),
            .in(.player),
            .adjectives("red"),
            .synonyms("ball")
        )
        let item2 = Item(
            id: itemID2,
            .name("blue ball"),
            .description("A blue ball."),
            .in(.player),
            .adjectives("blue"),
            .synonyms("ball")
        )
        let game = MinimalGame(
            items: [item1, item2],
        )
        let (engine, _) = await GameEngine.test(
            blueprint: game
        )
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        // Parse the raw input first
        let parseResult = await engine.parser.parse(
            input: "examine ball",
            vocabulary: await engine.gameState.vocabulary,
            gameState: await engine.gameState
        )

        // Assert
        #expect(
            throws: ParseError.ambiguity("Which do you mean: the blue ball or the red ball?")
        ) {
            try parseResult.get()
        }
    }

    @Test func testExamineSelf() async throws {
        let (engine, mockIO) = await GameEngine.test()
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .player,
            rawInput: "examine self"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You are your usual self.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test func testExamineItemWithObjectActionOverride() async throws {
        let item = Item(
            id: "magicMirror",
            .name("magic mirror"),
            .description("A dusty old mirror."),
            .in(.player)
        )
        let game = MinimalGame(
            items: [item],
            itemEventHandlers: [
                "magicMirror": ItemEventHandler { engine, command in
                    ActionResult("You see your reflection in the magic mirror.")
                }
            ]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let initialItemState = try await engine.item("magicMirror")
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(item.id),
            rawInput: "examine mirror"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see your reflection in the magic mirror.")

        #expect(await engine.gameState.changeHistory.isEmpty)
        let finalItemState = try await engine.item("magicMirror")
        #expect(finalItemState.attributes[.isTouched] != true)
    }

    @Test func testExamineSceneryItem() async throws {
        let itemID: ItemID = "window"
        let roomID: LocationID = "kitchen"
        let item = Item(
            id: itemID,
            .name("kitchen window"),
            .description("The window is slightly ajar, but not enough to allow entry."),
            .in(.location(roomID)),
            .omitDescription
        )
        let room = Location(
            id: roomID,
            .name("Kitchen"),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: roomID),
            locations: [room],
            items: [item]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let initialItemState = try await engine.item(itemID)
        #expect(initialItemState.attributes[.isTouched] != true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item(itemID),
            rawInput: "examine window"
        )
        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "The window is slightly ajar, but not enough to allow entry.")

        let finalItemState = try await engine.item(itemID)
        #expect(finalItemState.attributes[.isTouched] == true)

        let expectedChanges = expectedExamineChanges(
            itemID: itemID,
            initialAttributes: initialItemState.attributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Surface with generic description and items on it")
    func testExamineSurfaceWithGenericDescription() async throws {
        // Arrange: Kitchen table with no special description, but items on it
        let kitchenTable = Item(
            id: "kitchenTable",
            .name("kitchen table"),
            // No custom description - will get generic "You see nothing special about the kitchen table."
            .in(.location(.startRoom)),
            .isSurface
        )
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A clear glass bottle."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer,
            .isTransparent
        )
        let brownSack = Item(
            id: "brownSack",
            .name("brown sack"),
            .description("A brown sack."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer
        )

        let initialAttributes = kitchenTable.attributes

        let game = MinimalGame(items: [kitchenTable, bottle, brownSack])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .examine,
            directObject: .item("kitchenTable"),
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should skip generic description and show only what's on the table
        let output = await mockIO.flush()
        expectNoDifference(output, "On the kitchen table are a glass bottle and a brown sack.")

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("kitchenTable")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedExamineChanges(itemID: "kitchenTable", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Empty surface with generic description")
    func testExamineEmptySurfaceWithGenericDescription() async throws {
        // Arrange: Kitchen table with no special description and no items on it
        let kitchenTable = Item(
            id: "kitchenTable",
            .name("kitchen table"),
            // No custom description - will get generic "You see nothing special about the kitchen table."
            .in(.location(.startRoom)),
            .isSurface
        )

        let initialAttributes = kitchenTable.attributes

        let game = MinimalGame(items: [kitchenTable])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .examine,
            directObject: .item("kitchenTable"),
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should show generic description since there's nothing on the table
        let output = await mockIO.flush()
        expectNoDifference(output, "You see nothing special about the kitchen table.")

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("kitchenTable")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedExamineChanges(itemID: "kitchenTable", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Surface with custom description and items on it")
    func testExamineSurfaceWithCustomDescription() async throws {
        // Arrange: Kitchen table with custom description and items on it
        let kitchenTable = Item(
            id: "kitchenTable",
            .name("kitchen table"),
            .description("A sturdy wooden table with scratches from years of use."),
            .in(.location(.startRoom)),
            .isSurface
        )
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A clear glass bottle."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer,
            .isTransparent
        )
        let brownSack = Item(
            id: "brownSack",
            .name("brown sack"),
            .description("A brown sack."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer
        )

        let initialAttributes = kitchenTable.attributes

        let game = MinimalGame(items: [kitchenTable, bottle, brownSack])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .examine,
            directObject: .item("kitchenTable"),
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should show custom description followed by surface contents
        let output = await mockIO.flush()
        expectNoDifference(output, """
            A sturdy wooden table with scratches from years of use. On the
            kitchen table are a glass bottle and a brown sack.
            """)

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("kitchenTable")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedExamineChanges(itemID: "kitchenTable", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Enhanced surface with generic description and firstDescription items")
    func testExamineEnhancedSurfaceWithGenericDescription() async throws {
        // Arrange: Kitchen table with no special description, but items with firstDescription
        let kitchenTable = Item(
            id: "kitchenTable",
            .name("kitchen table"),
            // No custom description - will get generic "You see nothing special about the kitchen table."
            .in(.location(.startRoom)),
            .isSurface
        )
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .description("A clear glass bottle."),
            .firstDescription("A bottle is sitting on the table."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer,
            .isTransparent
        )
        let water = Item(
            id: "water",
            .name("quantity of water"),
            .description("It's just water."),
            .in(.item("bottle")),
            .isTakable
        )
        let brownSack = Item(
            id: "brownSack",
            .name("brown sack"),
            .description("A brown sack."),
            .firstDescription("On the table is an elongated brown sack, smelling of hot peppers."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer
        )

        let initialAttributes = kitchenTable.attributes

        let game = MinimalGame(items: [kitchenTable, bottle, water, brownSack])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .examine,
            directObject: .item("kitchenTable"),
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Should skip generic description and show only enhanced item descriptions
        let output = await mockIO.flush()
        expectNoDifference(output, """
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.
            """)

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("kitchenTable")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedExamineChanges(itemID: "kitchenTable", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Enhanced surface description with nested containers")
    func testExamineEnhancedSurface() async throws {
        // Arrange: Kitchen table with bottle containing water, and brown sack
        let kitchenTable = Item(
            id: "kitchenTable",
            .name("kitchen table"),
            .description("A wooden table used for food preparation."),
            .in(.location(.startRoom)),
            .isSurface
        )
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .adjectives("clear", "glass"),
            .description("A clear glass bottle."),
            .firstDescription("A bottle is sitting on the table."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isTransparent,
            .isContainer
        )
        let water = Item(
            id: "water",
            .name("quantity of water"),
            .description("It's just water."),
            .synonyms("water", "h2o", "liquid"),
            .in(.item("bottle")),
            .isTakable
        )
        let brownSack = Item(
            id: "brownSack",
            .name("elongated brown sack"),
            .description("An elongated brown sack, smelling of hot peppers."),
            .adjectives("brown", "elongated", "smelly"),
            .synonyms("bag", "sack"),
            .firstDescription("On the table is an elongated brown sack, smelling of hot peppers."),
            .in(.item("kitchenTable")),
            .isTakable,
            .isContainer,
            .isOpenable
        )

        let initialAttributes = kitchenTable.attributes

        let game = MinimalGame(items: [kitchenTable, bottle, water, brownSack])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(try await engine.item("kitchenTable").hasFlag(.isTouched) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        let command = Command(
            verb: .examine,
            directObject: .item("kitchenTable"),
            rawInput: "examine table"
        )

        // Act
        await engine.execute(command: command)

        // Debug: Let's see exactly what's being produced
        let output = await mockIO.flush()

        // Assert: Should show enhanced surface description
        expectNoDifference(output, """
            A bottle is sitting on the table. The glass bottle contains a
            quantity of water. On the table is an elongated brown sack,
            smelling of hot peppers.
            """)

        // Assert Final State (Surface marked touched)
        let finalItemState = try await engine.item("kitchenTable")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Surface should be marked touched")

        // Assert Change History
        let expectedChanges = expectedExamineChanges(itemID: "kitchenTable", initialAttributes: initialAttributes)
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }
}

extension ExamineActionHandlerTests {
    private func expectedExamineChanges(
        itemID: ItemID,
        initialAttributes: [ItemAttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Item is touched
        if initialAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attribute: .itemAttribute(.isTouched),
                    oldValue: nil,
                    newValue: true
                )
            )
        }

        // Pronoun "it" is set to this item
        // TODO: This might need to be more sophisticated if "them" is possible
        // or if the existing pronoun was different.
        changes.append(
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                // Old value might be nil or another item, for simplicity in test we assume nil or different
                // A more robust test might capture the actual old pronoun state.
                oldValue: nil, // Assuming it wasn’t set or was different
                newValue: .entityReferenceSet([.item(itemID)]) // Use .entityReferenceSet
            )
        )
        return changes
    }
}
