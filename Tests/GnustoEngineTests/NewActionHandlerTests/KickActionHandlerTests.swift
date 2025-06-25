import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KickActionHandler Tests")
struct KickActionHandlerTests {
    let handler = KickActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rock: Item!
    var troll: Item!

    @Before
    func setup() {
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        troll = Item(id: "troll", .name("troll"), .isCharacter, .in(.location("room")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rock, troll]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("KICK <item> syntax works")
    func testKickSyntax() async throws {
        try await engine.execute("kick rock")
        let output = await mockIO.flush()
        #expect(output.contains("Ouch! You hurt your foot kicking the heavy rock."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectMissing() async throws {
        try await engine.execute("kick")
        let output = await mockIO.flush()
        #expect(output.contains("Kick what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenItemNotReachable() async throws {
        let remoteRock = Item(id: "remoteRock", .name("remote rock"), .in(.location("otherRoom")))
        var blueprint = game.gameBlueprint
        blueprint.locations.append(Location(id: "otherRoom", .name("Other Room")))
        blueprint.items.append(remoteRock)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("kick remote rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    @Test("Requires light to kick")
    func testRequiresLight() async throws {
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let darkRock = Item(id: "darkRock", .name("unseen rock"), .in(.location("darkRoom")))
        let blueprint = MinimalGame(player: Player(in: "darkRoom"), locations: [darkRoom], items: [darkRock])
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("kick unseen rock")
        let output = await mockIO.flush()
        #expect(output.contains("It is pitch black. You can't see a thing."))
    }

    // MARK: - Processing Testing

    @Test("Kicking a character has a unique response")
    func testProcessKickCharacter() async throws {
        try await engine.execute("kick troll")
        let output = await mockIO.flush()
        #expect(output.contains("I don't think the troll would appreciate that."))
    }

    @Test("Kicking an item touches it")
    func testProcessKickTouchesItem() async throws {
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("kick rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("KICK action resolves to KickActionHandler")
    func testKickActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("kick rock")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is KickActionHandler)
    }
}
