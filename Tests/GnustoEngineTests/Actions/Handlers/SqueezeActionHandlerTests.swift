import CustomDump
import Testing

@testable import GnustoEngine

@Suite("SqueezeActionHandler Tests")
struct SqueezeActionHandlerTests {

    @Test("Squeeze validates missing direct object")
    func testSqueezeValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("squeeze")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze
            Squeeze what?
            """)
    }

    @Test("Squeeze sponge shows water drip message")
    func testSqueezeSpongeShowsWaterDripMessage() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("wet sponge"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSponge
        )

        let game = MinimalGame(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze sponge")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze sponge
            You squeeze the wet sponge and water drips out.
            """)
    }

    @Test("Squeeze tube shows ooze message")
    func testSqueezeeTubeShowsOozeMessage() async throws {
        // Given
        let tube = Item(
            id: "tube",
            .name("toothpaste tube"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: tube)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze tube")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze tube
            You squeeze the toothpaste tube and some of its contents ooze out.
            """)
    }

    @Test("Squeeze bottle shows ooze message")
    func testSqueezeBottleShowsOozeMessage() async throws {
        // Given
        let bottle = Item(
            id: "bottle",
            .name("plastic bottle"),
            .in(.location(.startRoom)),
            .isTakable,
            .isLiquidContainer
        )

        let game = MinimalGame(items: bottle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze bottle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze bottle
            You squeeze the plastic bottle and some of its contents ooze out.
            """)
    }

    @Test("Squeeze pillow shows soft message")
    func testSqueezePillowShowsSoftMessage() async throws {
        // Given
        let pillow = Item(
            id: "pillow",
            .name("soft pillow"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSoft
        )

        let game = MinimalGame(items: pillow)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze pillow")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze pillow
            You squeeze the soft pillow. It feels soft and yielding.
            """)
    }

    @Test("Squeeze cushion shows soft message")
    func testSqueezeCushionShowsSoftMessage() async throws {
        // Given
        let cushion = Item(
            id: "cushion",
            .name("cushion"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: cushion)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze cushion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze cushion
            You squeeze the cushion as hard as you can, but it doesn't give.
            """)
    }

    @Test("Squeeze hard object shows appropriate message")
    func testSqueezeHardObjectShowsAppropriateMessage() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("hard rock"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze rock
            You squeeze the hard rock as hard as you can, but it doesn't give.
            """)
    }

    @Test("Squeeze updates state correctly")
    func testSqueezeUpdatesStateCorrectly() async throws {
        // Given
        let sponge = Item(
            id: "sponge",
            .name("sponge"),
            .in(.location(.startRoom)),
            .isTakable,
            .isSponge
        )

        let game = MinimalGame(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("squeeze sponge")

        // Then - Check state was updated
        let finalSponge = try await engine.item("sponge")
        #expect(finalSponge.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > squeeze sponge
            You squeeze the sponge and water drips out.
            """)
    }
}
