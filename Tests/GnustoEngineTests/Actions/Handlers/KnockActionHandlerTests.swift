import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {
    let handler = KnockActionHandler()

    @Test("Knock validates missing direct object")
    func testKnockValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(verb: .knock, rawInput: "knock")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Knock on what?")) {
            try await handler.validate(context: context)
        }
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

        let game = MinimalGame(items: [door])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .knock, directObject: .item("door"), rawInput: "knock door")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You knock on the wooden door, but there’s no answer.")
    }

    @Test("Knock wall shows sound message")
    func testKnockWallShowsSoundMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [wall])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .knock, directObject: .item("wall"), rawInput: "knock wall")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You knock on the stone wall, but nothing happens.")
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

        let game = MinimalGame(items: [chest])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .knock, directObject: .item("chest"), rawInput: "knock chest")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "Knocking on the wooden chest produces a hollow sound.")
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

        let game = MinimalGame(items: [door])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .knock, directObject: .item("door"), rawInput: "knock door")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "No need to knock, the door is already open.")
    }
}
