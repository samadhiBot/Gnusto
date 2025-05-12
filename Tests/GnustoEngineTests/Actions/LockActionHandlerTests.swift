import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LockActionHandler Tests")
struct LockActionHandlerTests {
    @Test("Lock item successfully")
    func testLockItemSuccessfully() async throws {
        // Arrange: Key held, box reachable and unlocked
        let initialBox = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .lockKey("key"),
            .isContainer,
            .isLockable,
            .isOpenable
        )
        let initialKey = Item(
            id: "key",
            .name("small key"),
            .in(.player), // Key is held
            .isTakable
        )

        let game = MinimalGame(items: [initialBox, initialKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Check initial state
        let initialBoxSnapshot = try #require(await engine.item("box"))
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == false) // Qualified
        let initialKeySnapshot = try #require(await engine.item("key"))

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            indirectObject: "key",
            rawInput: "lock box with key"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is now locked.")

        // Assert Final State
        let finalBoxState = try #require(await engine.item("box"))
        #expect(finalBoxState.hasFlag(.isLocked), "Box should be locked")
        #expect(finalBoxState.hasFlag(.isTouched), "Box should be touched")

        let finalKeyState = try #require(await engine.item("key"))
        #expect(finalKeyState.hasFlag(.isTouched), "Key should be touched")

        // Assert Change History
        let expectedChanges = expectedLockChanges(
            targetItemID: "box",
            keyItemID: "key",
            initialTargetLocked: initialBoxSnapshot.hasFlag(.isLocked),
            initialTargetTouched: initialBoxSnapshot.hasFlag(.isTouched),
            initialKeyTouched: initialKeySnapshot.hasFlag(.isTouched)
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Lock fails with no direct object")
    func testLockFailsNoDirectObject() async throws {
        // Arrange: Player holds key
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            indirectObject: "key",
            rawInput: "lock with key"
        ) // No direct object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Lock what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails with no indirect object")
    func testLockFailsNoIndirectObject() async throws {
        // Arrange: Box is reachable and unlocked
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .lockKey("key"),
            .isContainer,
            .isLockable
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            rawInput: "lock box"
        ) // No indirect object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Lock it with what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when key not held")
    func testLockFailsKeyNotHeld() async throws {
        // Arrange: Key is in the room, not held; box is unlocked
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .lockKey("key"),
            .isContainer,
            .isLockable
        )
        let key = Item(
            id: "key",
            .name("key"),
            .in(.location(.startRoom)), // Key also in room
            .isTakable
        )
        let game = MinimalGame(items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            indirectObject: "key",
            rawInput: "lock box with key"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the key.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when target not reachable")
    func testLockFailsTargetNotReachable() async throws {
        // Arrange: Box is unlocked in another room, player holds key
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location("otherRoom")),
            .lockKey("key"),
            .isContainer,
            .isLockable
        )
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )
        let room1 = Location(
            id: .startRoom,
            .name("Start"),
            .inherentlyLit
        )
        let room2 = Location(
            id: "otherRoom",
            .name("Other"),
            .inherentlyLit
        )
        let game = MinimalGame(locations: [room1, room2], items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            indirectObject: "key",
            rawInput: "lock box with key"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when target not lockable")
    func testLockFailsTargetNotLockable() async throws {
        // Arrange: Target lacks .lockable, player holds key
        let pebble = Item(
            id: "pebble",
            .in(.location(.startRoom))
        ) // Not lockable
        let key = Item(
            id: "key",
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [pebble, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "pebble",
            indirectObject: "key",
            rawInput: "lock pebble with key"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't lock the pebble.") // Uses ActionResponse.itemNotLockable message

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails with wrong key")
    func testLockFailsWrongKey() async throws {
        // Arrange: Box unlocked, requires 'key', player holds 'wrongkey'
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .lockKey("key"),
            .isContainer,
            .isLockable
        )
        let wrongKey = Item(
            id: "wrongkey",
            .name("bent key"),
            .in(.player), // Player holds this
            .isTakable
        )
        let game = MinimalGame(items: [box, wrongKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            indirectObject: "wrongkey",
            rawInput: "lock box with bent key"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The bent key doesn't fit the box.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Lock fails when already locked")
    func testLockFailsAlreadyLocked() async throws {
        // Arrange: Box is already locked, player holds key
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .lockKey("key"),
            .isContainer,
            .isLockable,
            .isLocked // Start locked
        )
        let key = Item(
            id: "key",
            .name("key"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialBoxSnapshot = try #require(await engine.item("box"))
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == true) // Qualified
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: .lock,
            directObject: "box",
            indirectObject: "key",
            rawInput: "lock box with key"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The box is already locked.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}

extension LockActionHandlerTests {
    private func expectedLockChanges(
        targetItemID: ItemID,
        keyItemID: ItemID,
        initialTargetLocked: Bool,
        initialTargetTouched: Bool,
        initialKeyTouched: Bool
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Target change: Lock (if it wasn't locked)
        if !initialTargetLocked {
            changes.append(
                StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isLocked),
                    oldValue: false,
                    newValue: true,
                )
            )
        }

        // Target change: Touch (if not already touched)
        if !initialTargetTouched {
            changes.append(
                StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: nil,
                    newValue: true,
                )
            )
        }

        // Key change: Touch (if not already touched)
        if !initialKeyTouched {
            changes.append(
                StateChange(
                    entityID: .item(keyItemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: nil,
                    newValue: true,
                )
            )
        }

        // Add pronoun change
        changes.append(
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([targetItemID])
            )
        )

        return changes
    }
}
