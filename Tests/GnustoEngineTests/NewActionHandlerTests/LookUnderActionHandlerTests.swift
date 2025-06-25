import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookUnderActionHandler Tests")
struct LookUnderActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LOOK UNDER DIRECTOBJECT syntax works")
    func testLookUnderDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
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
            You see nothing of interest under the wooden table.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("LOOK BENEATH DIRECTOBJECT syntax works")
    func testLookBeneathDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the large rock.
            """)
    }

    @Test("LOOK BELOW DIRECTOBJECT syntax works")
    func testLookBelowDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bridge = Item(
            id: "bridge",
            .name("stone bridge"),
            .description("A stone bridge spanning a creek."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the stone bridge.
            """)
    }

    @Test("PEEK UNDER DIRECTOBJECT syntax works")
    func testPeekUnderDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bed = Item(
            id: "bed",
            .name("old bed"),
            .description("An old creaky bed."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the old bed.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot look under without specifying object")
    func testCannotLookUnderWithoutObject() async throws {
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
        try await engine.execute("look under")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under
            Look under what?
            """)
    }

    @Test("Cannot look under non-existent item")
    func testCannotLookUnderNonExistentItem() async throws {
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
        try await engine.execute("look under nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under nonexistent
            You can’t look under that.
            """)
    }

    @Test("Cannot look under item not in scope")
    func testCannotLookUnderItemNotInScope() async throws {
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

        let remoteTable = Item(
            id: "remoteTable",
            .name("remote table"),
            .description("A table in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
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
            You can’t see any such thing.
            """)
    }

    @Test("Cannot look under location")
    func testCannotLookUnderLocation() async throws {
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
        try await engine.execute("look under testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under testRoom
            You can’t look under that.
            """)
    }

    @Test("Cannot look under player")
    func testCannotLookUnderPlayer() async throws {
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
        try await engine.execute("look under me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under me
            You can’t look under that.
            """)
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
            .in(.location("darkRoom"))
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Look under item sets touched flag")
    func testLookUnderItemSetsTouchedFlag() async throws {
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

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify chest is not touched initially
        let initialState = try await engine.item("chest")
        #expect(initialState.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("look under chest")

        // Then
        let finalState = try await engine.item("chest")
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look under chest
            You see nothing of interest under the treasure chest.
            """)
    }

    @Test("Look under item updates pronouns")
    func testLookUnderItemUpdatesPronouns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute("examine book")
        _ = await mockIO.flush()

        // When - Look under table should update pronouns to table
        try await engine.execute("look under table")
        _ = await mockIO.flush()

        // Then - "examine it" should now refer to the table
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > examine it
            A sturdy wooden table.
            """)
    }

    @Test("Look under held item works")
    func testLookUnderHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("small box"),
            .description("A small wooden box."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the small box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look under item in container")
    func testLookUnderItemInContainer() async throws {
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

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.item("bag"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the gold coin.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Look under different item types")
    func testLookUnderDifferentItemTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rug = Item(
            id: "rug",
            .name("persian rug"),
            .description("A beautiful persian rug."),
            .in(.location("testRoom"))
        )

        let character = Item(
            id: "character",
            .name("old man"),
            .description("A wise old man."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let device = Item(
            id: "device",
            .name("strange device"),
            .description("A strange mechanical device."),
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You see nothing of interest under the persian rug.
            """)

        // When - Look under character
        try await engine.execute("look under man")

        let characterOutput = await mockIO.flush()
        expectNoDifference(
            characterOutput,
            """
            > look under man
            You see nothing of interest under the old man.
            """)

        // When - Look under device
        try await engine.execute("look under device")

        let deviceOutput = await mockIO.flush()
        expectNoDifference(
            deviceOutput,
            """
            > look under device
            You see nothing of interest under the strange device.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = LookUnderActionHandler()
        // LookUnderActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = LookUnderActionHandler()
        #expect(handler.verbs.contains(.look))
        #expect(handler.verbs.contains(.peek))
        #expect(handler.verbs.count == 2)
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
