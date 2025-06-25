import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct WearActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'wear <item>'")
    func testSyntaxWear() async throws {
        let handler = WearActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.wear)) })!
            .parse("wear cloak")
        #expect(syntax.verb == .wear)
        #expect(syntax.directObjects.first == .item(id: "cloak"))
    }

    @Test("Syntax for 'put on <item>'")
    func testSyntaxPutOn() async throws {
        let handler = WearActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.put)) })!
            .parse("put on cloak")
        #expect(syntax.verb == .wear)
        #expect(syntax.directObjects.first == .item(id: "cloak"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails if item not held")
    func testValidationFailsIfNotHeld() async throws {
        let cloak = Item(id: "cloak", .name("a cloak"), .isWearable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: cloak)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("wear cloak")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear cloak
            You aren’t holding the cloak.
            """)
    }

    @Test("Validation fails if not wearable")
    func testValidationFailsIfNotWearable() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.player))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("wear rock")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear rock
            You can’t wear the rock.
            """)
    }

    // MARK: - Processing Testing

    @Test("Wearing an item")
    func testWearItem() async throws {
        let cloak = Item(id: "cloak", .name("a cloak"), .isWearable, .in(.player))
        let game = MinimalGame.lit(items: cloak)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear cloak")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear cloak
            You put on the cloak.
            """)

        let finalCloak = try await engine.item("cloak")
        #expect(finalCloak.hasFlag(.isWorn))
    }

    @Test("Wear all")
    func testWearAll() async throws {
        let cloak = Item(id: "cloak", .name("a cloak"), .isWearable, .in(.player))
        let hat = Item(id: "hat", .name("a hat"), .isWearable, .in(.player))
        let rock = Item(id: "rock", .name("a rock"), .in(.player))
        let game = MinimalGame.lit(items: cloak, hat, rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("wear all")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > wear all
            You put on the cloak and the hat.
            """)

        let finalCloak = try await engine.item("cloak")
        let finalHat = try await engine.item("hat")
        let finalRock = try await engine.item("rock")
        #expect(finalCloak.hasFlag(.isWorn))
        #expect(finalHat.hasFlag(.isWorn))
        #expect(!finalRock.hasFlag(.isWorn))
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(WearActionHandler().actionID == .wear)
    }
}
