import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK syntax works")
    func testLookSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing purposes."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room for testing purposes.
            """)
    }

    @Test("L syntax works")
    func testLSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("l")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > l
            — Test Room —

            A room for testing.
            """)
    }

    @Test("LOOK AT DIRECTOBJECT syntax delegates to examine")
    func testLookAtDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look at book
            A worn leather-bound book.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK IN DIRECTOBJECT syntax delegates to look inside")
    func testLookInDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby gem."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look in box
            In the wooden box you can see a ruby gem.
            """)
    }

    @Test("LOOK INSIDE DIRECTOBJECT syntax delegates to look inside")
    func testLookInsideDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cabinet = Item(
            id: "cabinet",
            .name("oak cabinet"),
            .description("A sturdy oak cabinet."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let vase = Item(
            id: "vase",
            .name("ceramic vase"),
            .description("A delicate ceramic vase."),
            .isTakable,
            .in(.item("cabinet"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cabinet, vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside cabinet")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look inside cabinet
            In the oak cabinet you can see a ceramic vase.
            """)
    }

    @Test("LOOK THROUGH DIRECTOBJECT syntax delegates to examine")
    func testLookThroughDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let window = Item(
            id: "window",
            .name("glass window"),
            .description("A clear glass window showing the outside world."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: window
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look through window")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look through window
            A clear glass window showing the outside world.
            """)
    }

    @Test("LOOK WITH DIRECTOBJECT syntax delegates to look inside")
    func testLookWithDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let telescope = Item(
            id: "telescope",
            .name("brass telescope"),
            .description("A polished brass telescope."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let lens = Item(
            id: "lens",
            .name("crystal lens"),
            .description("A perfect crystal lens."),
            .isTakable,
            .in(.item("telescope"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: telescope, lens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look with telescope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look with telescope
            In the brass telescope you can see a crystal lens.
            """)
    }

    // MARK: - Validation Testing

    @Test("LOOK without object always succeeds")
    func testLookWithoutObjectAlwaysSucceeds() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A simple test room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A simple test room.
            """)
    }

    @Test("Cannot look at non-existent item")
    func testCannotLookAtNonExistentItem() async throws {
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
        try await engine.execute("look at nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look at nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot look at item not in scope")
    func testCannotLookAtItemNotInScope() async throws {
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

        let remoteBook = Item(
            id: "remoteBook",
            .name("remote book"),
            .description("A book in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look at book
            You can’t see any such thing.
            """)
    }

    @Test("Cannot look at non-item entities")
    func testCannotLookAtNonItemEntities() async throws {
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
        try await engine.execute("look at me")

        // Then - This should work since "me" refers to player, but let's test with room
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look at me
            You look about the same as always.
            """)
    }

    // MARK: - Processing Testing

    @Test("Look in dark room shows darkness message")
    func testLookInDarkRoomShowsDarknessMessage() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            It is pitch black. You can’t see a thing.
            """)
    }

    @Test("Look in lit room shows room description")
    func testLookInLitRoomShowsRoomDescription() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Beautiful Garden"),
            .description("A lovely garden filled with colorful flowers and singing birds."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Beautiful Garden —

            A lovely garden filled with colorful flowers and singing birds.
            """)
    }

    @Test("Look shows items in room")
    func testLookShowsItemsInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("red book"),
            .description("A red leather book."),
            .isTakable,
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
            items: book, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room for testing.

            There is a red book and a wooden table here.
            """)
    }

    @Test("Look shows items on surfaces")
    func testLookShowsItemsOnSurfaces() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with furniture."),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("oak table"),
            .description("A solid oak table."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A leather-bound book."),
            .isTakable,
            .in(.item("table"))
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .in(.item("table"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with furniture.

            There is an oak table here.

            On the oak table you can see a leather book and a wax candle.
            """)
    }

    @Test("Look shows items in open containers")
    func testLookShowsItemsInOpenContainers() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with containers."),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("ruby gem"),
            .description("A precious ruby gem."),
            .isTakable,
            .in(.item("box"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, gem, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with containers.

            There is a wooden box here.

            In the wooden box you can see a ruby gem and a gold coin.
            """)
    }

    @Test("Look shows items in transparent containers")
    func testLookShowsItemsInTransparentContainers() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with transparent containers."),
            .inherentlyLit
        )

        let jar = Item(
            id: "jar",
            .name("glass jar"),
            .description("A transparent glass jar."),
            .isContainer,
            .isTransparent,
            // Note: Not open, but transparent
            .in(.location("testRoom"))
        )

        let marble = Item(
            id: "marble",
            .name("blue marble"),
            .description("A beautiful blue marble."),
            .isTakable,
            .in(.item("jar"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with transparent containers.

            There is a glass jar here.

            In the glass jar you can see a blue marble.
            """)
    }

    @Test("Look doesn’t show items in closed opaque containers")
    func testLookDoesntShowItemsInClosedOpaqueContainers() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with closed containers."),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A closed treasure chest."),
            .isContainer,
            // Note: Not open and not transparent
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .description("Precious golden treasure."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with closed containers.

            There is a treasure chest here.
            """)
    }

    @Test("Look in room with light source shows room even if light is off")
    func testLookInRoomWithLightSourceShowsRoomEvenIfLightIsOff() async throws {
        // Given: Room that's lit by light source, but light source is off
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that needs artificial light.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Light is off by default
        // When
        try await engine.execute("look")

        // Then - should show darkness message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            It is pitch black. You can’t see a thing.
            """)
    }

    @Test("Look in room with active light source shows room description")
    func testLookInRoomWithActiveLightSourceShowsRoomDescription() async throws {
        // Given: Dark room with active light source
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room illuminated by artificial light.")
            // Note: No .inherentlyLit property
        )

        let torch = Item(
            id: "torch",
            .name("burning torch"),
            .description("A torch with a bright flame."),
            .isLightSource,
            .isDevice,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the torch to be on (providing light)
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("torch"))
        )

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Dark Room —

            A room illuminated by artificial light.
            """)
    }

    @Test("Look shows first descriptions for untouched items")
    func testLookShowsFirstDescriptionsForUntouchedItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with special items."),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A simple wooden table."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("mysterious book"),
            .description("An ancient tome."),
            .firstDescription("A mysterious book glows softly on the table."),
            .isTakable,
            // Note: Not touched yet
            .in(.item("table"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then - should show first description
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with special items.

            There is a wooden table here.

            A mysterious book glows softly on the table.
            """)
    }

    @Test("Look shows regular descriptions for touched items")
    func testLookShowsRegularDescriptionsForTouchedItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room with examined items."),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A simple wooden table."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("mysterious book"),
            .description("An ancient tome."),
            .firstDescription("A mysterious book glows softly on the table."),
            .isTakable,
            .isTouched,  // Already touched
            .in(.item("table"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then - should show regular description, not first description
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Test Room —

            A room with examined items.

            There is a wooden table here.

            On the wooden table you can see a mysterious book.
            """)
    }

    @Test("Look handles empty room")
    func testLookHandlesEmptyRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Empty Room"),
            .description("A completely empty room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            — Empty Room —

            A completely empty room.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = LookActionHandler()
        // LookActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = LookActionHandler()
        #expect(handler.verbs.contains(.look))
        #expect(handler.verbs.contains("l"))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = LookActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = LookActionHandler()
        #expect(handler.syntax.count == 1)
        // The specific syntax pattern allows just the verb without objects
    }
}
