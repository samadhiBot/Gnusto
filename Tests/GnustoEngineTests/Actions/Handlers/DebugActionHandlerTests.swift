import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DebugActionHandler Tests")
struct DebugActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DEBUG syntax works")
    func testDebugSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug lamp")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        // Should start with command echo and contain debug output in code blocks
        #expect(lines.first == "> debug lamp")
        #expect(output.contains("```"))
        #expect(output.contains("Item"))
        #expect(output.contains("brass lamp"))
    }

    // MARK: - Validation Testing

    @Test("Cannot debug without specifying object")
    func testCannotDebugWithoutObject() async throws {
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
        try await engine.execute("debug")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug
            DEBUG requires a direct object to examine.
            """)
    }

    @Test("Cannot debug non-existent item")
    func testCannotDebugNonExistentItem() async throws {
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
        try await engine.execute("debug nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot debug non-existent location")
    func testCannotDebugNonExistentLocation() async throws {
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
        try await engine.execute("debug nonexistentRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > debug nonexistentRoom
            You can’t see any such thing.
            """)
    }

    @Test("Does not require light to debug")
    func testDoesNotRequireLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug lamp")

        // Then - Debug should work even in darkness
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug lamp")
        #expect(output.contains("```"))
        #expect(output.contains("Item"))
    }

    // MARK: - Processing Testing

    @Test("Debug item shows item details")
    func testDebugItemShowsDetails() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isTakable,
            .isWeapon,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("debug sword")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug sword")
        #expect(output.contains("```"))
        #expect(output.contains("Item"))
        #expect(output.contains("steel sword"))
        #expect(output.contains("sword"))  // Should show the ID
        #expect(output.contains("isTakable"))
        #expect(output.contains("isWeapon"))
    }

    @Test("Debug location shows location details")
    func testDebugLocationShowsDetails() async throws {
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
        try await engine.execute("debug testRoom")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug testRoom")
        #expect(output.contains("```"))
        #expect(output.contains("Location"))
        #expect(output.contains("Test Room"))
        #expect(output.contains("testRoom"))  // Should show the ID
        #expect(output.contains("inherentlyLit"))
    }

    @Test("Debug player shows player details")
    func testDebugPlayerShowsDetails() async throws {
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
        try await engine.execute("debug me")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug me")
        #expect(output.contains("```"))
        #expect(output.contains("Player"))
        #expect(output.contains("testRoom"))  // Should show current location
    }

    @Test("Debug self alias works")
    func testDebugSelfAlias() async throws {
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
        try await engine.execute("debug self")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug self")
        #expect(output.contains("```"))
        #expect(output.contains("Player"))
    }

    @Test("Debug item with flags shows flag details")
    func testDebugItemWithFlagsShowsFlags() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .isDevice,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set the lamp to be on for more detailed debug output
        try await engine.apply(
            await engine.setFlag(.isOn, on: try await engine.item("lamp"))
        )

        // When
        try await engine.execute("debug lamp")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug lamp")
        #expect(output.contains("```"))
        #expect(output.contains("Item"))
        #expect(output.contains("brass lamp"))
        #expect(output.contains("isTakable"))
        #expect(output.contains("isLightSource"))
        #expect(output.contains("isDevice"))
        #expect(output.contains("isOn"))
        #expect(output.contains("player"))  // Should show parent location
    }

    @Test("Debug item not in scope still works")
    func testDebugItemNotInScopeStillWorks() async throws {
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

        let remoteItem = Item(
            id: "remoteItem",
            .name("remote item"),
            .description("An item in another room."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Debug should work even on items not in current scope
        try await engine.execute("debug remoteItem")

        // Then
        let output = await mockIO.flush()
        let lines = output.components(separatedBy: "\n")

        #expect(lines.first == "> debug remoteItem")
        #expect(output.contains("```"))
        #expect(output.contains("Item"))
        #expect(output.contains("remote item"))
        #expect(output.contains("anotherRoom"))
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = DebugActionHandler()
        // DebugActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DebugActionHandler()
        #expect(handler.verbs.contains(.debug))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = DebugActionHandler()
        #expect(handler.requiresLight == false)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = DebugActionHandler()
        #expect(handler.syntax.count == 1)

        // Should have .match(.verb) syntax
        let _ = handler.syntax[0]
        // Note: We can’t easily test the internal structure of SyntaxRule,
        // but we can verify the count and that syntax testing above works
    }
}
