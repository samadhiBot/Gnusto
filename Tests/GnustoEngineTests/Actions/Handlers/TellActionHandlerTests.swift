import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TellActionHandler Tests")
struct TellActionHandlerTests {

    @Test("Tell requires direct object")
    func testTellRequiresDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When/Then
        try await engine.execute("tell")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell
            Tell whom?
            """)
    }

    @Test("Tell requires indirect object")
    func testTellRequiresIndirectObject() async throws {
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
        try await engine.execute("tell wizard")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell wizard
            Tell about what?
            """)
    }

    @Test("Tell requires character as direct object")
    func testTellRequiresCharacter() async throws {
        // Given
        let rock = Item(id: "rock", .name("rock"), .in(.location(.startRoom)))
        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When/Then
        try await engine.execute("tell rock about rock")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell rock about rock
            You can't tell the rock about anything.
            """)
    }

    @Test("Tell character about item")
    func testTellCharacterAboutItem() async throws {
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

        // When
        try await engine.execute("tell wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell wizard about crystal
            Old wizard listens politely to what you say about magic crystal.
            """)
    }

    @Test("Tell character about player")
    func testTellCharacterAboutPlayer() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell wizard about me
            Old wizard listens politely to what you say about yourself.
            """)
    }

    @Test("Tell character about location")
    func testTellCharacterAboutLocation() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about room")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell wizard about room
            Old wizard listens politely to what you say about Void.
            """)
    }

    @Test("Tell inaccessible character fails")
    func testTellInaccessibleCharacterFails() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.nowhere),
            .isCharacter
        )
        let game = MinimalGame(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > tell wizard about wizard
            You can't see any wizard here.
            """)
    }
}
