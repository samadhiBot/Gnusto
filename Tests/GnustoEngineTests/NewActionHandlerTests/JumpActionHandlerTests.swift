import CustomDump
import Testing

@testable import GnustoEngine

@Suite("JumpActionHandler Tests")
struct JumpActionHandlerTests {
    let handler = JumpActionHandler()
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

    @Test("JUMP syntax works")
    func testJumpSyntax() async throws {
        try await engine.execute("jump")
        let output = await mockIO.flush()
        // Response is random, so just check that we got some output.
        #expect(!output.isEmpty)
    }

    @Test("JUMP <item> syntax works")
    func testJumpItemSyntax() async throws {
        try await engine.execute("jump rock")
        let output = await mockIO.flush()
        #expect(output.contains("You jump on the heavy rock, but nothing happens."))
    }

    @Test("LEAP OVER <item> synonym works")
    func testLeapOverSyntax() async throws {
        try await engine.execute("leap over rock")
        let output = await mockIO.flush()
        #expect(output.contains("You jump on the heavy rock, but nothing happens."))
    }

    // MARK: - Validation Testing

    @Test("Fails when jumping on an unreachable item")
    func testValidationFailsOnUnreachableItem() async throws {
        let remoteRock = Item(id: "remoteRock", .name("remote rock"), .in(.location("otherRoom")))
        var blueprint = game.gameBlueprint
        blueprint.locations.append(Location(id: "otherRoom", .name("Other Room")))
        blueprint.items.append(remoteRock)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("jump remote rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Jumping provides a random response")
    func testProcessJumpRandomResponse() async throws {
        // This is tricky to test for randomness, but we can check it's one of the known responses.
        try await engine.execute("jump")
        let output = await mockIO.flush()
        let possibleResponses = [
            "You jump on the spot.",
            "Whee!",
            "You jump, but nothing much happens.",
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let cleanedOutput =
            output.split(separator: "\n").last?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        #expect(possibleResponses.contains(String(cleanedOutput)))
    }

    @Test("Jumping on a character provides a specific response")
    func testProcessJumpCharacter() async throws {
        try await engine.execute("jump troll")
        let output = await mockIO.flush()
        #expect(output.contains("A valiant effort, but you can't jump the troll."))
    }

    @Test("Jumping on an item touches it")
    func testProcessJumpTouchesItem() async throws {
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("jump rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("JUMP action resolves to JumpActionHandler")
    func testJumpActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("jump")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is JumpActionHandler)
    }
}
