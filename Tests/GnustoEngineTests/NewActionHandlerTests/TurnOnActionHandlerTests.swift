import Testing
import CustomDump
@testable import GnustoEngine

@Suite
struct TurnOnActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'turn on <item>'")
    func testSyntaxTurnOn() async throws {
        let handler = TurnOnActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.turn)) })!
            .parse("turn on lamp")
        #expect(syntax.verb == .light)
        #expect(syntax.directObject == .item(id: "lamp"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails if item is not a device or flammable")
    func testValidationFailsIfNotDeviceOrFlammable() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn on rock")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > turn on rock
         You can’t turn that on.
         """)
    }

    @Test("Validation fails if device is already on")
    func testValidationFailsIfAlreadyOn() async throws {
        let lamp = Item(id: "lamp", .name("a lamp"), .isDevice, .isOn, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn on lamp")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > turn on lamp
         It’s already on.
         """)
    }

    // MARK: - Processing Testing

    @Test("Turning on a device")
    func testTurnOnDevice() async throws {
        let lamp = Item(id: "lamp", .name("the lamp"), .isDevice, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on lamp")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > turn on lamp
         The lamp is now on.
         """)

        let finalLamp = try await engine.item("lamp")
        #expect(finalLamp.hasFlag(.isOn))
    }

    @Test("Turning on a flammable item burns it")
    func testTurnOnFlammable() async throws {
        let paper = Item(id: "paper", .name("a piece of paper"), .isFlammable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: paper)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("light paper")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > light paper
         The piece of paper burns to ashes.
         """)

        await #expect(throws: GnustoEngineError.itemNotFound(id: "paper")) {
            _ = try await engine.item("paper")
        }
    }

    @Test("Turning on a light source in a dark room")
    func testTurnOnLightInDark() async throws {
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let lamp = Item(id: "lamp", .name("the lamp"), .isDevice, .isLightSource, .in(.location("darkRoom")))
        let game = MinimalGame(player: Player(in: "darkRoom"), locations: darkRoom, items: lamp)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("turn on lamp")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > turn on lamp
         The lamp is now on.
         You can see your surroundings now.
         """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action IDs")
    func testActionIDs() {
        let handler = TurnOnActionHandler()
        #expect(handler.actions.contains(.lightSource))
        #expect(handler.actions.contains(.burn))
    }
}
