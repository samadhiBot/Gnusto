import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DebugActionHandler Tests")
struct DebugActionHandlerTests {
    // MARK: - Setup Helper

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let testItem = Item(
            id: "test_item",
            .name("test item"),
            .description("A test item for debugging."),
            .isTakable,
            .in(.player)
        )

        let testLocation = Location(
            id: "test_location",
            .name("Test Location"),
            .description("A test location for debugging."),
            .exits([
                .north: .to("other_location")
            ])
        )

        return await GameEngine.test(
            blueprint: MinimalGame(
                locations: testLocation,
                items: testItem
            )
        )
    }

    // MARK: - Validation Tests

    @Test("DEBUG fails with no direct object")
    func testValidationFailsWithNoDirectObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug
            DEBUG requires a direct object to examine.
            """)
    }

    @Test("DEBUG validates player successfully")
    func testValidationSucceedsForPlayer() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug self")

        // Assert Output
        let output = await mockIO.flush()
        #expect(output.contains("```"))
        #expect(output.contains("Player") || output.contains("player"))
    }

    @Test("DEBUG validates existing item successfully")
    func testValidationSucceedsForExistingItem() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test_item")

        // Assert Output
        let output = await mockIO.flush()
        #expect(output.contains("```"))
        #expect(output.contains("test_item") || output.contains("Item"))
    }

    @Test("DEBUG validates existing location successfully")
    func testValidationSucceedsForExistingLocation() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test_location")

        // Assert Output
        let output = await mockIO.flush()
        #expect(output.contains("```"))
        #expect(output.contains("test_location") || output.contains("Location"))
    }

    @Test("DEBUG fails for non-existent item")
    func testValidationFailsForNonExistentItem() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug nonexistent_item")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug nonexistent_item
            You can’t see any such thing.
            """)
    }

    @Test("DEBUG fails for non-existent location")
    func testValidationFailsForNonExistentLocation() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug nonexistent_location")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > debug nonexistent_location
            You can’t see any such thing.
            """)
    }

    // MARK: - Processing Tests

    @Test("DEBUG player produces formatted output")
    func testProcessPlayerDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug self")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and player data
        #expect(output.contains("```"))
        #expect(output.contains("Player") || output.contains("player"))
    }

    @Test("DEBUG item produces formatted output")
    func testProcessItemDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test_item")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and item data
        #expect(output.contains("```"))
        #expect(output.contains("test_item") || output.contains("Item"))
    }

    @Test("DEBUG location produces formatted output")
    func testProcessLocationDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test_location")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and location data
        #expect(output.contains("```"))
        #expect(output.contains("test_location") || output.contains("Location"))
    }

    // MARK: - Output Format Tests

    @Test("DEBUG output is properly formatted with code blocks")
    func testOutputFormatting() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug self")

        // Assert Output
        let output = await mockIO.flush()

        // Should start and end with code block markers
        #expect(output.contains("```"))
    }

    @Test("DEBUG output contains meaningful entity data")
    func testOutputContainsMeaningfulData() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Test item debug
        try await engine.execute("debug test_item")
        let itemOutput = await mockIO.flush()

        // Should contain item-specific data
        #expect(
            itemOutput.contains("test_item") == true
                || itemOutput.contains("id") == true)

        // Test location debug
        try await engine.execute("debug test_location")
        let locationOutput = await mockIO.flush()

        // Should contain location-specific data
        #expect(
            locationOutput.contains("test_location") == true
                || locationOutput.contains("id") == true)
    }

    // MARK: - Edge Cases

    @Test("DEBUG works with item that has complex properties")
    func testDebugComplexItem() async throws {
        let complexItem = Item(
            id: "complex_item",
            .name("complex item"),
            .description("A complex item with many properties."),
            .isTakable,
            .isWearable,
            .isOpenable,
            .isContainer,
            .size(10),
            .capacity(5),
            .in(.location("test_location"))
        )

        let game = MinimalGame(items: complexItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("debug complex_item")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex item data
        #expect(output.contains("```"))
        #expect(output.contains("complex_item"))
    }

    @Test("DEBUG works with location that has complex exits")
    func testDebugComplexLocation() async throws {
        let complexLocation = Location(
            id: "complex_location",
            .name("Complex Location"),
            .description("A location with multiple exits and properties."),
            .exits([
                .north: .to("north_room"),
                .south: .to("south_room"),
                .east: .to("east_room"),
                .west: .to("west_room"),
            ]),
            .inherentlyLit
        )

        let game = MinimalGame(locations: complexLocation)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("debug complex_location")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex location data
        #expect(output.contains("```"))
        #expect(output.contains("complex_location"))
    }

    @Test("DEBUG works with player that has modified state")
    func testDebugModifiedPlayer() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Modify player state
        let scoreChange = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: 100
        )
        try await engine.apply(scoreChange)

        let movesChange = StateChange(
            entityID: .player,
            attribute: .playerMoves,
            newValue: 50
        )
        try await engine.apply(movesChange)

        // Act
        try await engine.execute("debug self")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain player data
        #expect(output.contains("```"))
        #expect(output.contains("Player") || output.contains("player"))
    }
}
