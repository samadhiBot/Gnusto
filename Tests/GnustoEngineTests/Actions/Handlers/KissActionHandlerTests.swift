import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {
    let handler = KissActionHandler()

    @Test("Kiss validates missing direct object")
    func testKissValidatesMissingDirectObject() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

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

        let game = MinimalGame(items: princess)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .kiss,
            directObject: .item("princess"),
            rawInput: "kiss princess"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            The beautiful princess doesn’t seem particularly receptive to
            your affections.
            """)
    }

    @Test("Kiss object returns varied responses")
    func testKissObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("kiss the pebble", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss the pebble
            You kiss it curiously, but your curiosity remains unsatisfied.

            > kiss the pebble
            You plant a brief kiss on the pebble, yet your lips learn
            nothing new.

            > kiss the pebble
            You plant a small kiss on the pebble, learning nothing your
            eyes hadn’t already told you.
            """)
    }

    @Test("Kiss self returns varied responses")
    func testKissSelf() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("kiss myself")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss myself
            You can’t kiss that.
            """)
    }

    @Test("Kiss updates state correctly")
    func testKissUpdatesStateCorrectly() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("mirror"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: mirror)
        let (engine, _) = await GameEngine.test(blueprint: game)

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
            change.entityID == .item("mirror") && change.attribute == .itemAttribute(.isTouched)
                && change.newValue == true
        })
        #expect(hasTouchedChange)
    }
}
