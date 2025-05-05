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
        properties: .container, .openable,
        attributes: [.isOpen: true]
    )

    // --- Helper ---
    private func expectedInsertChanges(
        itemToInsertID: ItemID,
        containerID: ItemID,
        initialParent: ParentEntity,
        initialItemTouched: Bool,
        initialContainerTouched: Bool
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: Item parent
        changes.append(StateChange(
            entityId: .item(itemToInsertID),
            propertyKey: .itemParent,
            oldValue: .parentEntity(initialParent),
            newValue: .parentEntity(.item(containerID))
        ))

        // Change 2: Item touched (if needed)
        if !initialItemTouched {
            changes.append(StateChange(
                entityId: .item(itemToInsertID),
                propertyKey: .itemAttribute(.isTouched),
                oldValue: .bool(false),
                newValue: .bool(true)
            ))
        }

        // Change 3: Container touched (if needed)
        if !initialContainerTouched {
            changes.append(StateChange(
                entityId: .item(containerID),
                propertyKey: .itemAttribute(.isTouched),
                oldValue: .bool(false),
                newValue: .bool(true)
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
            parent: .player,
            isTakable: true
        )
        let initialBox = Item(
            id: "openBox", name: "open box",
            parent: .location("startRoom"),
            attributes: [.isOpen: .bool(true)],
            isContainer: true,
            isOpenable: true
        )
        let initialParent = initialCoin.parent
        let initialItemTouched = initialCoin.hasFlag(PropertyID.isTouched)
        let initialContainerTouched = initialBox.hasFlag(PropertyID.isTouched)

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
        let finalCoinState = try #require(await engine.item("coin"))
        #expect(finalCoinState.parent == .item("openBox"), "Coin should be in the box")
        #expect(finalCoinState.hasFlag(PropertyID.isTouched) == true, "Coin should be touched")

        let finalBoxState = try #require(await engine.item("openBox"))
        #expect(finalBoxState.hasFlag(PropertyID.isTouched) == true, "Box should be touched")

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Change History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "openBox",
            initialParent: initialParent,
            initialItemTouched: initialItemTouched,
            initialContainerTouched: initialContainerTouched
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Insert fails with no direct object")
    func testInsertFailsNoDirectObject() async throws {
        // Arrange: Open box is reachable
        let box = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [.isOpen: .bool(true)],
            isContainer: true
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
            parent: .player,
            isTakable: true
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
            parent: .location("startRoom"),
            isTakable: true
        )
        let box = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [.isOpen: .bool(true)],
            isContainer: true
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
            properties: .container,
            attributes: [.isOpen: true],
            parent: .location("otherRoom"),
        )
        let room1 = Location(
            id: "startRoom",
            name: "Start",
            isLit: true
        )
        let room2 = Location(
            id: "otherRoom",
            name: "Other",
            isLit: true
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
            properties: .container,
            attributes: [.isOpen: true],
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
            properties: .container,
            attributes: [.isOpen: true],
            parent: .player
        )
        let box = Item(
            id: "box",
            name: "box",
            properties: .container,
            attributes: [.isOpen: true],
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
            properties: .container, .openable,
            attributes: [.isOpen: true],
            capacity: 10,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [coin, box, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInside = engine.items(in: .item("fullBox"))
        let initialLoad = itemsInside.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 6)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "fullBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The nearly full box is full.") // ActionError.containerIsFull

        // Assert No State Change
        #expect(engine.item("coin")?.parent == .player) // Coin still held
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
            properties: .container, .openable,
            attributes: [.isOpen: true],
            capacity: 10,
            parent: .location("startRoom"),
        )
        let initialCoinProps = initialCoin.properties
        let initialBoxProps = initialBox.properties

        let game = MinimalGame(items: [initialCoin, initialBox, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInsideInitial = engine.items(in: .item("exactBox"))
        let initialLoad = itemsInsideInitial.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 5)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "exactBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the gold coin in the half-full box.") // Success message

        // Assert Final State
        #expect(engine.item("coin")?.parent == .item("exactBox")) // Coin is in box
        // Final state check - Calculate manually
        let itemsInsideFinal = engine.items(in: .item("exactBox"))
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

    @Test("Insert into reachable container successfully")
    func testInsertIntoReachableContainerSuccessfully() async throws {
        // Arrange: Player holds key, box is in the room
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true // Starts open
            ]
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true) // Assuming lit for test

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the small key in the wooden box.")

        // Assert Final State
        let finalItemState = try #require(await engine.item("key"))
        #expect(finalItemState.parent == .item("box"))
        let finalContainerState = try #require(await engine.item("box"))
        #expect(finalContainerState.hasFlag(PropertyID.isTouched) == true)

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Change History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "key",
            containerID: "box",
            initialParent: .player,
            initialItemTouched: false,
            initialContainerTouched: false
        )
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Insert into self not allowed")
    func testInsertIntoSelfNotAllowed() async throws {
        // Arrange: Player holds open container
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .player,
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true
            ]
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [container])
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

    @Test("Insert into item not in reach")
    func testInsertIntoItemNotInReach() async throws {
        // Arrange: Player holds key, container is in another room
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("otherRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true
            ]
        )
        let room1 = Location(id: "startRoom", name: "Start Room", isLit: true)
        let room2 = Location(id: "otherRoom", name: "Other Room", isLit: true)

        let game = MinimalGame(locations: [room1, room2], items: [itemToInsert, container])
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert into target not a container")
    func testInsertIntoTargetNotAContainer() async throws {
        // Arrange: Target is a rock (not a container)
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let target = Item(id: "rock", name: "smooth rock", parent: .location("startRoom"))
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, target])
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "rock", preposition: "in", rawInput: "put key in rock")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things in the rock.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert into closed container")
    func testInsertIntoClosedContainer() async throws {
        // Arrange: Container is closed
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true
                // Closed by default
            ]
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is closed.")

        // Assert No State Change
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert into container that is full")
    func testInsertIntoContainerThatIsFull() async throws {
        // Arrange: Container has capacity 1, already contains an item
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let existingItem = Item(id: "gem", name: "shiny gem", parent: .item("box"), size: 1)
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 1 // Set capacity
            ]
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, existingItem, container])
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is full.") // ActionError.containerIsFull

        // Assert No State Change
        #expect(engine.item("key")?.parent == .player) // Key still held
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert item too large for container")
    func testInsertItemTooLargeForContainer() async throws {
        // Arrange: Item size is 5, container capacity is 3
        let itemToInsert = Item(id: "key", name: "large key", parent: .player, size: 5)
        let container = Item(
            id: "box",
            name: "small box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 3 // Set capacity
            ]
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The small box is too small for the large key.") // ActionError.itemTooLargeForContainer

        // Assert No State Change
        #expect(engine.item("key")?.parent == .player) // Key still held
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    // TODO: Add capacity check test when implemented
}
