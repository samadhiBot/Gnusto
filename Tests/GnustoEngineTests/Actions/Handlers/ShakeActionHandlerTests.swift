import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ShakeActionHandler Tests")
struct ShakeActionHandlerTests {

    @Test("Shake validates missing direct object")
    func testShakeValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("shake")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake
            Expected a direct object phrase for verb '.shake'.
            """)
    }

    @Test("Shake container shows rattle message")
    func testShakeContainerShowsRattleMessage() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTakable
        )

        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake box
            You shake the wooden box and hear something rattling inside.
            """)
    }

    @Test("Shake bottle shows slosh message")
    func testShakeBottleShowsSloshMessage() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("glass bottle"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: bottle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake bottle
            You shake the glass bottle and hear liquid sloshing inside.
            """)
    }

    @Test("Shake vial shows slosh message")
    func testShakeVialShowsSloshMessage() async throws {
        // Given
        let vial = Item(
            id: "vial",
            .name("small vial"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: vial)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake vial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake vial
            You shake the small vial and hear liquid sloshing inside.
            """)
    }

    @Test("Shake fixed object shows different message")
    func testShakeFixedObjectShowsDifferentMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake wall
            You can't shake the stone wall - it's firmly in place.
            """)
    }

    @Test("Shake takable object shows appropriate message")
    func testShakeTakableObjectShowsAppropriateMessage() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("old book"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake book
            You shake the old book vigorously, but nothing happens.
            """)
    }

    @Test("Shake updates state correctly")
    func testShakeUpdatesStateCorrectly() async throws {
        // Given
        let jar = Item(
            id: "jar",
            .name("jar"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTakable
        )

        let game = MinimalGame(items: jar)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shake jar")

        // Then - Check state was updated
        let finalJar = try await engine.item("jar")
        #expect(finalJar.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shake jar
            You shake the jar and hear something rattling inside.
            """)
    }
}
