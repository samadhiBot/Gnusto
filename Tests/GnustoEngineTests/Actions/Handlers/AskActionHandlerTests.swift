import CustomDump
import Testing

@testable import GnustoEngine

@Suite("AskActionHandler Tests")
struct AskActionHandlerTests {
    let handler = AskActionHandler()

    @Test("Ask requires direct object")
    func testAskRequiresDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When/Then
        try await engine.execute("ask")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask
            Ask whom?
            """)
    }

    @Test("Ask requires indirect object")
    func testAskRequiresIndirectObject() async throws {
        // Given
        let character = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: character)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When/Then
        try await engine.execute("ask wizard")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard
            Ask about what?
            """)
    }

    @Test("Ask requires character as direct object")
    func testAskRequiresCharacter() async throws {
        // Given
        let rock = Item(id: "rock", .name("rock"), .in(.location(.startRoom)))
        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When/Then
        try await engine.execute("ask rock about rock")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask rock about rock
            You can’t ask the rock about that.
            """)
    }

    @Test("Ask character about item")
    func testAskCharacterAboutItem() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .in(.location(.startRoom))
        )
        let game = MinimalGame(items: wizard, crystal)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("ask wizard about crystal")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about crystal
            Old wizard doesn’t seem to know anything about a magic crystal.
            """)
    }

    @Test("Ask character about player")
    func testAskCharacterAboutPlayer() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("ask wizard about me")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about me
            Old wizard doesn’t seem to know anything about you.
            """)
    }

    @Test("Ask character about location")
    func testAskCharacterAboutLocation() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("ask wizard about room")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about room
            Old wizard doesn’t seem to know anything about any Void.
            """)
    }

    @Test("Ask inaccessible character fails")
    func testAskInaccessibleCharacterFails() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.nowhere),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("ask wizard about wizard")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about wizard
            You can’t see any wizard here.
            """)
    }
}
