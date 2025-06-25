import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct UnlockActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'unlock <item> with <key>'")
    func testSyntaxUnlockWith() async throws {
        let handler = UnlockActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.with)) })!
            .parse("unlock chest with key")
        #expect(syntax.verb == .unlock)
        #expect(syntax.directObject == .item(id: "chest"))
        #expect(syntax.indirectObject == .item(id: "key"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a key")
    func testValidationFailsWithoutKey() async throws {
        let chest = Item(
            id: "chest", .name("the chest"), .isLockable, .isLocked, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: chest)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("unlock chest")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest
            Unlock the chest with what?
            """)
    }

    @Test("Validation fails with wrong key")
    func testValidationFailsWithWrongKey() async throws {
        let chest = Item(
            id: "chest", .name("the chest"), .isLockable, .isLocked, .lockKey("rightKey"),
            .in(.location("testRoom")))
        let wrongKey = Item(id: "wrongKey", .name("a key"), .in(.player))
        let game = MinimalGame.lit(items: chest, wrongKey)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("unlock chest with key")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest with key
            The key doesn’t fit the chest.
            """)
    }

    @Test("Validation fails if already unlocked")
    func testValidationFailsIfAlreadyUnlocked() async throws {
        let chest = Item(
            id: "chest", .name("the chest"), .isLockable, .lockKey("key"),
            .in(.location("testRoom")))
        let key = Item(id: "key", .name("a key"), .in(.player))
        let game = MinimalGame.lit(items: chest, key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("unlock chest with key")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest with key
            The chest is already unlocked.
            """)
    }

    // MARK: - Processing Testing

    @Test("Unlocking an item")
    func testUnlockItem() async throws {
        let chest = Item(
            id: "chest", .name("the chest"), .isLockable, .isLocked, .lockKey("key"),
            .in(.location("testRoom")))
        let key = Item(id: "key", .name("a key"), .in(.player))
        let game = MinimalGame.lit(items: chest, key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("unlock chest with key")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > unlock chest with key
            The chest is now unlocked.
            """)

        let finalChest = try await engine.item("chest")
        #expect(!finalChest.hasFlag(.isLocked))
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(UnlockActionHandler().actionID == .unlock)
    }
}
