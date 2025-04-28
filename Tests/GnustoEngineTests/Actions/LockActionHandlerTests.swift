import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("LockActionHandler Tests")
struct LockActionHandlerTests {

    // --- Test Setup ---
    let box = Item(
        id: "box",
        name: "wooden box",
        properties: .container, .openable, .lockable, // Lockable, initially unlocked
        lockKey: "key"
    )

    let key = Item(
        id: "key",
        name: "small key",
        properties: .takable
    )

    // --- Helper ---
    private func expectedLockChanges(
        targetItemID: ItemID,
        keyItemID: ItemID,
        oldTargetProps: Set<ItemProperty>,
        oldKeyProps: Set<ItemProperty>
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Target changes: Add .locked and .touched
        var newTargetProps = oldTargetProps
        newTargetProps.insert(.locked)
        newTargetProps.insert(.touched)
        if oldTargetProps != newTargetProps {
            changes.append(StateChange(
                entityId: .item(targetItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldTargetProps),
                newValue: .itemProperties(newTargetProps)
            ))
        }

        // Key changes: Add .touched (if needed)
        if !oldKeyProps.contains(.touched) {
            var newKeyProps = oldKeyProps
            newKeyProps.insert(.touched)
            changes.append(StateChange(
                entityId: .item(keyItemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldKeyProps),
                newValue: .itemProperties(newKeyProps)
            ))
        }

        return changes
    }

    // --- Tests ---

    @Test("Lock item successfully")
    func testLockItemSuccessfully() async throws {
        // Arrange: Key held, box reachable and unlocked
        let initialBox = Item( // Use copies to track initial state
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .lockable,
            parent: .location("startRoom"),
            lockKey: "key"
        )
        let initialKey = Item(
            id: "key",
            name: "small key",
            properties: .takable,
            parent: .player // Key is held
        )
        let initialBoxProps = initialBox.properties
        let initialKeyProps = initialKey.properties

        let game = MinimalGame(items: [initialBox, initialKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Check initial state
        guard let initialBoxSnapshot = engine.itemSnapshot(with: "box") else {
            Issue.record("Initial box snapshot was nil")
            return // Exit test if setup failed
        }
        #expect(initialBoxSnapshot.hasProperty(.locked) == false)

        guard let initialKeySnapshot = engine.itemSnapshot(with: "key") else {
            Issue.record("Initial key snapshot was nil")
            return // Exit test if setup failed
        }
        #expect(initialKeySnapshot.parent == .player)

        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", indirectObject: "key", rawInput: "lock box with key")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is now locked.")

        // Assert Final State
        guard let finalBoxState = engine.itemSnapshot(with: "box") else {
            Issue.record("Final box snapshot was nil")
            return // Exit test if check failed
        }
        #expect(finalBoxState.hasProperty(.locked) == true, "Box should be locked")
        #expect(finalBoxState.hasProperty(.touched) == true, "Box should be touched")

        guard let finalKeyState = engine.itemSnapshot(with: "key") else {
            Issue.record("Final key snapshot was nil")
            return // Exit test if check failed
        }
        #expect(finalKeyState.hasProperty(.touched) == true, "Key should be touched")

        // Assert Change History
        let expectedChanges = expectedLockChanges(
            targetItemID: "box",
            keyItemID: "key",
            oldTargetProps: initialBoxProps,
            oldKeyProps: initialKeyProps
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Lock fails with no direct object")
    func testLockFailsNoDirectObject() async throws {
        // Arrange: Player holds key
        let key = Item(id: "key", name: "key", parent: .player)
        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", indirectObject: "key", rawInput: "lock with key") // No direct object

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output (Error message from validation reported by engine)
        let output = await mockIO.flush()
        expectNoDifference(output, "Lock what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails with no indirect object")
    func testLockFailsNoIndirectObject() async throws {
        // Arrange: Box is reachable
        let box = Item(id: "box", name: "box", parent: .location("startRoom"))
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", rawInput: "lock box") // No indirect object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Lock it with what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when key not held")
    func testLockFailsKeyNotHeld() async throws {
        // Arrange: Key is in the room, not held
        let box = Item(id: "box", name: "box", parent: .location("startRoom"))
        let key = Item(id: "key", name: "key", parent: .location("startRoom")) // Key also in room
        let game = MinimalGame(items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", indirectObject: "key", rawInput: "lock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the key.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when target not reachable")
    func testLockFailsTargetNotReachable() async throws {
        // Arrange: Box is in another room, player holds key
        let box = Item(id: "box", name: "box", parent: .location("otherRoom"))
        let key = Item(id: "key", name: "key", parent: .player)
        let room1 = Location(id: "startRoom", name: "Start", properties: .inherentlyLit)
        let room2 = Location(id: "otherRoom", name: "Other")
        let game = MinimalGame(locations: [room1, room2], items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", indirectObject: "key", rawInput: "lock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You don't see the box here.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when target not lockable")
    func testLockFailsTargetNotLockable() async throws {
        // Arrange: Target is not lockable, player holds key
        let pebble = Item(id: "pebble", name: "pebble", parent: .location("startRoom")) // Not lockable
        let key = Item(id: "key", name: "key", parent: .player)
        let game = MinimalGame(items: [pebble, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "pebble", indirectObject: "key", rawInput: "lock pebble with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't lock the pebble.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails with wrong key")
    func testLockFailsWrongKey() async throws {
        // Arrange: Player holds wrong key, box requires 'key'
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .lockable,
            parent: .location("startRoom"),
            lockKey: "key"
        )
        let wrongKey = Item(
            id: "wrongkey",
            name: "bent key",
            properties: .takable,
            parent: .player // Player holds this
        )
        let game = MinimalGame(items: [box, wrongKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", indirectObject: "wrongkey", rawInput: "lock box with bent key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The bent key doesn't fit the box.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when already locked")
    func testLockFailsAlreadyLocked() async throws {
        // Arrange: Box is already locked, player holds key
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .lockable, .locked, // Start locked
            parent: .location("startRoom"),
            lockKey: "key"
        )
        let key = Item(id: "key", name: "key", parent: .player)
        let game = MinimalGame(items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        guard let initialBoxSnapshot = engine.itemSnapshot(with: "box") else {
            Issue.record("Initial box snapshot was nil")
            return
        }
        #expect(initialBoxSnapshot.hasProperty(.locked) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "lock", directObject: "box", indirectObject: "key", rawInput: "lock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The box is already locked.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
