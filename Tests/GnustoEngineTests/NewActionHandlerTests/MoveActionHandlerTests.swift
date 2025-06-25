import CustomDump
import Testing

@testable import GnustoEngine

@Suite("MoveActionHandler Tests")
struct MoveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("MOVE DIRECTOBJECT syntax works")
    func testMoveDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move box
            Moving the wooden box doesn't accomplish anything.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("SHIFT syntax works")
    func testShiftSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let stone = Item(
            id: "stone",
            .name("large stone"),
            .description("A large stone block."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shift stone")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shift stone
            Moving the large stone doesn't accomplish anything.
            """)
    }

    @Test("SLIDE syntax works")
    func testSlideSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let block = Item(
            id: "block",
            .name("ice block"),
            .description("A slippery ice block."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: block
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("slide block")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > slide block
            Moving the ice block doesn't accomplish anything.
            """)
    }

    @Test("MOVE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testMoveToSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A simple wooden chair."),
            .in(.location("testRoom"))
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chair, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move chair to table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move chair to table
            Moving the wooden chair doesn't accomplish anything.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot move without specifying object")
    func testCannotMoveWithoutObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move
            Move what?
            """)
    }

    @Test("Cannot move non-existent item")
    func testCannotMoveNonExistentItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move nonexistent
            You can't see any such thing.
            """)
    }

    @Test("Cannot move item not in scope")
    func testCannotMoveItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move box
            You can't see any such thing.
            """)
    }

    @Test("Cannot move location")
    func testCannotMoveLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move testRoom
            That's not something you can move.
            """)
    }

    @Test("Cannot move player")
    func testCannotMovePlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move me
            That's not something you can move.
            """)
    }

    @Test("Requires light to move")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move box
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Move item sets touched flag")
    func testMoveItemSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("A large oak barrel."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify barrel is not touched initially
        let initialState = try await engine.item("barrel")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("move barrel")

        // Then
        let finalState = try await engine.item("barrel")
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move barrel
            Moving the oak barrel doesn't accomplish anything.
            """)
    }

    @Test("Move item updates pronouns")
    func testMoveItemUpdatesPronouns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A large treasure chest."),
            .in(.location("testRoom"))
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the sword to set pronouns
        try await engine.execute("examine sword")
        _ = await mockIO.flush()

        // When - Move chest should update pronouns to chest
        try await engine.execute("move chest")
        _ = await mockIO.flush()

        // Then - "examine it" should now refer to the chest
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine it
            A large treasure chest.
            """)
    }

    @Test("Move held item works")
    func testMoveHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("heavy book"),
            .description("A heavy leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move book
            Moving the heavy book doesn't accomplish anything.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Move item in container")
    func testMoveItemInContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isTakable,
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A beautiful ruby gem."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bag, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move gem
            Moving the ruby gem doesn't accomplish anything.
            """)

        let finalState = try await engine.item("gem")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Move different item types")
    func testMoveDifferentItemTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let character = Item(
            id: "character",
            .name("old wizard"),
            .description("A wise old wizard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let device = Item(
            id: "device",
            .name("mechanical device"),
            .description("A complex mechanical device."),
            .isDevice,
            .in(.location("testRoom"))
        )

        let scenery = Item(
            id: "scenery",
            .name("stone pillar"),
            .description("A massive stone pillar."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: character, device, scenery
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Move character
        try await engine.execute("move wizard")

        let characterOutput = await mockIO.flush()
        expectNoDifference(
            characterOutput,
            """
            > move wizard
            Moving the old wizard doesn't accomplish anything.
            """)

        // When - Move device
        try await engine.execute("move device")

        let deviceOutput = await mockIO.flush()
        expectNoDifference(
            deviceOutput,
            """
            > move device
            Moving the mechanical device doesn't accomplish anything.
            """)

        // When - Move scenery
        try await engine.execute("move pillar")

        let sceneryOutput = await mockIO.flush()
        expectNoDifference(
            sceneryOutput,
            """
            > move pillar
            Moving the stone pillar doesn't accomplish anything.
            """)
    }

    @Test("Move ALL with no items")
    func testMoveAllWithNoItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move all
            There is nothing here to move.
            """)
    }

    @Test("Move ALL with multiple items")
    func testMoveAllWithMultipleItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .in(.location("testRoom"))
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A wooden chair."),
            .in(.location("testRoom"))
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, chair, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move all
            You move the wooden box, the wooden chair, and the wooden table.
            """)

        // Check that all items were touched
        let finalBox = try await engine.item("box")
        let finalChair = try await engine.item("chair")
        let finalTable = try await engine.item("table")

        #expect(finalBox.hasFlag(.isTouched) == true)
        #expect(finalChair.hasFlag(.isTouched) == true)
        #expect(finalTable.hasFlag(.isTouched) == true)
    }

    @Test("Move ALL skips unreachable items")
    func testMoveAllSkipsUnreachableItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let localBox = Item(
            id: "localBox",
            .name("local box"),
            .description("A box in this room."),
            .in(.location("testRoom"))
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: localBox, remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then - Should only move reachable items
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > move all
            You move the local box.
            """)

        let finalLocalBox = try await engine.item("localBox")
        let finalRemoteBox = try await engine.item("remoteBox")

        #expect(finalLocalBox.hasFlag(.isTouched) == true)
        #expect(finalRemoteBox.hasFlag(.isTouched) == false)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = MoveActionHandler()
        // MoveActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = MoveActionHandler()
        #expect(handler.verbs.contains(.move))
        #expect(handler.verbs.contains(.shift))
        #expect(handler.verbs.contains(.slide))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = MoveActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = MoveActionHandler()
        #expect(handler.syntax.count == 2)

        // Should have two syntax rules:
        // .match(.verb, .directObject)
        // .match(.verb, .directObject, .to, .indirectObject)
    }
}
