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
        try await engine.execute("kiss the princess", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss the princess
            You lean in to kiss the beautiful princess with unshakable
            confidence in your interpersonal appeal.
            
            > kiss the princess
            You lean in to kiss the beautiful princess with the confident
            charm of one who knows their worth.
            
            > kiss the princess
            You pucker up at the beautiful princess with the fearless
            romanticism of one who shoots their shot.
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
            You kiss the pebble with impressive commitment to expressing
            affection in all its forms.
            
            > kiss the pebble
            You kiss the pebble curiously, but your curiosity
            remains unsatisfied.
            
            > kiss the pebble
            You plant a smooch on the pebble with admirable openness to
            unconventional relationships.
            """)
    }

    @Test("Kiss self returns varied responses")
    func testKissSelf() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("kiss myself", times: 3)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kiss myself
            You give yourself a passionate smooch with admirable commitment
            to being your own best partner.
            
            > kiss myself
            You smooch yourself with the fearless self-appreciation of
            someone who knows their value.
            
            > kiss myself
            You kiss yourself with impressive range in your capacity for
            love and appreciation.
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

        // When
        try await engine.execute("kiss mirror")

        // Then - Check that the item was touched
        let finalMirror = try await engine.item("mirror")
        #expect(finalMirror.hasFlag(.isTouched))
    }
}
