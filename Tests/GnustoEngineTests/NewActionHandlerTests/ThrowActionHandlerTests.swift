import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct ThrowActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'throw <item>'")
    func testSyntaxThrow() async throws {
        let handler = ThrowActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.count == 2 })!
            .parse("throw rock")
        #expect(syntax.verb == .throw)
        #expect(syntax.directObject == .item(id: "rock"))
    }

    @Test("Syntax for 'throw <item> at <target>'")
    func testSyntaxThrowAt() async throws {
        let handler = ThrowActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.at)) })!
            .parse("throw rock at troll")
        #expect(syntax.verb == .throw)
        #expect(syntax.directObject == .item(id: "rock"))
        #expect(syntax.indirectObject == .item(id: "troll"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("throw")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw
            Throw what?
            """)
    }

    @Test("Validation fails if item is not held")
    func testValidationFailsIfNotHeld() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("throw rock")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock
            You aren’t holding the rock.
            """)
    }

    @Test("Validation fails if target is not reachable")
    func testValidationFailsIfTargetUnreachable() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.player))
        let troll = Item(id: "troll", .name("a troll"), .isCharacter, .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: rock, troll)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("throw rock at troll")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock at troll
            You can’t see any troll here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Throwing an item without a target")
    func testThrowItem() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.player))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("throw rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock
            You throw the rock, and it falls to the ground.
            """)

        let finalRock = try await engine.item("rock")
        #expect(finalRock.parent == .location("testRoom"))
    }

    @Test("Throwing an item at an object")
    func testThrowAtObject() async throws {
        let rock = Item(id: "rock", .name("the rock"), .in(.player))
        let wall = Item(id: "wall", .name("the wall"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock, wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("throw rock at wall")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock at wall
            You throw the rock at the wall. It bounces off harmlessly.
            """)
        let finalRock = try await engine.item("rock")
        #expect(finalRock.parent == .location("testRoom"))
    }

    @Test("Throwing an item at a character")
    func testThrowAtCharacter() async throws {
        let rock = Item(id: "rock", .name("the rock"), .in(.player))
        let troll = Item(id: "troll", .name("the troll"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock, troll)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("throw rock at troll")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > throw rock at troll
            You throw the rock at the troll.
            """)
        let finalRock = try await engine.item("rock")
        #expect(finalRock.parent == .location("testRoom"))
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(ThrowActionHandler().actionID == .throwObject)
    }
}
