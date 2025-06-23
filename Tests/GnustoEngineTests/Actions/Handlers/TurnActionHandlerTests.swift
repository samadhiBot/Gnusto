import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TurnActionHandler Tests")
struct TurnActionHandlerTests {

    @Test("Turn validates missing direct object")
    func testTurnValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("turn")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn
            Turn what?
            """)
    }

    @Test("Turn dial shows clicking message")
    func testTurnDialShowsClickingMessage() async throws {
        // Given
        let dial = Item(
            id: "dial",
            .name("metal dial"),
            .in(.location(.startRoom)),
            .isDial
        )

        let game = MinimalGame(items: dial)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            You turn the metal dial. It clicks into a new position.
            """)
    }

    @Test("Turn knob shows clicking message")
    func testTurnKnobShowsClickingMessage() async throws {
        // Given
        let knob = Item(
            id: "knob",
            .name("brass knob"),
            .in(.location(.startRoom)),
            .isKnob
        )

        let game = MinimalGame(items: knob)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn knob")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn knob
            You turn the brass knob. It clicks into a new position.
            """)
    }

    @Test("Turn wheel shows grinding message")
    func testTurnWheelShowsGrindingMessage() async throws {
        // Given
        let wheel = Item(
            id: "wheel",
            .name("large wheel"),
            .in(.location(.startRoom)),
            .isWheel
        )

        let game = MinimalGame(items: wheel)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn wheel")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn wheel
            You turn the large wheel. It rotates with some effort.
            """)
    }

    @Test("Turn handle shows appropriate message")
    func testTurnHandleShowsAppropriateMessage() async throws {
        // Given
        let handle = Item(
            id: "handle",
            .name("door handle"),
            .in(.location(.startRoom)),
            .isHandle
        )

        let game = MinimalGame(items: handle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn handle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn handle
            You turn the door handle. It moves with a grinding sound.
            """)
    }

    @Test("Turn key shows guidance message")
    func testTurnKeyShowsGuidanceMessage() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable,
            .isKey
        )

        let game = MinimalGame(items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn key
            You can’t just turn the brass key by itself. You need to use it
            with something.
            """)
    }

    @Test("Turn character shows prevention message")
    func testTurnCharacterShowsPreventionMessage() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: cat)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn cat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn cat
            You can’t turn the fluffy cat around like an object.
            """)
    }

    @Test("Turn regular object shows default message")
    func testTurnRegularObjectShowsDefaultMessage() async throws {
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
        try await engine.execute("turn book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn book
            You turn the old book around in your hands, but
            nothing happens.
            """)
    }

    @Test("Turn integration test")
    func testTurnIntegrationTest() async throws {
        // Given
        let dial = Item(
            id: "dial",
            .name("dial"),
            .in(.location(.startRoom)),
            .isDial
        )

        let game = MinimalGame(items: dial)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn dial")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn dial
            You turn the dial. It clicks into a new position.
            """)
    }
}
