import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("UnlockActionHandler Tests")
struct UnlockActionHandlerTests {

    // --- Test Setup ---
    let box = Item(
        id: "box",
        name: "wooden box",
        properties: .container, .openable, .lockable, // Base properties
        lockKey: "key"
    )

    let key = Item(
        id: "key",
        name: "small key",
        properties: .takable
    )

    // --- Helper ---
    private func expectedUnlockChanges(
        targetItemID: ItemID,
        keyItemID: ItemID,
        oldTargetProps: Set<ItemProperty>,
        oldKeyProps: Set<ItemProperty>
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Target changes: Remove .locked, add .touched
        var newTargetProps = oldTargetProps
        newTargetProps.remove(.locked)
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

    @Test("Unlock item successfully")
    func testUnlockItemSuccessfully() async throws {
        // Arrange: Key held, box reachable and locked
        let initialBox = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .lockable, .locked, // Start locked
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
            return
        }
        #expect(initialBoxSnapshot.hasProperty(.locked) == true)

        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is now unlocked.")

        // Assert Final State
        guard let finalBoxState = engine.itemSnapshot(with: "box") else {
            Issue.record("Final box snapshot was nil")
            return
        }
        #expect(finalBoxState.hasProperty(.locked) == false, "Box should be unlocked")
        #expect(finalBoxState.hasProperty(.touched) == true, "Box should be touched")

        guard let finalKeyState = engine.itemSnapshot(with: "key") else {
            Issue.record("Final key snapshot was nil")
            return
        }
        #expect(finalKeyState.hasProperty(.touched) == true, "Key should be touched")

        // Assert Change History
        let expectedChanges = expectedUnlockChanges(
            targetItemID: "box",
            keyItemID: "key",
            oldTargetProps: initialBoxProps,
            oldKeyProps: initialKeyProps
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Unlock fails with no direct object")
    func testUnlockFailsNoDirectObject() async throws {
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

        let command = Command(verbID: "unlock", indirectObject: "key", rawInput: "unlock with key") // No direct object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Unlock what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails with no indirect object")
    func testUnlockFailsNoIndirectObject() async throws {
        // Arrange: Box is reachable and locked
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .lockable, .locked,
            parent: .location("startRoom"),
            lockKey: "key"
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", rawInput: "unlock box") // No indirect object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Unlock it with what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when key not held")
    func testUnlockFailsKeyNotHeld() async throws {
        // Arrange: Key is in the room, not held; box is locked
        let box = Item(
            id: "box", name: "box", properties: .container, .lockable, .locked,
            parent: .location("startRoom"), lockKey: "key"
        )
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

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the key.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when target not reachable")
    func testUnlockFailsTargetNotReachable() async throws {
        // Arrange: Box is locked in another room, player holds key
        let box = Item(
            id: "box", name: "box", properties: .container, .lockable, .locked,
            parent: .location("otherRoom"), lockKey: "key"
        )
        let key = Item(id: "key", name: "key", parent: .player)
        let room1 = Location(id: "startRoom", name: "Start", properties: .inherentlyLit)
        let room2 = Location(id: "otherRoom", name: "Other", properties: .inherentlyLit) // Both rooms lit
        let game = MinimalGame(locations: [room1, room2], items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when target not lockable/unlockable")
    func testUnlockFailsTargetNotUnlockable() async throws {
        // Arrange: Target lacks .lockable, player holds key
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

        let command = Command(verbID: "unlock", directObject: "pebble", indirectObject: "key", rawInput: "unlock pebble with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't unlock the pebble.") // Uses ActionError.itemNotUnlockable message

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails with wrong key")
    func testUnlockFailsWrongKey() async throws {
        // Arrange: Box locked, requires 'key', player holds 'wrongkey'
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .lockable, .locked,
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

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "wrongkey", rawInput: "unlock box with bent key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The bent key doesn't fit the box.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when already unlocked")
    func testUnlockFailsAlreadyUnlocked() async throws {
        // Arrange: Box is already unlocked, player holds key
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .lockable, // Start unlocked
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
        #expect(initialBoxSnapshot.hasProperty(.locked) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The box is already unlocked.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
