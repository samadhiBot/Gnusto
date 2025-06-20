import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PressActionHandler")
struct PressActionHandlerTests {

    @Test("Press pressable button successfully")
    func testPressPressableButtonSuccessfully() async throws {
        // Arrange
        let button = Item(
            id: "button",
            .name("button"),
            .isPressable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: button)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("press button")

        // Assert
        let finalButtonState = try await engine.item("button")
        #expect(finalButtonState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > press button
            You press the button.
            """)
    }

    @Test("Press non-pressable item fails")
    func testPressNonPressableItemFails() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
            // Note: not pressable
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("press rock")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > press rock
            You can’t press the rock.
            """)
    }

    @Test("Press with no object fails")
    func testPressWithNoObjectFails() async throws {
        // Arrange
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("press")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > press
            Press what?
            """)
    }

    @Test("Press unreachable button fails")
    func testPressUnreachableButtonFails() async throws {
        // Arrange
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .description("Another room."),
            .inherentlyLit
        )

        let startRoom = Location(
            id: "startRoom",
            .name("Start Room"),
            .description("The start room."),
            .inherentlyLit
        )

        let distantButton = Item(
            id: "distantButton",
            .name("distant button"),
            .isPressable,
            .in(.location("otherRoom"))
        )

        let game = MinimalGame(
            locations: startRoom, otherRoom,
            items: distantButton
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("press distant button")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > press distant button
            You can’t see any distant button here.
            """)
    }
}
