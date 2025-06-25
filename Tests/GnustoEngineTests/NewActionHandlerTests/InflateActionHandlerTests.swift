import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InflateActionHandler Tests")
struct InflateActionHandlerTests {
    let handler = InflateActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var raft: Item!
    var rock: Item!

    @Before
    func setup() {
        raft = Item(
            id: "raft",
            .name("rubber raft"),
            .description("A rubber raft."),
            .isInflatable,
            .in(.location("room"))
        )
        rock = Item(
            id: "rock",
            .name("heavy rock"),
            .description("A heavy rock."),
            .in(.location("room"))
        )

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [raft, rock]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("INFLATE <item> syntax works")
    func testInflateSyntax() async throws {
        try await engine.execute("inflate raft")
        let output = await mockIO.flush()
        #expect(output.contains("You inflate the rubber raft."))
    }

    @Test("BLOW UP <item> synonym works")
    func testBlowUpSynonym() async throws {
        try await engine.execute("blow up raft")
        let output = await mockIO.flush()
        #expect(output.contains("You inflate the rubber raft."))
    }

    @Test("INFLATE <item> WITH <tool> syntax works")
    func testInflateWithToolSyntax() async throws {
        // The tool is just for flavor, no special item is needed
        try await engine.execute("inflate raft with pump")
        let output = await mockIO.flush()
        #expect(output.contains("You inflate the rubber raft."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectIsMissing() async throws {
        try await engine.execute("inflate")
        let output = await mockIO.flush()
        #expect(output.contains("Inflate what?"))
    }

    @Test("Fails when item is not inflatable")
    func testValidationFailsWhenItemNotInflateable() async throws {
        try await engine.execute("inflate rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't inflate the heavy rock."))
    }

    // MARK: - Processing Testing

    @Test("Inflating sets the isInflated flag")
    func testProcessSetsIsInflatedFlag() async throws {
        var raftState = try await engine.item("raft")
        #expect(raftState.hasFlag(.isInflated) == false)

        try await engine.execute("inflate raft")

        raftState = try await engine.item("raft")
        #expect(raftState.hasFlag(.isInflated) == true)
        #expect(raftState.hasFlag(.isTouched) == true)
    }

    @Test("Fails when item is already inflated")
    func testProcessFailsWhenAlreadyInflated() async throws {
        try await engine.update(item: "raft") { $0.setFlag(.isInflated) }

        try await engine.execute("inflate raft")
        let output = await mockIO.flush()
        #expect(output.contains("The rubber raft is already inflated."))
    }

    // MARK: - ActionID Testing

    @Test("INFLATE action resolves to InflateActionHandler")
    func testInflateActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("inflate raft")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is InflateActionHandler)
    }
}
