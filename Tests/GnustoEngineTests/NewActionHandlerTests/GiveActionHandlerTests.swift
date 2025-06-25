import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GiveActionHandler Tests")
struct GiveActionHandlerTests {
    let handler = GiveActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        let troll = Item(
            id: "troll",
            .name("troll"),
            .description("A menacing troll."),
            .isCharacter,
            .in(.location("room"))
        )
        let remoteTroll = Item(
            id: "remoteTroll",
            .name("remote troll"),
            .isCharacter,
            .in(.location("otherRoom"))
        )
        let lamp = Item(id: "lamp", .name("brass lantern"), .in(.player))
        let book = Item(id: "book", .name("book"), .in(.player))
        let box = Item(id: "box", .name("box"), .in(.location("room")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [
                Location(id: "room", .name("Room")),
                Location(id: "otherRoom", .name("Other Room")),
            ],
            items: [troll, remoteTroll, lamp, book, box]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("GIVE <direct> TO <indirect> syntax works")
    func testGiveDirectToIndirectSyntax() async throws {
        try await engine.execute("give lamp to troll")
        let output = await mockIO.flush()
        #expect(output.contains("The troll now has the brass lantern."))
    }

    @Test("GIVE <indirect> <direct> syntax works")
    func testGiveIndirectDirectSyntax() async throws {
        try await engine.execute("give troll the lamp")
        let output = await mockIO.flush()
        #expect(output.contains("The troll now has the brass lantern."))
    }

    @Test("OFFER synonym works")
    func testOfferSyntax() async throws {
        try await engine.execute("offer lamp to troll")
        let output = await mockIO.flush()
        #expect(output.contains("The troll now has the brass lantern."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWithMissingDirectObject() async throws {
        try await engine.execute("give to troll")
        let output = await mockIO.flush()
        #expect(output.contains("Give what?"))
    }

    @Test("Fails when indirect object is missing")
    func testValidationFailsWithMissingIndirectObject() async throws {
        try await engine.execute("give lamp")
        let output = await mockIO.flush()
        #expect(output.contains("Give it to whom?"))
    }

    @Test("Fails when player does not have the item")
    func testValidationFailsWhenPlayerDoesNotHaveItem() async throws {
        try await engine.execute("give box to troll")
        let output = await mockIO.flush()
        #expect(output.contains("You don't have that."))
    }

    @Test("Fails when recipient is not a character")
    func testValidationFailsWhenRecipientNotACharacter() async throws {
        try await engine.execute("give lamp to box")
        let output = await mockIO.flush()
        #expect(output.contains("That's not something you can give things to."))
    }

    @Test("Fails when recipient is not reachable")
    func testValidationFailsWhenRecipientNotReachable() async throws {
        try await engine.execute("give lamp to remote troll")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any remote troll here."))
    }

    // MARK: - Processing Testing

    @Test("Giving item moves it to recipient's inventory")
    func testProcessMovesItemToRecipient() async throws {
        try await engine.execute("give lamp to troll")

        let lamp = try await engine.item("lamp")
        #expect(lamp.parent == .item("troll"))

        let troll = try await engine.item("troll")
        let trollContents = await engine.items(in: .item(troll.id))
        #expect(trollContents.map(\.id).contains("lamp"))
    }

    @Test("Giving multiple items with 'all'")
    func testProcessGiveAll() async throws {
        try await engine.execute("give all to troll")
        let output = await mockIO.flush()
        #expect(output.contains("The troll now has the brass lantern and the book."))

        let lamp = try await engine.item("lamp")
        #expect(lamp.parent == .item("troll"))

        let book = try await engine.item("book")
        #expect(book.parent == .item("troll"))
    }

    @Test("'Give all' gives nothing if player has nothing to give")
    func testProcessGiveAllWithNothingToGive() async throws {
        // Drop everything first
        try await engine.execute("drop all")
        await mockIO.flush()  // Clear output

        try await engine.execute("give all to troll")
        let output = await mockIO.flush()
        #expect(output.contains("You have nothing to give."))
    }

    // MARK: - ActionID Testing

    @Test("GIVE action resolves to GiveActionHandler")
    func testGiveActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("give lamp to troll")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is GiveActionHandler)
    }
}
