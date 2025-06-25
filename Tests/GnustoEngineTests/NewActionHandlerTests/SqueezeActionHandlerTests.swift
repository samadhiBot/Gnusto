import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct SqueezeActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule accepts 'squeeze <item>'")
    func testSyntaxRule() async throws {
        let handler = SqueezeActionHandler()
        let syntax = try handler.syntax.primary.parse("squeeze sponge")
        #expect(syntax.verb == .squeeze)
        #expect(syntax.directObject == .item(id: "sponge"))
    }

    @Test("Syntax rule accepts synonym 'compress <item>'")
    func testCompressSyntaxRule() async throws {
        let handler = SqueezeActionHandler()
        let syntax = try handler.syntax.synonyms.first!.parse("compress sponge")
        #expect(syntax.verb == .squeeze)
        #expect(syntax.directObject == .item(id: "sponge"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.execute("squeeze")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze
            Squeeze what?
            """)
    }

    @Test("Validation fails for unreachable item")
    func testValidationFailsForUnreachableItem() async throws {
        let sponge = Item(id: "sponge", .name("a sponge"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("squeeze sponge")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze sponge
            You can’t see any sponge here.
            """)
    }

    @Test("Validation fails in the dark")
    func testValidationFailsInDark() async throws {
        let sponge = Item(id: "sponge", .name("a sponge"), .in(.location("testRoom")))
        let testRoom = Location(id: "testRoom", .name("Test Room"), .items(sponge))
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("squeeze sponge")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > squeeze sponge
            It’s too dark to see.
            """)
    }

    // MARK: - Processing Testing

    @Test("Squeezing a character returns a message")
    func testSqueezingCharacter() async throws {
        let troll = Item(id: "troll", .name("a troll"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: troll)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("squeeze troll")

        let output = await mockIO.flush()
        #expect(!output.isEmpty)
        #expect(output.contains("> squeeze troll"))

        let touched = try await engine.item("troll").hasFlag(.isTouched)
        #expect(touched)
    }

    @Test("Squeezing an item returns a message")
    func testSqueezingItem() async throws {
        let sponge = Item(id: "sponge", .name("a sponge"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: sponge)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("squeeze sponge")

        let output = await mockIO.flush()
        #expect(!output.isEmpty)
        #expect(output.contains("> squeeze sponge"))

        let touched = try await engine.item("sponge").hasFlag(.isTouched)
        #expect(touched)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(SqueezeActionHandler().actionID == .squeeze)
    }
}
