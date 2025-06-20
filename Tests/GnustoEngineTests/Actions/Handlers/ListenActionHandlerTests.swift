import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ListenActionHandler Tests")
struct ListenActionHandlerTests {
    // MARK: - Basic Functionality Tests

    @Test("LISTEN command produces the expected message")
    func testListenBasicFunctionality() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("listen")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN produces correct ActionResult")
    func testListenActionResult() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("listen")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN validation always succeeds")
    func testListenValidationSucceeds() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("listen")

        // Assert - Should not throw and should produce output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN full workflow integration test")
    func testListenFullWorkflow() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("listen")

        // Assert complete workflow
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN does not affect game state")
    func testListenDoesNotAffectGameState() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Capture initial state
        let initialState = await engine.gameState
        let initialScore = initialState.player.score
        let initialLocation = initialState.player.currentLocationID

        // Execute LISTEN
        try await engine.execute("listen")

        // Verify state hasn't changed significantly (moves will increment)
        let finalState = await engine.gameState
        #expect(finalState.player.score == initialScore)
        #expect(finalState.player.currentLocationID == initialLocation)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN works regardless of game state")
    func testListenWorksInDifferentStates() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Modify game state
        let scoreChange = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: 100
        )
        try await engine.apply(scoreChange)

        // Act: LISTEN should work the same regardless of game state
        try await engine.execute("listen")

        // Assert Output is unchanged
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN works in different locations")
    func testListenWorksInDifferentLocations() async throws {
        let location1 = Location(
            id: "location1",
            .name("Quiet Room"),
            .description("A very quiet room.")
        )
        let location2 = Location(
            id: "location2",
            .name("Noisy Room"),
            .description("A potentially noisy room.")
        )

        let game = MinimalGame(locations: location1, location2)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test in first location
        try await engine.execute("listen")
        let output1 = await mockIO.flush()
        expectNoDifference(output1, """
            > listen
            You hear nothing unusual.
            """)

        // Move to second location
        let moveChange = StateChange(
            entityID: .player,
            attribute: .playerLocation,
            newValue: .parentEntity(.location("location2"))
        )
        try await engine.apply(moveChange)

        // Test in second location - should give same generic response
        try await engine.execute("listen")
        let output2 = await mockIO.flush()
        expectNoDifference(output2, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN with extra text still works")
    func testListenWithExtraText() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act: Use engine.execute for full pipeline
        try await engine.execute("listen carefully")

        // Assert Output - should still work the same way
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen carefully
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN message is consistent across multiple calls")
    func testListenConsistency() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Execute LISTEN multiple times
        try await engine.execute("listen")
        let firstOutput = await mockIO.flush()

        try await engine.execute("listen")
        let secondOutput = await mockIO.flush()

        try await engine.execute("listen")
        let thirdOutput = await mockIO.flush()

        // All outputs should be identical
        expectNoDifference(firstOutput, """
            > listen
            You hear nothing unusual.
            """)
        expectNoDifference(secondOutput, """
            > listen
            You hear nothing unusual.
            """)
        expectNoDifference(thirdOutput, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN works in dark room")
    func testListenWorksInDarkRoom() async throws {
        let darkLocation = Location(
            id: "dark_room",
            .name("Dark Room"),
            .description("A completely dark room.")
            // No .inherentlyLit, so it should be dark
        )

        let player = Player(in: "dark_room")
        let game = MinimalGame(
            player: player,
            locations: darkLocation
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: LISTEN should work even in dark rooms
        try await engine.execute("listen")

        // Assert Output - should still work
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN works with items present")
    func testListenWorksWithItemsPresent() async throws {
        let noisyItem = Item(
            id: "clock",
            .name("ticking clock"),
            .description("A loudly ticking clock."),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: noisyItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act: Default LISTEN should still give generic response even with noisy items
        try await engine.execute("listen")

        // Assert Output - generic response (custom item sounds would need custom handlers)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }
}
