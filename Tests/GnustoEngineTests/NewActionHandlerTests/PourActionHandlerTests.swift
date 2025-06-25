import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PourActionHandler Tests")
struct PourActionHandlerTests {
    let handler = PourActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var water: Item!
    var plant: Item!

    @Before
    func setup() {
        water = Item(id: "water", .name("quantity of water"), .in(.location("room")))
        plant = Item(id: "plant", .name("potted plant"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [water, plant]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("POUR <item> ON <item> syntax works")
    func testPourOnSyntax() async throws {
        try await engine.execute("pour water on plant")
        let output = await mockIO.flush()
        #expect(output.contains("You pour the quantity of water on the potted plant."))
    }

    @Test("SPILL <item> ON <item> synonym works")
    func testSpillOnSyntax() async throws {
        let spillVerb = Verb(id: .pour, synonyms: ["pour", "spill"])
        let customVocabulary = Vocabulary(verbs: [spillVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("spill water on plant")
        let output = await mockIO.flush()
        #expect(output.contains("You pour the quantity of water on the potted plant."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectMissing() async throws {
        try await engine.execute("pour")
        let output = await mockIO.flush()
        #expect(output.contains("Pour what?"))
    }

    @Test("Fails when indirect object is missing")
    func testValidationFailsWhenIndirectObjectMissing() async throws {
        try await engine.execute("pour water")
        let output = await mockIO.flush()
        #expect(output.contains("Pour the quantity of water on what?"))
    }

    @Test("Fails when pouring an item on itself")
    func testValidationFailsWhenPouringOnSelf() async throws {
        try await engine.execute("pour water on water")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t pour the quantity of water on itself."))
    }

    // MARK: - Processing Testing

    @Test("Pouring touches both items")
    func testProcessPouringTouchesBothItems() async throws {
        try await engine.update(item: "water") { $0.clearFlag(.isTouched) }
        try await engine.update(item: "plant") { $0.clearFlag(.isTouched) }
        var waterState = try await engine.item("water")
        var plantState = try await engine.item("plant")
        #expect(waterState.hasFlag(.isTouched) == false)
        #expect(plantState.hasFlag(.isTouched) == false)

        try await engine.execute("pour water on plant")

        waterState = try await engine.item("water")
        plantState = try await engine.item("plant")
        #expect(waterState.hasFlag(.isTouched) == true)
        #expect(plantState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("POUR action resolves to PourActionHandler")
    func testPourActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("pour water on plant")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is PourActionHandler)
    }
}
