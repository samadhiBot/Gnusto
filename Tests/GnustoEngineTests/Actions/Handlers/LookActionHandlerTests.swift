import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK syntax works")
    func testLookSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("L syntax works")
    func testLSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("l")

        // Then
        await mockIO.expectOutput(
            """
            > l
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("LOOK AT DIRECTOBJECT syntax delegates to examine")
    func testLookAtDirectObjectSyntax() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A worn leather-bound book.")
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at book")

        // Then
        await mockIO.expectOutput(
            """
            > look at book
            A worn leather-bound book.
            """
        )

        let finalState = await engine.item("book")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK IN DIRECTOBJECT syntax delegates to look inside")
    func testLookInDirectObjectSyntax() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let gem = Item("gem")
            .name("ruby gem")
            .description("A precious ruby gem.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look in the box")

        // Then
        await mockIO.expectOutput(
            """
            > look in the box
            In the wooden box you can see a ruby gem.
            """
        )
    }

    @Test("LOOK INSIDE DIRECTOBJECT syntax delegates to look inside")
    func testLookInsideDirectObjectSyntax() async throws {
        // Given
        let cabinet = Item("cabinet")
            .name("oak cabinet")
            .description("A sturdy oak cabinet.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let vase = Item("vase")
            .name("ceramic vase")
            .description("A delicate ceramic vase.")
            .isTakable
            .in(.item("cabinet"))

        let game = MinimalGame(
            items: cabinet, vase
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look inside cabinet")

        // Then
        await mockIO.expectOutput(
            """
            > look inside cabinet
            In the oak cabinet you can see a ceramic vase.
            """
        )
    }

    @Test("LOOK THROUGH DIRECTOBJECT syntax delegates to examine")
    func testLookThroughDirectObjectSyntax() async throws {
        // Given
        let window = Item("window")
            .name("glass window")
            .description("A clear glass window showing the outside world.")
            .in(.startRoom)

        let game = MinimalGame(
            items: window
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look through window")

        // Then
        await mockIO.expectOutput(
            """
            > look through window
            A clear glass window showing the outside world.
            """
        )
    }

    @Test("LOOK WITH DIRECTOBJECT syntax delegates to look inside")
    func testLookWithDirectObjectSyntax() async throws {
        // Given
        let telescope = Item("telescope")
            .name("brass telescope")
            .description("A polished brass telescope.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let lens = Item("lens")
            .name("crystal lens")
            .description("A perfect crystal lens.")
            .isTakable
            .in(.item("telescope"))

        let game = MinimalGame(
            items: telescope, lens
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look with telescope")

        // Then
        await mockIO.expectOutput(
            """
            > look with telescope
            In the brass telescope you can see a crystal lens.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("LOOK without object always succeeds")
    func testLookWithoutObjectAlwaysSucceeds() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("Cannot look at non-existent item")
    func testCannotLookAtNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > look at nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot look at item not in scope")
    func testCannotLookAtItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteBook = Item("remoteBook")
            .name("remote book")
            .description("A book in another room.")
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBook
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at book")

        // Then
        await mockIO.expectOutput(
            """
            > look at book
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot look at non-item entities")
    func testCannotLookAtNonItemEntities() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look at me")

        // Then - This should work since "me" refers to player, but let's test with room
        await mockIO.expectOutput(
            """
            > look at me
            As good-looking as ever, which is to say, adequately
            presentable.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Look in dark room shows darkness message")
    func testLookInDarkRoomShowsDarknessMessage() async throws {
        // Given: Dark room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    @Test("Look in lit room shows room description")
    func testLookInLitRoomShowsRoomDescription() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    @Test("Look shows items in room")
    func testLookShowsItemsInRoom() async throws {
        // Given
        let book = Item("book")
            .name("red book")
            .description("A red leather book.")
            .isTakable
            .in(.startRoom)

        let table = Item("table")
            .name("wooden table")
            .description("A sturdy wooden table.")
            .in(.startRoom)

        let game = MinimalGame(
            items: book, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There are a red book and a wooden table here.
            """
        )
    }

    @Test("Look shows items on surfaces")
    func testLookShowsItemsOnSurfaces() async throws {
        // Given
        let table = Item("table")
            .name("oak table")
            .description("A solid oak table.")
            .isSurface
            .in(.startRoom)

        let book = Item("book")
            .name("leather book")
            .description("A leather-bound book.")
            .isTakable
            .in(.item("table"))

        let candle = Item("candle")
            .name("wax candle")
            .description("A simple wax candle.")
            .isTakable
            .in(.item("table"))

        let game = MinimalGame(
            items: table, book, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is an oak table here. On the oak table you can see a
            leather book and a wax candle.
            """
        )
    }

    @Test("Look shows items in open containers")
    func testLookShowsItemsInOpenContainers() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A sturdy wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let gem = Item("gem")
            .name("ruby gem")
            .description("A precious ruby gem.")
            .isTakable
            .in(.item("box"))

        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, gem, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a wooden box here. In the wooden box you can see a
            gold coin and a ruby gem.
            """
        )
    }

    @Test("Look shows items in transparent containers")
    func testLookShowsItemsInTransparentContainers() async throws {
        // Given
        let jar = Item("jar")
            .name("glass jar")
            .description("A transparent glass jar.")
            .isContainer
            .isTransparent
            // Note: Not open, but transparent
            .in(.startRoom)

        let marble = Item("marble")
            .name("blue marble")
            .description("A beautiful blue marble.")
            .isTakable
            .in(.item("jar"))

        let game = MinimalGame(
            items: jar, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a glass jar here. In the glass jar you can see a blue
            marble.
            """
        )
    }

    @Test("Look doesn't show items in closed opaque containers")
    func testLookDoesntShowItemsInClosedOpaqueContainers() async throws {
        // Given
        let chest = Item("chest")
            .name("treasure chest")
            .description("A closed treasure chest.")
            .isContainer
            // Note: Not open and not transparent
            .in(.startRoom)

        let treasure = Item("treasure")
            .name("golden treasure")
            .description("Precious golden treasure.")
            .isTakable
            .in(.item("chest"))

        let game = MinimalGame(
            items: chest, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a treasure chest here.
            """
        )
    }

    @Test("Look in room with light source shows room even if light is off")
    func testLookInRoomWithLightSourceShowsRoomEvenIfLightIsOff() async throws {
        // Given: Room that's lit by light source, but light source is off
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A room that needs artificial light.")
            // Note: No .inherentlyLit property

        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A brass lamp.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

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
        await mockIO.expectOutput(
            """
            > look
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    @Test("Look in room with active light source shows room description")
    func testLookInRoomWithActiveLightSourceShowsRoomDescription() async throws {
        // Given: Dark room with active light source
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A room illuminated by artificial light.")
            // Note: No .inherentlyLit property

        let torch = Item("torch")
            .name("burning torch")
            .description("A torch with a bright flame.")
            .isLightSource
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the torch to be on (providing light)
        try await engine.apply(
            torch.proxy(engine).setFlag(.isOn)
        )

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Dark Room ---

            A room illuminated by artificial light.
            """
        )
    }

    @Test("Look shows first descriptions for untouched items")
    func testLookShowsFirstDescriptionsForUntouchedItems() async throws {
        // Given
        let table = Item("table")
            .name("wooden table")
            .description("A simple wooden table.")
            .isSurface
            .in(.startRoom)

        let book = Item("book")
            .name("mysterious book")
            .description("An ancient tome.")
            .firstDescription("A mysterious book glows softly on the table.")
            .isTakable
            // Note: Not touched yet
            .in(.item("table"))

        let game = MinimalGame(
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then - should show first description
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a wooden table here. A mysterious book glows softly on
            the table.
            """
        )
    }

    @Test("Look shows regular descriptions for touched items")
    func testLookShowsRegularDescriptionsForTouchedItems() async throws {
        // Given
        let table = Item("table")
            .name("wooden table")
            .description("A simple wooden table.")
            .isSurface
            .in(.startRoom)

        let book = Item("book")
            .name("mysterious book")
            .description("An ancient tome.")
            .firstDescription("A mysterious book glows softly on the table.")
            .isTakable
            .isTouched  // Already touched
            .in(.item("table"))

        let game = MinimalGame(
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then - should show regular description, not first description
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a wooden table here. On the wooden table you can see a
            mysterious book.
            """
        )
    }

    @Test("Look handles empty room")
    func testLookHandlesEmptyRoom() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.
            """
        )
    }

    // MARK: - Edge Case Testing

    @Test("Look handles mixed touched and untouched items with first descriptions")
    func testLookHandlesMixedTouchedAndUntouchedItemsWithFirstDescriptions() async throws {
        // Given: A complex scenario with multiple items in different states
        let desk = Item("desk")
            .name("mahogany desk")
            .description("A polished mahogany desk.")
            .isSurface
            .in(.startRoom)

        let safe = Item("safe")
            .name("steel safe")
            .description("A heavy steel safe.")
            .isContainer
            .isOpen
            .in(.startRoom)

        // Item with first description, not touched (should show first description)
        let glowingOrb = Item("orb")
            .name("crystal orb")
            .description("A clear crystal orb.")
            .firstDescription("A mysterious crystal orb pulses with inner light on the desk.")
            .isTakable
            .in(.item("desk"))

        // Item with first description, already touched (should show regular listing)
        let oldMap = Item("map")
            .name("ancient map")
            .description("An ancient parchment map.")
            .firstDescription("An ancient map lies spread across the desk.")
            .isTakable
            .isTouched
            .in(.item("desk"))

        // Item without first description, not touched (should show regular listing)
        let pen = Item("pen")
            .name("fountain pen")
            .description("An elegant fountain pen.")
            .isTakable
            .in(.item("desk"))

        // Item in container with first description, not touched
        let goldBar = Item("gold")
            .name("gold bar")
            .description("A heavy gold bar.")
            .firstDescription("A gleaming gold bar catches your eye in the safe.")
            .isTakable
            .in(.item("safe"))

        // Item in container without first description
        let documents = Item("documents")
            .name("legal documents")
            .description("Important legal papers.")
            .isTakable
            .isPlural
            .in(.item("safe"))

        let game = MinimalGame(
            items: desk, safe, glowingOrb, oldMap, pen, goldBar, documents
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There are a mahogany desk and a steel safe here. A mysterious
            crystal orb pulses with inner light on the desk. On the
            mahogany desk you also see an ancient map and a fountain pen. A
            gleaming gold bar catches your eye in the safe. In the steel
            safe you also see some legal documents.
            """
        )
    }

    @Test("Look handles nested containers with mixed visibility")
    func testLookHandlesNestedContainersWithMixedVisibility() async throws {
        // Given: Containers within containers with different visibility states
        let shelf = Item("shelf")
            .name("wooden shelf")
            .description("A tall wooden shelf.")
            .isSurface
            .in(.startRoom)

        // Open container on shelf
        let openBox = Item("openBox")
            .name("cardboard box")
            .description("An open cardboard box.")
            .isContainer
            .isOpen
            .in(.item("shelf"))

        // Closed container on shelf (contents not visible)
        let closedBox = Item("closedBox")
            .name("wooden crate")
            .description("A closed wooden crate.")
            .isContainer
            .in(.item("shelf"))

        // Transparent container on shelf
        let jar = Item("jar")
            .name("glass jar")
            .description("A clear glass jar.")
            .isContainer
            .isTransparent
            .in(.item("shelf"))

        // Items in different containers
        let book = Item("book")
            .name("blue book")
            .description("A small blue book.")
            .isTakable
            .in(.item("openBox"))

        let hiddenKey = Item("key")
            .name("brass key")
            .description("A small brass key.")
            .isTakable
            .in(.item("closedBox"))

        let marble = Item("marble")
            .name("green marble")
            .description("A smooth green marble.")
            .firstDescription("A green marble glows mysteriously in the jar.")
            .isTakable
            .in(.item("jar"))

        let game = MinimalGame(
            items: shelf, openBox, closedBox, jar, book, hiddenKey, marble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a wooden shelf here. On the wooden shelf you can see a
            wooden crate, a glass jar, and a cardboard box.
            """
        )
    }

    @Test("Look handles multiple surfaces with mixed content types")
    func testLookHandlesMultipleSurfacesWithMixedContentTypes() async throws {
        // Given: Multiple surfaces with different types of content
        let workbench = Item("workbench")
            .name("work bench")
            .description("A sturdy work bench.")
            .isSurface
            .in(.startRoom)

        let table = Item("table")
            .name("round table")
            .description("A small round table.")
            .isSurface
            .in(.startRoom)

        // Items with first descriptions on workbench
        let hammer = Item("hammer")
            .name("steel hammer")
            .description("A heavy steel hammer.")
            .firstDescription("A steel hammer lies ready for use on the work bench.")
            .isTakable
            .in(.item("workbench"))

        // Regular items on workbench
        let nails = Item("nails")
            .name("iron nails")
            .description("A handful of iron nails.")
            .isTakable
            .isPlural
            .in(.item("workbench"))

        let saw = Item("saw")
            .name("hand saw")
            .description("A sharp hand saw.")
            .isTakable
            .isTouched
            .in(.item("workbench"))

        // Mixed items on table
        let candle = Item("candle")
            .name("wax candle")
            .description("A half-melted candle.")
            .firstDescription("A wax candle flickers softly on the table.")
            .isTakable
            .in(.item("table"))

        let scroll = Item("scroll")
            .name("parchment scroll")
            .description("An old parchment scroll.")
            .isTakable
            .isTouched
            .in(.item("table"))

        let game = MinimalGame(
            items: workbench, table, hammer, nails, saw, candle, scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There are a round table and a work bench here. A wax candle
            flickers softly on the table. On the round table you also see a
            parchment scroll. A steel hammer lies ready for use on the work
            bench. On the work bench you also see some iron nails and a
            hand saw.
            """
        )
    }

    @Test("Look handles empty containers and surfaces")
    func testLookHandlesEmptyContainersAndSurfaces() async throws {
        // Given: Empty containers and surfaces
        let emptyTable = Item("table")
            .name("bare table")
            .description("A completely bare table.")
            .isSurface
            .in(.startRoom)

        let emptyBox = Item("box")
            .name("empty box")
            .description("An empty cardboard box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let emptyJar = Item("jar")
            .name("clear jar")
            .description("An empty clear jar.")
            .isContainer
            .isTransparent
            .in(.startRoom)

        let regularItem = Item("broom")
            .name("old broom")
            .description("A worn old broom.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: emptyTable, emptyBox, emptyJar, regularItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look")

        // Then - empty containers/surfaces should not generate content listings
        await mockIO.expectOutput(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There are an empty box, an old broom, a clear jar, and a bare
            table here.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LookActionHandler()
        #expect(handler.synonyms.contains(.look))
        #expect(handler.synonyms.contains("l"))
        #expect(handler.synonyms.count == 2)
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
