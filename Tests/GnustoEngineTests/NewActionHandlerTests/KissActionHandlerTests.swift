import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {
    let handler = KissActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rock: Item!
    var princess: Item!
    var troll: Item!

    @Before
    func setup() {
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        princess = Item(id: "princess", .name("princess"), .isCharacter, .in(.location("room")))
        troll = Item(id: "troll", .name("troll"), .isCharacter, .isFighting, .in(.location("room")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rock, princess, troll]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("KISS <item> syntax works")
    func testKissItemSyntax() async throws {
        try await engine.execute("kiss rock")
        let output = await mockIO.flush()
        // Response is random, so just check that we got some output.
        #expect(!output.isEmpty)
        #expect(output.contains("rock"))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectMissing() async throws {
        try await engine.execute("kiss")
        let output = await mockIO.flush()
        #expect(output.contains("Kiss what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenItemNotReachable() async throws {
        let remoteRock = Item(id: "remoteRock", .name("remote rock"), .in(.location("otherRoom")))
        var blueprint = game.gameBlueprint
        blueprint.locations.append(Location(id: "otherRoom", .name("Other Room")))
        blueprint.items.append(remoteRock)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("kiss remote rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    @Test("Requires light to kiss")
    func testRequiresLight() async throws {
        let darkRoom = Location(id: "darkRoom", .name("Dark Room"))
        let darkRock = Item(id: "darkRock", .name("unseen rock"), .in(.location("darkRoom")))
        let blueprint = MinimalGame(
            player: Player(in: "darkRoom"), locations: [darkRoom], items: [darkRock])
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("kiss unseen rock")
        let output = await mockIO.flush()
        #expect(output.contains("It is pitch black. You can't see a thing."))
    }

    // MARK: - Processing Testing

    @Test("Kissing self has a unique response")
    func testProcessKissSelf() async throws {
        try await engine.execute("kiss self")
        let output = await mockIO.flush()
        #expect(output.contains("You kiss yourself"))
    }

    @Test("Kissing a friendly character has a unique response")
    func testProcessKissCharacter() async throws {
        try await engine.execute("kiss princess")
        let output = await mockIO.flush()
        #expect(output.contains("princess"))
    }

    @Test("Kissing an enemy character has a unique response")
    func testProcessKissEnemy() async throws {
        try await engine.execute("kiss troll")
        let output = await mockIO.flush()
        #expect(output.contains("You can't kiss the troll while it's attacking you!"))
    }

    @Test("Kissing an item touches it")
    func testProcessKissTouchesItem() async throws {
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("kiss rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("KISS action resolves to KissActionHandler")
    func testKissActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("kiss rock")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is KissActionHandler)
    }
}
