import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RubActionHandler Tests")
struct RubActionHandlerTests {
    let handler = RubActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var troll: Item!
    var lamp: Item!
    var coin: Item!
    var wall: Item!

    @Before
    func setup() {
        troll = Item(id: "troll", .name("troll"), .isCharacter, .in(.location("room")))
        lamp = Item(id: "lamp", .name("brass lamp"), .isLightSource, .in(.location("room")))
        coin = Item(id: "coin", .name("gold coin"), .isTakable, .in(.location("room")))
        wall = Item(id: "wall", .name("stone wall"), .in(.location("room")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"), .inherentlyLit)],
            items: [troll, lamp, coin, wall]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("RUB <item> syntax works")
    func testRubSyntax() async throws {
        try await engine.execute("rub coin")
        let output = await mockIO.flush()
        #expect(output.contains("You rub the gold coin. It feels smooth to the touch."))
    }

    @Test("POLISH <item> synonym works")
    func testPolishSyntax() async throws {
        let polishVerb = Verb(id: .rub, synonyms: ["rub", "polish"])
        let customVocabulary = Vocabulary(verbs: [polishVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("polish coin")
        let output = await mockIO.flush()
        #expect(output.contains("You rub the gold coin. It feels smooth to the touch."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("rub")
        let output = await mockIO.flush()
        #expect(output.contains("Rub what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "coin") { $0.parent = .location("otherRoom") }
        try await engine.execute("rub coin")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Rubbing a character has a unique response")
    func testProcessRubCharacter() async throws {
        try await engine.execute("rub troll")
        let output = await mockIO.flush()
        #expect(output.contains("I don’t think the troll would appreciate being rubbed."))
    }

    @Test("Rubbing a light source has a unique response")
    func testProcessRubLightSource() async throws {
        try await engine.execute("rub lamp")
        let output = await mockIO.flush()
        #expect(
            output.contains("Rubbing the brass lamp doesn’t seem to do anything. No djinn appears.")
        )
    }

    @Test("Rubbing a generic takable item has a unique response")
    func testProcessRubTakable() async throws {
        try await engine.execute("rub coin")
        let output = await mockIO.flush()
        #expect(output.contains("You rub the gold coin. It feels smooth to the touch."))
    }

    @Test("Rubbing a generic non-takable item has a unique response")
    func testProcessRubGeneric() async throws {
        try await engine.execute("rub wall")
        let output = await mockIO.flush()
        #expect(output.contains("You rub the stone wall, but nothing interesting happens."))
    }

    @Test("Rubbing an item touches it")
    func testProcessRubTouchesItem() async throws {
        try await engine.update(item: "coin") { $0.clearFlag(.isTouched) }
        var coinState = try await engine.item("coin")
        #expect(coinState.hasFlag(.isTouched) == false)

        try await engine.execute("rub coin")

        coinState = try await engine.item("coin")
        #expect(coinState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("RUB action resolves to RubActionHandler")
    func testRubActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("rub coin")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is RubActionHandler)
    }
}
