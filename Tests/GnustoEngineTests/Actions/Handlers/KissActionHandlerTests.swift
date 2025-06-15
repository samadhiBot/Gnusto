import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {
    let handler = KissActionHandler()

    @Test("Kiss validates missing direct object")
    func testKissValidatesMissingDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            rawInput: "kiss"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Kiss what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Kiss character shows appropriate message")
    func testKissCharacterShowsAppropriateMessage() async throws {
        // Given
        let princess = Item(
            id: "princess",
            .name("beautiful princess"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [princess])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("princess"),
            rawInput: "kiss princess"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            The beautiful princess doesn't seem particularly receptive to your affections.
            """)
    }

    @Test("Kiss mirror shows narcissism message")
    func testKissMirrorShowsNarcissismMessage() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("polished mirror"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [mirror])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("mirror"),
            rawInput: "kiss mirror"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    @Test("Kiss statue shows cold stone message")
    func testKissStatueShowsColdStoneMessage() async throws {
        // Given
        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [statue])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("statue"),
            rawInput: "kiss statue"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You kiss the marble statue. The cold stone is not very responsive."))
    }

    @Test("Kiss inappropriate object shows humorous message")
    func testKissInappropriateObjectShowsHumorousMessage() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("dirty rock"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("rock"),
            rawInput: "kiss rock"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You kiss the dirty rock. It tastes about as good as you'd expect."))
    }

    @Test("Kiss updates state correctly")
    func testKissUpdatesStateCorrectly() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("mirror"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [mirror])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("mirror"),
            rawInput: "kiss mirror"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.changes.contains(where: { change in
            change.entityID == .item("mirror") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Kiss integration test")
    func testKissIntegrationTest() async throws {
        // Given
        let frog = Item(
            id: "frog",
            .name("frog"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [frog])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .kiss,
            directObject: .item("frog"),
            rawInput: "kiss frog"
        )

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        #expect(output.contains("but it remains a frog"))
    }
}
