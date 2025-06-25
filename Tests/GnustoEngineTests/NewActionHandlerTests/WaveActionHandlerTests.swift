import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct WaveActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'wave <item>'")
    func testSyntaxWave() async throws {
        let handler = WaveActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.count == 2 })!
            .parse("wave wand")
        #expect(syntax.verb == .wave)
        #expect(syntax.directObject == .item(id: "wand"))
    }

    @Test("Syntax for 'brandish <item>'")
    func testSyntaxBrandish() async throws {
        let handler = WaveActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.count == 2 })!
            .parse("brandish sword")
        #expect(syntax.verb == .wave)
        #expect(syntax.directObject == .item(id: "sword"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails for unreachable item")
    func testValidationFailsForUnreachableItem() async throws {
        let wand = Item(id: "wand", .name("a wand"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: wand)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("wave wand")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand
            You can’t see any wand here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Waving a generic takable item")
    func testWaveGenericItem() async throws {
        let wand = Item(id: "wand", .name("a magic wand"), .isTakable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wand)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wand")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wand
            You give the magic wand a little wave.
            """)

        let finalWand = try await engine.item("wand")
        #expect(finalWand.hasFlag(.isTouched))
    }

    @Test("Waving a weapon brandishes it")
    func testWaveWeapon() async throws {
        let sword = Item(
            id: "sword", .name("a sharp sword"), .isTakable, .isWeapon, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave sword")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave sword
            You brandish the sharp sword menacingly.
            """)
    }

    @Test("Waving a fixed object fails")
    func testWaveFixedObject() async throws {
        let wall = Item(id: "wall", .name("the wall"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wave wall")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wave wall
            You can’t wave the wall around – it’s not something you
            can pick up and wave.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(WaveActionHandler().actionID == .wave)
    }
}
