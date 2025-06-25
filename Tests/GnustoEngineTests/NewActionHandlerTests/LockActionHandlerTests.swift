import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LockActionHandler Tests")
struct LockActionHandlerTests {
    let handler = LockActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var chest: Item!
    var key: Item!
    var wrongKey: Item!

    @Before
    func setup() {
        chest = Item(
            id: "chest",
            .name("wooden chest"),
            .in(.location("room")),
            .isContainer,
            .isLockable,
            .lockKey("key")
        )
        key = Item(id: "key", .name("small key"), .in(.player))
        wrongKey = Item(id: "wrongKey", .name("bent key"), .in(.player))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [chest, key, wrongKey]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("LOCK <item> WITH <key> syntax works")
    func testLockWithSyntax() async throws {
        try await engine.execute("lock chest with key")
        let output = await mockIO.flush()
        #expect(output.contains("The wooden chest is now locked."))
    }

    // MARK: - Validation Testing

    @Test("Fails when key is missing")
    func testValidationFailsWhenKeyIsMissing() async throws {
        try await engine.execute("lock chest")
        let output = await mockIO.flush()
        #expect(output.contains("Lock the wooden chest with what?"))
    }

    @Test("Fails when key is not held")
    func testValidationFailsWhenKeyNotHeld() async throws {
        try await engine.update(item: "key") { $0.parent = .location("room") }
        try await engine.execute("lock chest with key")
        let output = await mockIO.flush()
        #expect(output.contains("You aren't holding the small key."))
    }

    @Test("Fails when target is not lockable")
    func testValidationFailsWhenNotLockable() async throws {
        let rock = Item(id: "rock", .name("rock"), .in(.location("room")))
        var blueprint = game.gameBlueprint
        blueprint.items.append(rock)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("lock rock with key")
        let output = await mockIO.flush()
        #expect(output.contains("You can't lock the rock."))
    }

    @Test("Fails with wrong key")
    func testValidationFailsWithWrongKey() async throws {
        try await engine.execute("lock chest with wrongKey")
        let output = await mockIO.flush()
        #expect(output.contains("The bent key doesn't fit the lock."))
    }

    // MARK: - Processing Testing

    @Test("Successfully locks an item")
    func testProcessLocksItem() async throws {
        var chestState = try await engine.item("chest")
        #expect(chestState.hasFlag(.isLocked) == false)

        try await engine.execute("lock chest with key")

        chestState = try await engine.item("chest")
        #expect(chestState.hasFlag(.isLocked) == true)
    }

    @Test("Reports when item is already locked")
    func testProcessReportsAlreadyLocked() async throws {
        try await engine.update(item: "chest") { $0.setFlag(.isLocked) }

        try await engine.execute("lock chest with key")
        let output = await mockIO.flush()
        #expect(output.contains("The wooden chest is already locked."))
    }

    @Test("Touches both items on success")
    func testProcessTouchesBothItems() async throws {
        try await engine.update(item: "chest") { $0.clearFlag(.isTouched) }
        try await engine.update(item: "key") { $0.clearFlag(.isTouched) }

        var chestState = try await engine.item("chest")
        var keyState = try await engine.item("key")
        #expect(chestState.hasFlag(.isTouched) == false)
        #expect(keyState.hasFlag(.isTouched) == false)

        try await engine.execute("lock chest with key")

        chestState = try await engine.item("chest")
        keyState = try await engine.item("key")
        #expect(chestState.hasFlag(.isTouched) == true)
        #expect(keyState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("LOCK action resolves to LockActionHandler")
    func testLockActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("lock chest with key")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is LockActionHandler)
    }
}
