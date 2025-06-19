import CustomDump
import Testing

import GnustoEngine

@Suite("InflateActionHandler")
struct InflateActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let inflatedBalloon = Item(
            id: "inflatedBalloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .isInflated,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: balloon, inflatedBalloon, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("INFLATE command on inflatable item")
    func testInflateCommand() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Check initial state
        let initialState = try await engine.hasFlag(.isInflated, on: "balloon")
        #expect(initialState == false)

        // Execute the command through the engine to properly apply state changes
        try await engine.execute("inflate balloon")

        // Check output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inflate balloon
            You inflate the balloon.
            """)

        // Verify balloon is now inflated
        #expect(try await engine.hasFlag(.isInflated, on: "balloon") == true)
    }

    @Test("INFLATE command on already inflated item")
    func testInflateAlreadyInflatedItem() async throws {
        let inflatedBalloon = Item(
            id: "inflatedBalloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .isInflated,
            .in(.player)
        )

        let game = MinimalGame(items: inflatedBalloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the engine to properly apply state changes
        try await engine.execute("inflate balloon")

        // Check output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inflate balloon
            The balloon is already inflated.
            """)
    }

    @Test("INFLATE command without direct object")
    func testInflateWithoutObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Execute the command
        try await engine.execute("inflate")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inflate
            Inflate what?
            """)
    }

    @Test("INFLATE command on non-inflatable item")
    func testInflateNonInflatableItem() async throws {
        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command
        try await engine.execute("inflate coin")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inflate coin
            You can't inflate the coin.
            """)
    }
}
