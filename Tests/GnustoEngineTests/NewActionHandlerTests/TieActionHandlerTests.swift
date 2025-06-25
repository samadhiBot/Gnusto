import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TieActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'tie <item>'")
    func testSyntaxTie() async throws {
        let handler = TieActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.count == 2 })!
            .parse("tie rope")
        #expect(syntax.verb == .tie)
        #expect(syntax.directObject == .item(id: "rope"))
    }

    @Test("Syntax for 'tie <item> to <target>'")
    func testSyntaxTieTo() async throws {
        let handler = TieActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.to)) })!
            .parse("tie rope to post")
        #expect(syntax.verb == .tie)
        #expect(syntax.directObject == .item(id: "rope"))
        #expect(syntax.indirectObject == .item(id: "post"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("tie")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie
            Tie what?
            """)
    }

    @Test("Validation fails if item is not reachable")
    func testValidationFailsIfUnreachable() async throws {
        let rope = Item(id: "rope", .name("a rope"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("tie rope")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope
            You can’t see any rope here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Tying a rope creates a knot")
    func testTieRope() async throws {
        let rope = Item(id: "rope", .name("the rope"), .isRope, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tie rope")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope
            You tie a knot in the rope.
            """)
    }

    @Test("Tying a non-rope item fails")
    func testTieNonRope() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tie rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rock
            You would need something to tie the rock with.
            """)
    }

    @Test("Tying an item to itself fails")
    func testTieToSelf() async throws {
        let rope = Item(id: "rope", .name("the rope"), .isRope, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tie rope to rope")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rope to rope
            You can’t tie the rope to itself.
            """)
    }

    @Test("Tying to an object fails without a rope")
    func testTieToOtherWithoutRope() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let post = Item(id: "post", .name("a post"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock, post)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tie rock to post")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tie rock to post
            You would need something to tie the rock with.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TieActionHandler().actionID == .tie)
    }
}
