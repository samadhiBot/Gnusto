import CustomDump
import Testing

@testable import GnustoEngine

@Suite("MoveActionHandler Tests")
struct MoveActionHandlerTests {
    let handler = MoveActionHandler()

    @Test("Move simple object (reachable)")
    func testMoveSimpleObjectReachable() async throws {
        // Given
        let leaves = Item(
            id: "leaves",
            .name("pile of leaves"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [leaves])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("leaves"),
            rawInput: "move leaves"
        )

        // When
        await engine.execute(command: command)

        // Then
        let finalItemState = try await engine.item("leaves")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "Moving the pile of leaves doesn’t accomplish anything.")
    }

    @Test("Move object not present")
    func testMoveObjectNotPresent() async throws {
        // Given
        let game = MinimalGame(items: [])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("leaves"),
            rawInput: "move leaves"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
    }

    @Test("Move object not reachable")
    func testMoveObjectNotReachable() async throws {
        // Given
        let leaves = Item(
            id: "leaves",
            .name("pile of leaves"),
            .in(.nowhere) // Not reachable
        )

        let game = MinimalGame(items: [leaves])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("leaves"),
            rawInput: "move leaves"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
    }

    @Test("Move without direct object")
    func testMoveWithoutDirectObject() async throws {
        // Given
        let game = MinimalGame(items: [])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            rawInput: "move"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "Move what?")
    }

    @Test("Move held item")
    func testMoveHeldItem() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player)
        )

        let game = MinimalGame(items: [key])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("key"),
            rawInput: "move key"
        )

        // When
        await engine.execute(command: command)

        // Then
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "Moving the brass key doesn’t accomplish anything.")
    }

    @Test("Move object in container (open)")
    func testMoveObjectInOpenContainer() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.item("box"))
        )
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )

        let game = MinimalGame(items: [key, box])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("key"),
            rawInput: "move key"
        )

        // When
        await engine.execute(command: command)

        // Then
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "Moving the brass key doesn’t accomplish anything.")
    }

    @Test("Move object in closed container")
    func testMoveObjectInClosedContainer() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.item("box"))
        )
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer // Not open
        )

        let game = MinimalGame(items: [key, box])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            parser: mockParser
        )

        let command = Command(
            verb: .move,
            directObject: .item("key"),
            rawInput: "move key"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")
    }
}
