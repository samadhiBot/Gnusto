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

    // MARK: - Processing Tests

    @Test("DEBUG player produces formatted output")
    func testProcessPlayerDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug self")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and player data
        expectNoDifference(output, """
            > debug self
            ```
            Player(
              carryingCapacity: 100,
              currentLocationID: .startRoom,
              health: 100,
              moves: 0,
              score: 0
            )
            ```
            """)
    }

    @Test("DEBUG item produces formatted output")
    func testProcessItemDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test item")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and item data
        expectNoDifference(output, """
            > debug test item
            ```
            Item(
              id: .test_item,
              attributes: [
                .description: .string("A test item for debugging."),
                .isTakable: .bool(true),
                .name: .string("test item"),
                .parentEntity: .parentEntity(..player)
              ]
            )
            ```
            """)
    }

    @Test("DEBUG location produces formatted output")
    func testProcessLocationDebug() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("debug test location")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain markdown code block and location data
        expectNoDifference(output, """
            > debug test location
            ```
            Location(
              id: .test_location,
              attributes: [
                .description: .string("A test location for debugging."),
                .exits: .exits(.north: to: .other_location),
                .name: .string("Test Location")
              ]
            )
            ```
            """)
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
        expectNoDifference(output, """
            > debug self
            ```
            Player(
              carryingCapacity: 100,
              currentLocationID: .startRoom,
              health: 100,
              moves: 0,
              score: 0
            )
            ```
            """)
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
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: complexItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("debug complex item")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex item data
        expectNoDifference(output, """
            > debug complex item
            ```
            Item(
              id: .complex_item,
              attributes: [
                .capacity: .int(5),
                .description: .string("A complex item with many properties."),
                .isContainer: .bool(true),
                .isOpenable: .bool(true),
                .isTakable: .bool(true),
                .isWearable: .bool(true),
                .name: .string("complex item"),
                .parentEntity: .parentEntity(
                  .location(.startRoom)
                ),
                .size: .int(10)
              ]
            )
            ```
            """)
    }

    @Test("DEBUG works with location that has complex exits")
    func testDebugComplexLocation() async throws {
        let complexLocation = Location(
            id: "complex_location",
            .name("complex Location"),
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
        try await engine.execute("debug complex Location")

        // Assert Output
        let output = await mockIO.flush()

        // Should contain complex location data
        expectNoDifference(output, """
            > debug complex Location
            ```
            Location(
              id: .complex_location,
              attributes: [
                .description: .string("A location with multiple exits and properties."),
                .exits: .exits(
                  .east: to: .east_room
                  .north: to: .north_room
                  .south: to: .south_room
                  .west: to: .west_room
                ),
                .inherentlyLit: .bool(true),
                .name: .string("complex Location")
              ]
            )
            ```
            """)
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
        expectNoDifference(output, """
            > debug self
            ```
            Player(
              carryingCapacity: 100,
              currentLocationID: .startRoom,
              health: 100,
              moves: 50,
              score: 100
            )
            ```
            """)
    }
}
