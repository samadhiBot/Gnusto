import CustomDump
import Testing

@testable import GnustoEngine

@Suite("EnterActionHandler Tests")
struct EnterActionHandlerTests {

    @Test("Enter validates missing direct object with no enterable items")
    func testEnterValidatesMissingDirectObjectWithNoEnterableItems() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When/Then
        try await engine.execute("enter")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter
            There's nothing here to enter.
            """)
    }

    @Test("Enter validates non-item direct object")
    func testEnterValidatesNonItemDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When/Then
        try await engine.execute("enter self")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter self
            You can't enter that.
            """)
    }

    @Test("Enter validates item not accessible")
    func testEnterValidatesItemNotAccessible() async throws {
        // Given
        let booth = Item(
            id: "booth",
            .name("phone booth"),
            .isEnterable,
            .in(.nowhere)  // Not accessible
        )

        let game = MinimalGame(items: booth)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When/Then
        try await engine.execute("enter booth")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter booth
            You can't see any booth here.
            """)
    }

    @Test("Enter validates item not enterable")
    func testEnterValidatesItemNotEnterable() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .in(.location(.startRoom))  // Accessible but not enterable
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When/Then
        try await engine.execute("enter rock")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter rock
            You can't enter the large rock.
            """)
    }

    @Test("Enter processes enterable object")
    func testEnterProcessesEnterableObject() async throws {
        // Given
        let booth = Item(
            id: "booth",
            .name("phone booth"),
            .isEnterable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: booth)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("enter booth")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > enter booth
            You enter the phone booth.
            """)
    }
}
