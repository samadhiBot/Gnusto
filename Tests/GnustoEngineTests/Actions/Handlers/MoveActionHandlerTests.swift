import CustomDump
import Testing

@testable import GnustoEngine

@Suite("MoveActionHandler Tests")
struct MoveActionHandlerTests {

    @Test("Move simple object (reachable)")
    func testMoveSimpleObjectReachable() async throws {
        // Given
        let leaves = Item(
            id: "leaves",
            .name("pile of leaves"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: leaves)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move leaves")

        // Then
        let finalItemState = try await engine.item("leaves")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move leaves
            Moving the pile of leaves doesn’t accomplish anything.
            """)
    }

    @Test("Move object not present")
    func testMoveObjectNotPresent() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("move leaves")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move leaves
            You can’t see any pile of leaves here.
            """)
    }

    @Test("Move object not reachable")
    func testMoveObjectNotReachable() async throws {
        // Given
        let leaves = Item(
            id: "leaves",
            .name("pile of leaves"),
            .in(.nowhere)  // Not reachable
        )

        let game = MinimalGame(items: leaves)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move leaves")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move leaves
            You can’t see any pile of leaves here.
            """)
    }

    @Test("Move without direct object")
    func testMoveWithoutDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When
        try await engine.execute("move")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move
            Move what?
            """)
    }

    @Test("Move held item")
    func testMoveHeldItem() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.player)
        )

        let game = MinimalGame(items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move key")

        // Then
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move key
            Moving the brass key doesn’t accomplish anything.
            """)
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

        let game = MinimalGame(items: key, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move key")

        // Then
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move key
            Moving the brass key doesn’t accomplish anything.
            """)
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
            .isContainer  // Not open
        )

        let game = MinimalGame(items: key, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("move key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > move key
            You can’t see any brass key here.
            """)
    }
}
