import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("MoveActionHandler Tests")
struct MoveActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("MOVE DIRECTOBJECT syntax works")
    func testMoveDirectObjectSyntax() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A heavy wooden box."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move box")

        // Then
        await mockIO.expectOutput(
            """
            > move box
            The wooden box remains firmly where it is, despite your
            efforts.
            """
        )

        let finalState = await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("SHIFT syntax works")
    func testShiftSyntax() async throws {
        // Given
        let stone = Item(
            id: "stone",
            .name("large stone"),
            .description("A large stone block."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: stone
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shift stone")

        // Then
        await mockIO.expectOutput(
            """
            > shift stone
            The large stone remains firmly where it is, despite your
            efforts.
            """
        )
    }

    @Test("SLIDE syntax works")
    func testSlideSyntax() async throws {
        // Given
        let block = Item(
            id: "block",
            .name("ice block"),
            .description("A slippery ice block."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: block
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("slide block")

        // Then
        await mockIO.expectOutput(
            """
            > slide block
            The ice block remains firmly where it is, despite your efforts.
            """
        )
    }

    @Test("MOVE DIRECTOBJECT TO INDIRECTOBJECT syntax works")
    func testMoveToSyntax() async throws {
        // Given
        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A simple wooden chair."),
            .in(.startRoom)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chair, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move chair to table")

        // Then
        await mockIO.expectOutput(
            """
            > move chair to table
            Moving the wooden chair to the wooden table proves impossible.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot move without specifying object")
    func testCannotMoveWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move")

        // Then
        await mockIO.expectOutput(
            """
            > move
            Nervous movement carries you nowhere in particular.
            """
        )
    }

    @Test("Cannot move non-existent item")
    func testCannotMoveNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > move nonexistent
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot move item not in scope")
    func testCannotMoveItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move box")

        // Then
        await mockIO.expectOutput(
            """
            > move box
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot move location")
    func testCannotMoveLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move testRoom")

        // Then
        await mockIO.expectOutput(
            """
            > move testRoom
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot move player")
    func testCannotMovePlayer() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move me")

        // Then
        await mockIO.expectOutput(
            """
            > move me
            You pace about with restless energy.
            """
        )
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
            .in("darkRoom")
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
        await mockIO.expectOutput(
            """
            > move box
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Move item sets touched flag")
    func testMoveItemSetsTouchedFlag() async throws {
        // Given
        let barrel = Item(
            id: "barrel",
            .name("oak barrel"),
            .description("A large oak barrel."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: barrel
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify barrel is not touched initially
        let initialState = await engine.item("barrel")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("move barrel")

        // Then
        let finalState = await engine.item("barrel")
        #expect(await finalState.hasFlag(.isTouched) == true)

        await mockIO.expectOutput(
            """
            > move barrel
            The oak barrel remains firmly where it is, despite your
            efforts.
            """
        )
    }

    @Test("Move item updates pronouns")
    func testMoveItemUpdatesPronouns() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A large treasure chest."),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chest, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the sword to set pronouns
        try await engine.execute("examine sword")

        // When - Move chest should update pronouns to chest
        try await engine.execute("move chest")

        // Then - "examine it" should now refer to the chest
        try await engine.execute("examine it")

        await mockIO.expectOutput(
            """
            > examine sword
            A sharp steel sword.

            > move chest
            The treasure chest remains firmly where it is, despite your
            efforts.

            > examine it
            A large treasure chest.
            """
        )
    }

    @Test("Move held item works")
    func testMoveHeldItem() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("heavy book"),
            .description("A heavy leather-bound book."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move book")

        // Then
        await mockIO.expectOutput(
            """
            > move book
            The heavy book remains firmly where it is, despite your
            efforts.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Move item in container")
    func testMoveItemInContainer() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .description("A leather bag."),
            .isTakable,
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A beautiful ruby gem."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            items: bag, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move gem")

        // Then
        await mockIO.expectOutput(
            """
            > move gem
            The ruby gem remains firmly where it is, despite your efforts.
            """
        )

        let finalState = await engine.item("gem")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Move different item types")
    func testMoveDifferentItemTypes() async throws {
        // Given
        let character = Item(
            id: "character",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let device = Item(
            id: "device",
            .name("mechanical device"),
            .description("A complex mechanical device."),
            .isDevice,
            .in(.startRoom)
        )

        let scenery = Item(
            id: "scenery",
            .name("stone pillar"),
            .description("A massive stone pillar."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: character, device, scenery
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Move character
        try await engine.execute("move wizard")

        await mockIO.expectOutput(
            """
            > move wizard
            The old wizard remains firmly where it is, despite your
            efforts.
            """
        )

        // When - Move device
        try await engine.execute("move device")

        await mockIO.expectOutput(
            """
            > move device
            The mechanical device remains firmly where it is, despite your
            efforts.
            """
        )

        // When - Move scenery
        try await engine.execute("move pillar")

        await mockIO.expectOutput(
            """
            > move pillar
            The stone pillar remains firmly where it is, despite your
            efforts.
            """
        )
    }

    @Test("Move ALL with no items")
    func testMoveAllWithNoItems() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then
        await mockIO.expectOutput(
            """
            > move all
            The verb 'move' doesn't support multiple objects.
            """
        )
    }

    @Test("Move ALL with multiple items")
    func testMoveAllWithMultipleItems() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .in(.startRoom)
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A wooden chair."),
            .in(.startRoom)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box, chair, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then
        await mockIO.expectOutput(
            """
            > move all
            The verb 'move' doesn't support multiple objects.
            """
        )
    }

    @Test("Move ALL skips unreachable items")
    func testMoveAllSkipsUnreachableItems() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let localBox = Item(
            id: "localBox",
            .name("local box"),
            .description("A box in this room."),
            .in(.startRoom)
        )

        let remoteBox = Item(
            id: "remoteBox",
            .name("remote box"),
            .description("A box in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: localBox, remoteBox
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move all")

        // Then - Should only move reachable items
        await mockIO.expectOutput(
            """
            > move all
            The verb 'move' doesn't support multiple objects.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = MoveActionHandler()
        #expect(handler.synonyms.contains(.move))
        #expect(handler.synonyms.contains(.shift))
        #expect(handler.synonyms.contains(.slide))
        #expect(handler.synonyms.count == 3)
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
