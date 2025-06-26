import CustomDump
import Testing

@testable import GnustoEngine

@Suite("HelpActionHandler Tests")
struct HelpActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("HELP syntax works")
    func testHelpSyntax() async throws {
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
        try await engine.execute("help")

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("> help"))
        #expect(output.contains("This is an interactive fiction game"))
        #expect(output.contains("Common commands:"))
        #expect(output.contains("LOOK or L"))
        #expect(output.contains("TAKE <object>"))
        #expect(output.contains("INVENTORY or I"))
        #expect(output.contains("SAVE"))
        #expect(output.contains("QUIT or Q"))
    }

    // MARK: - Validation Testing

    @Test("Help works in any condition")
    func testHelpWorksInAnyCondition() async throws {
        // Given: Dark room (help should still work)
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
        try await engine.execute("help")

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("> help"))
        #expect(output.contains("This is an interactive fiction game"))
        // Should not show darkness message since help doesn’t require light
        #expect(!output.contains("It is pitch black"))
    }

    // MARK: - Processing Testing

    @Test("Help displays complete help text")
    func testHelpDisplaysCompleteHelpText() async throws {
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
        try await engine.execute("help")

        // Then
        let output = await mockIO.flush()

        // Verify key sections of help text are present
        #expect(output.contains("This is an interactive fiction game"))
        #expect(output.contains("You control the story by typing commands"))
        #expect(output.contains("Common commands:"))

        // Verify common commands are listed
        #expect(output.contains("LOOK or L"))
        #expect(output.contains("EXAMINE <object> or X <object>"))
        #expect(output.contains("TAKE <object> or GET <object>"))
        #expect(output.contains("DROP <object>"))
        #expect(output.contains("INVENTORY or I"))
        #expect(output.contains("GO <direction>"))
        #expect(output.contains("OPEN <object>"))
        #expect(output.contains("CLOSE <object>"))
        #expect(output.contains("PUT <object> IN <container>"))
        #expect(output.contains("PUT <object> ON <surface>"))
        #expect(output.contains("SAVE"))
        #expect(output.contains("RESTORE"))
        #expect(output.contains("QUIT or Q"))

        // Verify guidance text
        #expect(output.contains("You can use multiple objects"))
        #expect(output.contains("Try different things"))
        #expect(output.contains("experimentation is part of the fun"))
    }

    @Test("Help works multiple times")
    func testHelpWorksMultipleTimes() async throws {
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

        // When: First help command
        try await engine.execute("help")

        // Then
        let output1 = await mockIO.flush()
        #expect(output1.contains("This is an interactive fiction game"))

        // When: Second help command
        try await engine.execute("help")

        // Then
        let output2 = await mockIO.flush()
        #expect(output2.contains("This is an interactive fiction game"))

        // Both should have identical content (excluding command echo)
        let helpContent1 = output1.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
        let helpContent2 = output2.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
        #expect(helpContent1 == helpContent2)
    }

    @Test("Help works in different locations")
    func testHelpWorksInDifferentLocations() async throws {
        // Given
        let startRoom = Location(
            id: "startRoom",
            .name("Start Room"),
            .inherentlyLit,
            .exits([.north: .to("endRoom")])
        )

        let endRoom = Location(
            id: "endRoom",
            .name("End Room"),
            .inherentlyLit,
            .exits([.south: .to("startRoom")])
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: startRoom, endRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Help in first room
        try await engine.execute("help")

        // Then
        let output1 = await mockIO.flush()
        #expect(output1.contains("This is an interactive fiction game"))

        // When: Move to another room
        try await engine.execute("north")
        await mockIO.flush()  // Clear movement output

        // When: Help in second room
        try await engine.execute("help")

        // Then
        let output2 = await mockIO.flush()
        #expect(output2.contains("This is an interactive fiction game"))

        // Help should work the same regardless of location
        let helpContent1 = output1.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
        let helpContent2 = output2.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
        #expect(helpContent1 == helpContent2)
    }

    @Test("Help works with items in inventory")
    func testHelpWorksWithItemsInInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A steel sword."),
            .isTakable,
            .in(.player)
        )

        let shield = Item(
            id: "shield",
            .name("wooden shield"),
            .description("A wooden shield."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, shield
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("help")

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("This is an interactive fiction game"))
        #expect(output.contains("Common commands:"))

        // Help should work regardless of what player is carrying
    }

    @Test("Help has no state changes")
    func testHelpHasNoStateChanges() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Check initial state
        let initialBookState = try await engine.item("book")
        let initialPlayerLocation = await engine.playerLocationID

        // When: Execute help
        try await engine.execute("help")
        await mockIO.flush()

        // Then: Verify no state changes
        let finalBookState = try await engine.item("book")
        let finalPlayerLocation = await engine.playerLocationID

        #expect(finalBookState.parent == initialBookState.parent)
        #expect(finalBookState.hasFlag(.isTouched) == initialBookState.hasFlag(.isTouched))
        #expect(finalPlayerLocation == initialPlayerLocation)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = HelpActionHandler()
        // HelpActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = HelpActionHandler()
        #expect(handler.verbs.contains(.help))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = HelpActionHandler()
        #expect(handler.requiresLight == false)
    }
}
