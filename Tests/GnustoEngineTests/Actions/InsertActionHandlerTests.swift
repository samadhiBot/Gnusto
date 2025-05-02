import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {

    // --- Test Setup ---
    let coin = Item(
        id: "coin",
        name: "gold coin",
        properties: .takable
    )

    let box = Item(
        id: "box",
        name: "wooden box",
        properties: .container, .openable // Starts closed
    )

    let openBox = Item(
        id: "openBox",
        name: "open box",
        properties: .container, .openable, .open // Starts open
    )

    // --- Helper ---
    private func expectedInsertChanges(
        itemToInsertID: ItemID,
        containerID: ItemID,
        oldItemProps: Set<ItemProperty>,
        oldContainerProps: Set<ItemProperty>
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: Item parent
        changes.append(StateChange(
            entityId: .item(itemToInsertID),
            propertyKey: .itemParent,
            oldValue: .parentEntity(.player),
            newValue: .parentEntity(.item(containerID))
        ))

        // Change 2: Item touched
        if !oldItemProps.contains(.touched) {
            var newItemProps = oldItemProps
            newItemProps.insert(.touched)
            changes.append(StateChange(
                entityId: .item(itemToInsertID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldItemProps),
                newValue: .itemPropertySet(newItemProps)
            ))
        }

        // Change 3: Container touched
        if !oldContainerProps.contains(.touched) {
            var newContainerProps = oldContainerProps
            newContainerProps.insert(.touched)
            changes.append(StateChange(
                entityId: .item(containerID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldContainerProps),
                newValue: .itemPropertySet(newContainerProps)
            ))
        }

        // Change 4: Pronoun "it"
        changes.append(StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemToInsertID])
        ))

        return changes
    }

    // --- Tests ---

    @Test("Insert item successfully")
    func testInsertItemSuccessfully() async throws {
        // Arrange: Player holds coin, open box is reachable
        let initialCoin = Item(
            id: "coin",
            name: "gold coin",
            properties: .takable,
            parent: .player
        )
        let initialBox = Item(
            id: "openBox", name: "open box",
            properties: .container, .openable, .open, // Start open
            parent: .location("startRoom")
        )
        let initialCoinProps = initialCoin.properties
        let initialBoxProps = initialBox.properties

        let game = MinimalGame(items: [initialCoin, initialBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "openBox", preposition: "in", rawInput: "put coin in open box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the gold coin in the open box.")

        // Assert Final State
        guard let finalCoinState = engine.item(with: "coin") else {
            Issue.record("Final coin snapshot was nil")
            return
        }
        #expect(finalCoinState.parent == .item("openBox"), "Coin should be in the box")
        #expect(finalCoinState.hasProperty(.touched) == true, "Coin should be touched")

        guard let finalBoxState = engine.item(with: "openBox") else {
            Issue.record("Final box snapshot was nil")
            return
        }
        #expect(finalBoxState.hasProperty(.touched) == true, "Box should be touched")

        // Assert Pronoun
        #expect(engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Change History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "openBox",
            oldItemProps: initialCoinProps,
            oldContainerProps: initialBoxProps
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Insert fails with no direct object")
    func testInsertFailsNoDirectObject() async throws {
        // Arrange: Open box is reachable
        let box = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .location("startRoom")
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

        let command = Command(verbID: "insert", indirectObject: "openBox", preposition: "in", rawInput: "put in open box") // No DO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Insert what?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails with no indirect object")
    func testInsertFailsNoIndirectObject() async throws {
        // Arrange: Player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player
        )
        let game = MinimalGame(items: [coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", preposition: "in", rawInput: "put coin in") // No IO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Where do you want to insert the gold coin?")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when item not held")
    func testInsertFailsItemNotHeld() async throws {
        // Arrange: Coin is in the room, not held; box is open
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .location("startRoom")
        )
        let box = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [coin, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "openBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the gold coin.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when target not reachable")
    func testInsertFailsTargetNotReachable() async throws {
        // Arrange: Box is in another room, player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player
        )
        let box = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .location("otherRoom")
        )
        let room1 = Location(
            id: "startRoom",
            name: "Start",
            properties: .inherentlyLit
        )
        let room2 = Location(
            id: "otherRoom",
            name: "Other",
            properties: .inherentlyLit
        )
        let game = MinimalGame(
            locations: [room1, room2],
            items: [coin, box]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "insert",
            directObject: "coin",
            indirectObject: "openBox",
            preposition: "in",
            rawInput: "put coin in box"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when target not a container")
    func testInsertFailsTargetNotContainer() async throws {
        // Arrange: Target is a rock (not container), player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player
        )
        let rock = Item(
            id: "rock",
            name: "rock",
            parent: .location("startRoom")
        ) // Not a container
        let game = MinimalGame(items: [coin, rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "rock", preposition: "in", rawInput: "put coin in rock")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things in the rock.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when container closed")
    func testInsertFailsContainerClosed() async throws {
        // Arrange: Box is closed, player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player
        )
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable,
            parent: .location("startRoom")
        ) // Closed
        let game = MinimalGame(items: [coin, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "box", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is closed.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails self-insertion")
    func testInsertFailsSelfInsertion() async throws {
        // Arrange: Player holds box
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .open,
            parent: .player
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

        let command = Command(verbID: "insert", directObject: "box", indirectObject: "box", preposition: "in", rawInput: "put box in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put something in itself.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails recursive insertion")
    func testInsertFailsRecursiveInsertion() async throws {
        // Arrange: Player holds bag, bag contains box
        let bag = Item(
            id: "bag",
            name: "bag",
            properties: .container, .open,
            parent: .player
        )
        let box = Item(
            id: "box",
            name: "box",
            properties: .container, .open,
            parent: .item("bag")
        )
        let game = MinimalGame(items: [bag, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.gameState.changeHistory.isEmpty == true)

        // Try to put the bag into the box (which is inside the bag)
        let command = Command(verbID: "insert", directObject: "bag", indirectObject: "box", preposition: "in", rawInput: "put bag in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put the box inside the bag like that.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when container is full")
    func testInsertFailsContainerFull() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 but already contains item size 6
        let coin = Item(
            id: "coin",
            name: "gold coin",
            size: 5,
            parent: .player
        )
        let existingItem = Item(
            id: "rock",
            name: "rock",
            size: 6,
            parent: .item("fullBox")
        )
        let box = Item(
            id: "fullBox",
            name: "nearly full box",
            properties: .container, .openable, .open, // Open
            capacity: 10,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [coin, box, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInside = engine.items(withParent: .item("fullBox"))
        let initialLoad = itemsInside.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 6)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "fullBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The nearly full box is full.") // ActionError.containerIsFull

        // Assert No State Change
        #expect(engine.item(with: "coin")?.parent == .player) // Coin still held
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert succeeds when container has exact space")
    func testInsertSucceedsContainerExactSpace() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 and contains item size 5
        let initialCoin = Item(
            id: "coin",
            name: "gold coin",
            size: 5,
            parent: .player
        )
        let existingItem = Item(
            id: "rock",
            name: "rock",
            size: 5,
            parent: .item("exactBox")
        )
        let initialBox = Item(
            id: "exactBox",
            name: "half-full box",
            properties: .container, .openable, .open, // Open
            capacity: 10,
            parent: .location("startRoom")
        )
        let initialCoinProps = initialCoin.properties
        let initialBoxProps = initialBox.properties

        let game = MinimalGame(items: [initialCoin, initialBox, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInsideInitial = engine.items(withParent: .item("exactBox"))
        let initialLoad = itemsInsideInitial.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 5)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "exactBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the gold coin in the half-full box.") // Success message

        // Assert Final State
        #expect(engine.item(with: "coin")?.parent == .item("exactBox")) // Coin is in box
        // Final state check - Calculate manually
        let itemsInsideFinal = engine.items(withParent: .item("exactBox"))
        let finalLoad = itemsInsideFinal.reduce(0) { $0 + $1.size }
        #expect(finalLoad == 10) // Box is now full

        // Assert Change History (should include parent change, touched flags, pronoun)
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "exactBox",
            oldItemProps: initialCoinProps,
            oldContainerProps: initialBoxProps
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    // TODO: Add capacity check test when implemented
}
