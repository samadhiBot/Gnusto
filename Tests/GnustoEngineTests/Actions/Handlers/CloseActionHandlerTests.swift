import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    @Test("Close open container successfully")
    func testCloseOpenContainerSuccessfully() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen  // Start open
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        let initialBox = try await engine.item("box")
        #expect(initialBox.attributes[.isOpen] == true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("close box")

        // Assert State Change
        let finalBox = try await engine.item("box")
        #expect(finalBox.attributes[.isOpen] == false)
        #expect(finalBox.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            Closed.
            """)

        // Assert Change History
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(
            changeHistory,
            [
                StateChange(
                    entityID: .item(box.id),
                    attribute: .itemAttribute(.isOpen),
                    oldValue: true,  // Assume it was open before closing
                    newValue: false
                ),
                StateChange(
                    entityID: .item(box.id),
                    attribute: .itemAttribute(.isTouched),
                    newValue: true,
                ),
                StateChange(
                    entityID: .global,
                    attribute: .pronounReference(pronoun: "it"),
                    newValue: .entityReferenceSet([.item(box.id)])
                ),
            ])
    }

    @Test("Close fails if already closed")
    func testCloseFailsIfAlreadyClosed() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable
            // Starts closed by default (no .isOpen)
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("close box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            The wooden box is already closed.
            """)

        // Assert Change History
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Close fails if not openable")
    func testCloseFailsIfNotOpenable() async throws {
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.location(.startRoom))
            // isContainer/isOpenable are false by default
        )
        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("close rock")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close rock
            You can’t close the smooth rock.
            """)

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Close fails if item not accessible")
    func testCloseFailsIfNotAccessible() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.nowhere),
            .isOpenable,
            .isOpen  // Start open
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("close box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            You can’t see any such thing.
            """)

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("close")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close
            Close what?
            """)

        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
