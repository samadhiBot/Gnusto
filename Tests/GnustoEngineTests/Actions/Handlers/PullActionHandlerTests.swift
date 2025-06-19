import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PullActionHandler")
struct PullActionHandlerTests {
    let handler = PullActionHandler()

    @Test("Pull pullable rope successfully")
    func testPullPullableRopeSuccessfully() async throws {
        // Arrange
        let rope = Item(
            id: "rope",
            .name("rope"),
            .isPullable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .pull,
            directObject: .item("rope"),
            rawInput: "pull rope"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalRopeState = try await engine.item("rope")
        #expect(finalRopeState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "You pull the rope.")
    }

    @Test("Pull non-pullable item fails")
    func testPullNonPullableItemFails() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
            // Note: not pullable
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .pull,
            directObject: .item("rock"),
            rawInput: "pull rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t pull the rock.")
    }

    @Test("Pull with no object fails")
    func testPullWithNoObjectFails() async throws {
        // Arrange
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .pull,
            directObject: nil,
            rawInput: "pull"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Pull what?")
    }

    @Test("Pull unreachable rope fails")
    func testPullUnreachableRopeFails() async throws {
        // Arrange
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .description("Another room."),
            .inherentlyLit
        )

        // The default startRoom in MinimalGame is lit. We need a dark one.
        let startRoom = Location(
            id: "startRoom",
            .name("Start Room"),
            .description("The start room."),
            .inherentlyLit
        )

        let distantRope = Item(
            id: "distantRope",
            .name("distant rope"),
            .isPullable,
            .in(.location("otherRoom"))
        )

        let game = MinimalGame(
            locations: startRoom, otherRoom,
            items: distantRope
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .pull,
            directObject: .item("distantRope"),
            rawInput: "pull distant rope"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
    }
}
