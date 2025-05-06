import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("UnlockActionHandler Tests")
struct UnlockActionHandlerTests {

    // --- Test Setup ---
    // Removed redundant setup, using inline initialization in tests

    // --- Helper ---
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
            changes.append(StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isLocked),
                oldValue: true,
                newValue: false
            ))
        }

        // Target change: Touch (if not already touched)
        if !initialTargetTouched {
            changes.append(StateChange(
                entityID: .item(targetItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true,
            ))
        }

        // Key change: Touch (if not already touched)
        if !initialKeyTouched {
            changes.append(StateChange(
                entityID: .item(keyItemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true,
            ))
        }

        // Add pronoun change
        changes.append(StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: nil, // Assuming previous 'it' is irrelevant for this action
            newValue: .itemIDSet([keyItemID, targetItemID]) // Both key and target are relevant
        ))

        return changes
    }

    // --- Tests ---

    @Test("Unlock item successfully")
    func testUnlockItemSuccessfully() async throws {
        // Arrange: Key held, box reachable and locked
        let initialBox = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .lockKey: "key",
                .isContainer: true,
                .isLockable: true,
                .isLocked: true,
                .isOpenable: true,
            ]
        )
        let initialKey = Item(
            id: "key",
            name: "small key",
            parent: .player, // Key is held
            attributes: [
                .isTakable: true,
            ]
        )

        let game = MinimalGame(items: [initialBox, initialKey])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Check initial state
        let initialBoxSnapshot = try #require(engine.item("box"))
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == true) // Qualified AttributeID
        let initialKeySnapshot = try #require(engine.item("key"))

        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "unlock", directObject: "box", indirectObject: "key", rawInput: "unlock box with key")

        // Act: Use engine.execute
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is now unlocked.")

        // Assert Final State
        let finalBoxState = try #require(engine.item("box"))
        #expect(finalBoxState.hasFlag(.isLocked) == false, "Box should be unlocked") // Qualified AttributeID
        #expect(finalBoxState.hasFlag(.isTouched) == true, "Box should be touched") // Qualified AttributeID

        let finalKeyState = try #require(engine.item("key"))
        #expect(finalKeyState.hasFlag(.isTouched) == true, "Key should be touched") // Qualified AttributeID

        // Assert Change History
        let expectedChanges = expectedUnlockChanges(
            targetItemID: "box",
            keyItemID: "key",
            initialTargetLocked: initialBoxSnapshot.hasFlag(.isLocked), // Qualified AttributeID
            initialTargetTouched: initialBoxSnapshot.hasFlag(.isTouched), // Qualified AttributeID
            initialKeyTouched: initialKeySnapshot.hasFlag(.isTouched) // Qualified AttributeID
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Unlock fails with no direct object")
    func testUnlockFailsNoDirectObject() async throws {
        // Arrange: Player holds key
        let key = Item(
            id: "key",
            name: "key",
            parent: .player,
            attributes: [
                .isTakable: true,
            ]
        )
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
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isLockable: true,
                .isLocked: true,
                .lockKey: "key",
            ]
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
            id: "box",
            name: "box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isLockable: true,
                .isLocked: true,
                .lockKey: "key",
            ]
        )
        let key = Item(
            id: "key",
            name: "key",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true,
            ]
        )
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
    id: "box",
    name: "box",
    parent: .location("otherRoom"),
    attributes: [
        .isContainer: true,
        .isLockable: true,
        .isLocked: true,
        .lockKey: "key",
    ]
)
        let key = Item(
            id: "key",
            name: "key",
            parent: .player,
            attributes: [
                .isTakable: true,
            ]
        )
        let room1 = Location(
            id: "startRoom",
            name: "Start",
            isLit: true
        ) // Correct parameter name
        let room2 = Location(
            id: "otherRoom",
            name: "Other",
            isLit: true
        ) // Correct parameter name
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
        let pebble = Item(
            id: "pebble",
            name: "pebble",
            parent: .location("startRoom")
        ) // Not lockable
        let key = Item(
            id: "key",
            name: "key",
            parent: .player,
            attributes: [
                .isTakable: true,
            ]
        )
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
            parent: .location("startRoom"),
            attributes: [
                .lockKey: "key",
                .isContainer: true,
                .isLockable: true,
                .isLocked: true
            ]
        )
        let wrongKey = Item(
            id: "wrongkey",
            name: "bent key",
            parent: .player, // Player holds this
            attributes: [
                .isTakable: true,
            ]
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
            parent: .location("startRoom"),
            attributes: [
                .lockKey: "key",
                .isContainer: true,
                .isLockable: true // Start unlocked
            ]
        )
        let key = Item(
            id: "key",
            name: "key",
            parent: .player,
            attributes: [
                .isTakable: true,
            ]
        )
        let game = MinimalGame(items: [box, key])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let initialBoxSnapshot = try #require(engine.item("box"))
        #expect(initialBoxSnapshot.hasFlag(.isLocked) == false) // Qualified AttributeID
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
