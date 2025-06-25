import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TurnOffActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'turn off <item>'")
    func testSyntaxTurnOff() async throws {
        let handler = TurnOffActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.turn)) })!
            .parse("turn off lamp")
        #expect(syntax.verb == .extinguish)
        #expect(syntax.directObject == .item(id: "lamp"))
    }

    @Test("Syntax for 'extinguish <item>'")
    func testSyntaxExtinguish() async throws {
        let handler = TurnOffActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern == [.verb, .directObject] })!
            .parse("extinguish lamp")
        #expect(syntax.verb == .extinguish)
        #expect(syntax.directObject == .item(id: "lamp"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails if item is not a device")
    func testValidationFailsIfNotDevice() async throws {
        let rock = Item(id: "rock", .name("a rock"), .isOn, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn off rock")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off rock
            You can’t turn that off.
            """)
    }

    @Test("Validation fails if item is already off")
    func testValidationFailsIfAlreadyOff() async throws {
        let lamp = Item(id: "lamp", .name("a lamp"), .isDevice, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn off lamp")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            It’s already off.
            """)
    }

    // MARK: - Processing Testing

    @Test("Turning off a device")
    func testTurnOffDevice() async throws {
        let lamp = Item(id: "lamp", .name("the lamp"), .isDevice, .isOn, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn off lamp")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The lamp is now off.
            """)

        let finalLamp = try await engine.item("lamp")
        #expect(!finalLamp.hasFlag(.isOn))
    }

    @Test("Turning off light source plunges room into darkness")
    func testTurnOffCausesDarkness() async throws {
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let lamp = Item(
            id: "lamp", .name("the lamp"), .isDevice, .isLightSource, .isOn,
            .in(.location("darkRoom")))
        let game = MinimalGame(player: Player(in: "darkRoom"), locations: darkRoom, items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn off lamp")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn off lamp
            The lamp is now off.
            You are plunged into darkness.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TurnOffActionHandler().actionID == .extinguish)
    }
}
