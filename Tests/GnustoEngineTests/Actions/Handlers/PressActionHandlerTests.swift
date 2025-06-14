import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PressActionHandler")
struct PressActionHandlerTests {
    let handler = PressActionHandler()

    @Test("Press pressable button successfully")
    func testPressPressableButtonSuccessfully() async throws {
        // Arrange
        let button = Item(
            id: "button",
            .name("button"),
            .isPressable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [button])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .press,
            directObject: .item("button"),
            rawInput: "press button"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalButtonState = try await engine.item("button")
        #expect(finalButtonState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "You press the button.")
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

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .press,
            directObject: .item("rock"),
            rawInput: "press rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t press the rock.")
    }

    @Test("Press with no object fails")
    func testPressWithNoObjectFails() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .press,
            directObject: nil,
            rawInput: "press"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Press what?")
    }

    @Test("Press unreachable button fails")
    func testPressUnreachableButtonFails() async throws {
        // Arrange
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .description("Another room.")
        )

        let distantButton = Item(
            id: "distantButton",
            .name("distant button"),
            .isPressable,
            .in(.location("otherRoom"))
        )

        let game = MinimalGame(
            locations: [otherRoom],
            items: [distantButton]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .press,
            directObject: .item("distantButton"),
            rawInput: "press distant button"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
    }
}
