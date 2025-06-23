import CustomDump
import Testing

@testable import GnustoEngine

@Suite("WaveActionHandler Tests")
struct WaveActionHandlerTests {

    @Test("Wave validates missing direct object")
    func testWaveValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("wave")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave
            Wave what?
            """)
    }

    @Test("Wave validates item not reachable")
    func testWaveValidatesItemNotReachable() async throws {
        // Given
        let distantWand = Item(
            id: "distant_wand",
            .name("distant wand"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: distantWand)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("wave distant wand")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave distant wand
            You can’t see any such thing.
            """)
    }

    @Test("Wave sword shows brandish message")
    func testWaveSwordShowsBrandishMessage() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("sharp sword"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWeapon
        )

        let game = MinimalGame(items: sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave sword
            You brandish the sharp sword menacingly.
            """)
    }

    @Test("Wave blade shows brandish message")
    func testWaveBladeShowsBrandishMessage() async throws {
        // Given
        let blade = Item(
            id: "blade",
            .name("razor blade"),
            .in(.location(.startRoom)),
            .isTakable,
            .isWeapon
        )

        let game = MinimalGame(items: blade)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave blade")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave blade
            You brandish the razor blade menacingly.
            """)
    }

    @Test("Wave fixed object shows different message")
    func testWaveFixedObjectShowsDifferentMessage() async throws {
        // Given
        let tree = Item(
            id: "tree",
            .name("large tree"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: tree)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave tree
            You can’t wave the large tree around – it’s not something you
            can pick up and wave.
            """)
    }

    @Test("Wave updates state correctly")
    func testWaveUpdatesStateCorrectly() async throws {
        // Given
        let wand = Item(
            id: "wand",
            .name("magic wand"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: wand)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wave wand")

        // Then - Check that the item was touched
        let finalWand = try await engine.item("wand")
        #expect(finalWand.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wave wand
            You give the magic wand a little wave.
            """)
    }
}
