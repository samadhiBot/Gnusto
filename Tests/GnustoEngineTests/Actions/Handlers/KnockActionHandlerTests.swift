import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {

    @Test("Knock validates missing direct object")
    func testKnockValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("knock")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > knock
            Knock on what?
            """)
    }

    @Test("Knock door shows appropriate message")
    func testKnockDoorShowsAppropriateMessage() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .in(.location(.startRoom)),
            .isDoor
        )

        let game = MinimalGame(items: door)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on the door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > knock on the door
            You knock on the wooden door, but there’s no answer.
            """)
    }

    @Test("Knock wall shows sound message")
    func testKnockWallShowsSoundMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on the wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > knock on the wall
            You knock on the stone wall, but nothing happens.
            """)
    }

    @Test("Knock container shows hollow sound")
    func testKnockContainerShowsHollowSound() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .in(.location(.startRoom)),
            .isContainer
        )

        let game = MinimalGame(items: chest)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on the chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > knock on the chest
            Knocking on the wooden chest produces a hollow sound.
            """)
    }

    @Test("Knock integration test")
    func testKnockIntegrationTest() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("door"),
            .in(.location(.startRoom)),
            .isDoor,
            .isOpen
        )

        let game = MinimalGame(items: door)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("knock on the door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > knock on the door
            No need to knock, the door is already open.
            """)
    }
}
