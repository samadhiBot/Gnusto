import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("LookUnderActionHandler Tests")
struct LookUnderActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK UNDER DIRECTOBJECT syntax works")
    func testLookUnderDirectObjectSyntax() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under table
            Beneath the wooden table lurks only disappointment and possibly
            dust.
            """
        )

        let finalState = try await engine.item("table")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK BENEATH DIRECTOBJECT syntax works")
    func testLookBeneathDirectObjectSyntax() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look beneath rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look beneath rock
            Beneath the large rock lurks only disappointment and possibly
            dust.
            """
        )
    }

    @Test("LOOK BELOW DIRECTOBJECT syntax works")
    func testLookBelowDirectObjectSyntax() async throws {
        // Given
        let bridge = Item(
            id: "bridge",
            .name("stone bridge"),
            .description("A stone bridge spanning a creek."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bridge
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look below bridge")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look below bridge
            Beneath the stone bridge lurks only disappointment and possibly
            dust.
            """
        )
    }

    @Test("PEEK UNDER DIRECTOBJECT syntax works")
    func testPeekUnderDirectObjectSyntax() async throws {
        // Given
        let bed = Item(
            id: "bed",
            .name("old bed"),
            .description("An old creaky bed."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bed
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("peek under bed")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > peek under bed
            Beneath the old bed lurks only disappointment and possibly
            dust.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot look under without specifying object")
    func testCannotLookUnderWithoutObject() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under
            Look under what?
            """
        )
    }

    @Test("Cannot look under non-existent item")
    func testCannotLookUnderNonExistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under nonexistent
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot look under item not in scope")
    func testCannotLookUnderItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTable = Item(
            id: "remoteTable",
            .name("remote table"),
            .description("A table in another room."),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTable
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under table
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot look under location")
    func testCannotLookUnderLocation() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under testRoom
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot look under player")
    func testCannotLookUnderPlayer() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under me
            The logistics of looking oneself prove insurmountable.
            """
        )
    }

    @Test("Requires light to look under")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under table
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Look under item sets touched flag")
    func testLookUnderItemSetsTouchedFlag() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A large treasure chest."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify chest is not touched initially
        let initialState = try await engine.item("chest")
        #expect(await initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("look under chest")

        // Then
        let finalState = try await engine.item("chest")
        #expect(await finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under chest
            Beneath the treasure chest lurks only disappointment and
            possibly dust.
            """
        )
    }

    @Test("Look under item updates pronouns")
    func testLookUnderItemUpdatesPronouns() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute("examine book")

        // When - Look under table should update pronouns to table
        try await engine.execute("look under table")

        // Then - "examine it" should now refer to the table
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine book
            An old leather book.

            > look under table
            Beneath the wooden table lurks only disappointment and possibly
            dust.

            > examine it
            A sturdy wooden table.
            """
        )
    }

    @Test("Look under held item works")
    func testLookUnderHeldItem() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under box
            Beneath the small box lurks only disappointment and possibly
            dust.
            """
        )

        let finalState = try await engine.item("box")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look under item in container")
    func testLookUnderItemInContainer() async throws {
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

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            items: bag, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("look under coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under coin
            Beneath the gold coin lurks only disappointment and possibly
            dust.
            """
        )

        let finalState = try await engine.item("coin")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look under different item types")
    func testLookUnderDifferentItemTypes() async throws {
        // Given
        let rug = Item(
            id: "rug",
            .name("persian rug"),
            .description("A beautiful persian rug."),
            .in(.startRoom)
        )

        let character = Item(
            id: "character",
            .name("old man"),
            .description("A wise old man."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let device = Item(
            id: "device",
            .name("strange device"),
            .description("A strange mechanical device."),
            .isDevice,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rug, character, device
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Look under rug
        try await engine.execute("look under rug")

        let rugOutput = await mockIO.flush()
        expectNoDifference(
            rugOutput,
            """
            > look under rug
            Beneath the persian rug lurks only disappointment and possibly
            dust.
            """
        )

        // When - Look under character
        try await engine.execute("look under man")

        let characterOutput = await mockIO.flush()
        expectNoDifference(
            characterOutput,
            """
            > look under man
            The space beneath the old man harbors no secrets worth
            discovering.
            """
        )

        // When - Look under device
        try await engine.execute("look under device")

        let deviceOutput = await mockIO.flush()
        expectNoDifference(
            deviceOutput,
            """
            > look under device
            Your investigation under the strange device reveals a profound
            absence of interest.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = LookUnderActionHandler()
        #expect(handler.synonyms.contains(.look))
        #expect(handler.synonyms.contains(.peek))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = LookUnderActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = LookUnderActionHandler()
        #expect(handler.syntax.count == 3)

        // Should have three syntax rules:
        // .match(.verb, .under, .directObject)
        // .match(.verb, .beneath, .directObject)
        // .match(.verb, .below, .directObject)
    }
}
