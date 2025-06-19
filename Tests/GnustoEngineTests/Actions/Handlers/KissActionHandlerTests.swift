import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {

    @Test("Kiss validates missing direct object")
    func testKissValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("kiss")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss
            Kiss what?
            """)
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

        // Act
        try await engine.execute("kiss princess")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss princess
            The beautiful princess doesn't seem particularly receptive to your affections.
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
            You plant a brief kiss on the pebble, yet your lips learn nothing new.

            > kiss the pebble
            You plant a small kiss on the pebble, learning nothing your eyes hadn't already told you.
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
            You can't kiss that.
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
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss mirror")

        // Then - Check that the item was touched
        let finalMirror = try await engine.item("mirror")
        #expect(finalMirror.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss mirror
            You kiss it curiously, but your curiosity remains unsatisfied.
            """)
    }
}
