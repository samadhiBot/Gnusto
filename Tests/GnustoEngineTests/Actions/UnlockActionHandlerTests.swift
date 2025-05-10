import CustomDump
import Testing

@testable import GnustoEngine

@Suite("UnlockActionHandler Tests")
struct UnlockActionHandlerTests {
    @Test("Unlock item successfully")
    func testUnlockItemSuccessfully() async throws {
        // Arrange: Key held, box reachable and locked
        let initialBox = Item(
            id: "box",
            name: "wooden box",
            .in(.location("startRoom")),
            .isContainer,
            .isLockable,
            .isLocked,
            .isOpenable,
            .lockKey("key"),
        )
        let initialKey = Item(
            id: "key",
            name: "small key",
            .in(.player), // Key is held
            .isTakable,
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
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == true)
        let initialKeySnapshot = try #require(await engine.item("key"))

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "unlock",
            directObject: "box",
            indirectObject: "key",
            rawInput: "unlock box with key"
        )

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is now unlocked.")

        // Assert Final State
        let finalBoxState = try #require(await engine.item("box"))
        #expect(finalBoxState.hasFlag(.isLocked) == false, "Box should be unlocked")
        #expect(finalBoxState.hasFlag(.isTouched) == true, "Box should be touched")

        let finalKeyState = try #require(await engine.item("key"))
        #expect(finalKeyState.hasFlag(.isTouched) == true, "Key should be touched")

        // Assert Change History
        let expectedChanges = expectedUnlockChanges(
            targetItemID: "box",
            keyItemID: "key",
            initialTargetLocked: initialBoxSnapshot.hasFlag(.isLocked),
            initialTargetTouched: initialBoxSnapshot.hasFlag(.isTouched),
            initialKeyTouched: initialKeySnapshot.hasFlag(.isTouched)
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Unlock fails with no direct object")
    func testUnlockFailsNoDirectObject() async throws {
        // Arrange: Player holds key
        let key = Item(
            id: "key",
            name: "key",
            .in(.player),
            .isTakable,
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

        let command = Command(verbID: "unlock", indirectObject: "key", rawInput: "unlock with key") // No direct object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Unlock what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails with no indirect object")
    func testUnlockFailsNoIndirectObject() async throws {
        // Arrange: Box is reachable and locked
        let box = Item(
            id: "box",
            name: "box",
            .in(.location("startRoom")),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key"),
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

        let command = Command(verbID: "unlock", directObject: "box", rawInput: "unlock box") // No indirect object

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Unlock it with what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when key not held")
    func testUnlockFailsKeyNotHeld() async throws {
        // Arrange: Key is in the room, not held; box is locked
        let box = Item(
            id: "box",
            name: "box",
            .in(.location("startRoom")),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key"),
        )
        let key = Item(
            id: "key",
            name: "key",
            .in(.location("startRoom")),
            .isTakable,
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

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the key.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when target not reachable")
    func testUnlockFailsTargetNotReachable() async throws {
        // Arrange: Box is locked in another room, player holds key
        let box = Item(
            id: "box",
            name: "box",
            .in(.location("otherRoom")),
            .isContainer,
            .isLockable,
            .isLocked,
            .lockKey("key"),
        )
        let key = Item(
            id: "key",
            name: "key",
            .in(.player),
            .isTakable,
        )
        let room1 = Location(
            id: "startRoom",
            name: "Start",
            .inherentlyLit
        ) // Correct parameter name
        let room2 = Location(
            id: "otherRoom",
            name: "Other",
            .inherentlyLit
        ) // Correct parameter name
        let game = MinimalGame(locations: [room1, room2], items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when target not lockable/unlockable")
    func testUnlockFailsTargetNotUnlockable() async throws {
        // Arrange: Target lacks .lockable, player holds key
        let pebble = Item(
            id: "pebble",
            name: "pebble",
            .in(.location("startRoom"))
        ) // Not lockable
        let key = Item(
            id: "key",
            name: "key",
            .in(.player),
            .isTakable,
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

        let command = Command(verbID: "unlock", directObject: "pebble", indirectObject: "key", rawInput: "unlock pebble with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't unlock the pebble.") // Uses ActionError.itemNotUnlockable message

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails with wrong key")
    func testUnlockFailsWrongKey() async throws {
        // Arrange: Box locked, requires 'key', player holds 'wrongkey'
        let box = Item(
            id: "box",
            name: "box",
            .in(.location("startRoom")),
            .lockKey("key"),
            .isContainer,
            .isLockable,
            .isLocked
        )
        let wrongKey = Item(
            id: "wrongkey",
            name: "bent key",
            .in(.player), // Player holds this
            .isTakable,
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

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "wrongkey", rawInput: "unlock box with bent key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The bent key doesn't fit the box.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Unlock fails when already unlocked")
    func testUnlockFailsAlreadyUnlocked() async throws {
        // Arrange: Box is already unlocked, player holds key
        let box = Item(
            id: "box",
            name: "box",
            .in(.location("startRoom")),
            .isContainer,
            .isLockable, // Start unlocked
            .lockKey("key"),
        )
        let key = Item(
            id: "key",
            name: "key",
            .in(.player),
            .isTakable,
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
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == false)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The box is already unlocked.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}

extension UnlockActionHandlerTests {
    private func expectedUnlockChanges(
        targetItemID: ItemID,
        keyItemID: ItemID,
        initialTargetLocked: Bool,
        initialTargetTouched: Bool,
        initialKeyTouched: Bool
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Target change: Unlock (if it was locked)
        if initialTargetLocked {
            changes.append(
                StateChange(
                    entityID: .item(targetItemID),
                    attributeKey: .itemAttribute(.isLocked),
                    oldValue: true,
                    newValue: false
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
                attributeKey: .pronounReference(pronoun: "them"),
                oldValue: nil, // Assuming previous 'it' is irrelevant for this action
                newValue: .itemIDSet([keyItemID, targetItemID]) // Both key and target are relevant
            )
        )

        return changes
    }
}
