import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {
    let handler = InsertActionHandler()

    // --- Test Setup ---
    let coin = Item(
        id: "coin",
        name: "gold coin",
        attributes: [.isTakable: true,]
    )

    let box = Item(
        id: "box",
        name: "wooden box",
        attributes: [
            .isContainer: true,
            .isOpenable: true,
        ]
    )

    let openBox = Item(
        id: "openBox",
        name: "open box",
        attributes: [
            .isContainer: true,
            .isOpenable: true,
            .isOpen: true,
        ]
    )

    // --- Tests ---

    @Test("Insert item successfully")
    func testInsertItemSuccessfully() async throws {
        // Arrange: Player holds coin, open box is reachable
        let initialCoin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [
                .isTakable: true,
            ]
        )
        let initialBox = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [
                .isOpen: true,
                .isContainer: true,
                .isOpenable: true,
            ]
        )
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialBox.attributes

        let game = MinimalGame(items: [initialCoin, initialBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "openBox", preposition: "in", rawInput: "put coin in open box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the gold coin in the open box.")

        // Assert Final State
        let finalCoinState = try #require(await engine.item("coin"))
        #expect(finalCoinState.parent == .item("openBox"), "Coin should be in the box")
        #expect(finalCoinState.attributes[.isTouched] == true, "Coin should be touched")

        let finalBoxState = try #require(await engine.item("openBox"))
        #expect(finalBoxState.attributes[.isTouched] == true, "Box should be touched")

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == ["coin"])

        // Assert Change History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "openBox",
            initialParent: initialParent,
            initialItemAttributes: initialItemAttributes,
            initialContainerAttributes: initialContainerAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Insert fails with no direct object")
    func testInsertFailsNoDirectObject() async throws {
        // Arrange: Open box is reachable
        let box = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [
                .isOpen: true,
                .isContainer: true,
            ],
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

        let command = Command(verbID: "insert", indirectObject: "openBox", preposition: "in", rawInput: "put in open box") // No DO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Insert what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails with no indirect object")
    func testInsertFailsNoIndirectObject() async throws {
        // Arrange: Player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [.isTakable: true,]
        )
        let game = MinimalGame(items: [coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", preposition: "in", rawInput: "put coin in") // No IO

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Where do you want to insert the gold coin?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when item not held")
    func testInsertFailsItemNotHeld() async throws {
        // Arrange: Coin is in the room, not held; box is open
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .location("startRoom"),
            attributes: [.isTakable: true,]
        )
        let box = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [.isOpen: true, .isContainer: true, .isOpenable: true,]
        )
        let game = MinimalGame(items: [coin, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "openBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the gold coin.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when target not reachable")
    func testInsertFailsTargetNotReachable() async throws {
        // Arrange: Box is in another room, player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [.isTakable: true,]
        )
        let box = Item(
            id: "distantBox",
            name: "distant box",
            parent: .nowhere,
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ]
        )
        let game = MinimalGame(items: [coin, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "distantBox", preposition: "in", rawInput: "put coin in distant box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when target not a container")
    func testInsertFailsTargetNotContainer() async throws {
        // Arrange: Player holds coin, target is statue (not container)
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [.isTakable: true,]
        )
        let statue = Item(
            id: "statue",
            name: "stone statue",
            parent: .location("startRoom"),
            attributes: [
                .isOpenable: false
            ]
        )
        let game = MinimalGame(items: [coin, statue])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "statue", preposition: "in", rawInput: "put coin in statue")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things in the stone statue.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when container closed")
    func testInsertFailsContainerClosed() async throws {
        // Arrange: Box is closed, player holds coin
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
        )
        let box = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
            ],
        ) // Closed
        let game = MinimalGame(items: [coin, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "box", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is closed.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails self-insertion")
    func testInsertFailsSelfInsertion() async throws {
        // Arrange: Player holds box
        let box = Item(
            id: "box",
            name: "box",
            parent: .player,
            attributes: [.isOpen: true,],
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

        let command = Command(verbID: "insert", directObject: "box", indirectObject: "box", preposition: "in", rawInput: "put box in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails recursive insertion")
    func testInsertFailsRecursiveInsertion() async throws {
        // Arrange: Player holds bag, bag contains box
        let bag = Item(
            id: "bag",
            name: "bag",
            parent: .player,
            attributes: [
                .isContainer: true,
                .isOpen: true,
            ],
        )
        let box = Item(
            id: "box",
            name: "box",
            parent: .item("bag"),
            attributes: [
                .isContainer: true,
                .isOpen: true,
            ],
        )
        let game = MinimalGame(items: [bag, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        // Try to put the bag into the box (which is inside the bag)
        let command = Command(verbID: "insert", directObject: "bag", indirectObject: "box", preposition: "in", rawInput: "put bag in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put the box inside the bag like that.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert fails when container is full")
    func testInsertFailsContainerFull() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 but already contains item size 6
        let coin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [
                .size: 5
            ]
        )
        let existingItem = Item(
            id: "rock",
            name: "rock",
            parent: .item("fullBox"),
            attributes: [
                .size: 6,
            ]
        )
        let box = Item(
            id: "fullBox",
            name: "nearly full box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 10,
            ]
        )
        let game = MinimalGame(items: [coin, box, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInside = await engine.items(in: .item("fullBox"))
        let initialLoad = itemsInside.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 6)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "fullBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The gold coin won't fit in the nearly full box.")

        // Assert No State Change
        #expect(await engine.item("coin")?.parent == .player) // Coin still held
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert succeeds when container has exact space")
    func testInsertSucceedsContainerExactSpace() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 and contains item size 5
        let initialCoin = Item(
            id: "coin",
            name: "gold coin",
            parent: .player,
            attributes: [
                .size: 5
            ]
        )
        let existingItem = Item(
            id: "rock",
            name: "rock",
            parent: .item("exactBox"),
            attributes: [
                .size: 5
            ]
        )
        let initialBox = Item(
            id: "exactBox",
            name: "half-full box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 10,
            ]
        )
        let initialCoinAttributes = initialCoin.attributes
        let initialBoxAttributes = initialBox.attributes

        let game = MinimalGame(items: [initialCoin, initialBox, existingItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        // Initial state check - Calculate manually
        let itemsInsideInitial = await engine.items(in: .item("exactBox"))
        let initialLoad = itemsInsideInitial.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 5)

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "exactBox", preposition: "in", rawInput: "put coin in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the gold coin in the half-full box.") // Success message

        // Assert Final State
        #expect(await engine.item("coin")?.parent == .item("exactBox")) // Coin is in box
                                                                  // Final state check - Calculate manually
        let itemsInsideFinal = await engine.items(in: .item("exactBox"))
        let finalLoad = itemsInsideFinal.reduce(0) { $0 + $1.size }
        #expect(finalLoad == 10) // Box is now full

        // Assert Change History (should include parent change, touched flags, pronoun)
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "exactBox",
            initialParent: .player,
            initialItemAttributes: initialCoinAttributes,
            initialContainerAttributes: initialBoxAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
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
            ],
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true) // Assuming lit for test

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

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
        #expect(finalContainerState.hasFlag(.isTouched) == true)

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == ["key"])

        // Assert Change History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "key",
            containerID: "box",
            initialParent: .player,
            initialItemAttributes: [:],
            initialContainerAttributes: [:])
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
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
            ],
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "box", indirectObject: "box", preposition: "in", rawInput: "put box in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
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
            ],
        )
        let room1 = Location(id: "startRoom", name: "Start Room", isLit: true)
        let room2 = Location(id: "otherRoom", name: "Other Room", isLit: true)

        let game = MinimalGame(locations: [room1, room2], items: [itemToInsert, container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert into target not a container")
    func testInsertIntoTargetNotAContainer() async throws {
        // Arrange: Target is a rock (not a container)
        let itemToInsert = Item(id: "key", name: "small key", parent: .player)
        let target = Item(
            id: "rock",
            name: "smooth rock",
            parent: .location("startRoom")
        )
        let room = Location(
            id: "startRoom",
            name: "Room",
            isLit: true
        )

        let game = MinimalGame(locations: [room], items: [itemToInsert, target])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "rock", preposition: "in", rawInput: "put key in rock")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things in the smooth rock.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
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
                .isOpenable: true,
            ],
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is closed.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert into container that is full")
    func testInsertIntoContainerThatIsFull() async throws {
        // Arrange: Container has capacity 1, already contains an item
        let itemToInsert = Item(
            id: "key",
            name: "small key",
            parent: .player
        )
        let existingItem = Item(
            id: "gem",
            name: "shiny gem",
            parent: .item("box"),
            attributes: [
                .size: 1
            ]
        )
        let container = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 1
            ],
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(
            locations: [room],
            items: [itemToInsert, existingItem, container]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "insert",
            directObject: "key",
            indirectObject: "box",
            preposition: "in",
            rawInput: "put key in box"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The small key won't fit in the wooden box.")

        // Assert No State Change
        #expect(await engine.item("key")?.parent == .player) // Key still held
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Insert item too large for container")
    func testInsertItemTooLargeForContainer() async throws {
        // Arrange: Item size is 5, container capacity is 3
        let itemToInsert = Item(
            id: "key",
            name: "large key",
            parent: .player,
            attributes: [
                .size: 5
            ]
        )
        let container = Item(
            id: "box",
            name: "small box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 3
            ],
        )
        let room = Location(id: "startRoom", name: "Room", isLit: true)

        let game = MinimalGame(locations: [room], items: [itemToInsert, container])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)

        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "key", indirectObject: "box", preposition: "in", rawInput: "put key in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The large key won't fit in the small box.")

        // Assert No State Change
        #expect(await engine.item("key")?.parent == .player) // Key still held
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    // Helper to setup game state for nested container tests
    private func setupNestedContainerTest() async -> (GameEngine, MockIOHandler) {
        let outerBox = Item(
            id: "outerBox", name: "large box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let innerBox = Item(
            id: "innerBox", name: "small box",
            parent: .item("outerBox"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let coin = Item(
            id: "coin", name: "shiny coin",
            parent: .player,
            attributes: [.isTakable: true,]
        )

        let game = MinimalGame(items: [outerBox, innerBox, coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        return (engine, mockIO)
    }

    @Test("Insert into nested container (outer box)")
    func testInsertIntoNestedOuter() async throws {
        // Arrange
        let (engine, mockIO) = await setupNestedContainerTest()
        let initialCoin = try #require(await engine.item("coin"))
        let initialOuterBox = try #require(await engine.item("outerBox"))
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialOuterBox.attributes

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "outerBox", preposition: "in", rawInput: "put coin in large box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the shiny coin in the large box.")

        // Assert State
        let finalCoin = try #require(await engine.item("coin"))
        #expect(finalCoin.parent == .item("outerBox"))

        // Assert History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "outerBox",
            initialParent: initialParent,
            initialItemAttributes: initialItemAttributes,
            initialContainerAttributes: initialContainerAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Insert into nested container (inner box)")
    func testInsertIntoNestedInner() async throws {
        // Arrange
        let (engine, mockIO) = await setupNestedContainerTest()
        let initialCoin = try #require(await engine.item("coin"))
        let initialInnerBox = try #require(await engine.item("innerBox"))
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialInnerBox.attributes

        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "innerBox", preposition: "in", rawInput: "put coin in small box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put the shiny coin in the small box.")

        // Assert State
        let finalCoin = try #require(await engine.item("coin"))
        #expect(finalCoin.parent == .item("innerBox"))

        // Assert History
        let expectedChanges = expectedInsertChanges(
            itemToInsertID: "coin",
            containerID: "innerBox",
            initialParent: initialParent,
            initialItemAttributes: initialItemAttributes,
            initialContainerAttributes: initialContainerAttributes
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Insert into itself fails")
    func testInsertIntoSelfFails() async throws {
        // Arrange: Player holds a bag (which is a container)
        let bag = Item(
            id: "bag", name: "cloth bag",
            parent: .player,
            attributes: [
                .isTakable: true,
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let game = MinimalGame(items: [bag])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO) // Initialize engine
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "bag", indirectObject: "bag", preposition: "in", rawInput: "put bag in bag")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true) // Use engine instance
    }

    @Test("Insert into nested container that contains itself indirectly (A in B, put B in A)")
    func testInsertIntoIndirectSelfContainer() async throws {
        // Arrange: Box A contains Box B. Player holds Box B. Try putting B into A.
        let boxA = Item(
            id: "boxA",
            name: "box A",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let boxB = Item(
            id: "boxB",
            name: "box B",
            parent: .item("boxA"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .isTakable: true,
            ],
        )

        let game = MinimalGame(items: [boxA, boxB])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO) // Initialize engine

        // Player needs to take Box B first
        await engine.execute(command: Command(verbID: "take", directObject: "boxB", rawInput: "take box B"))
        _ = await mockIO.flush() // Discard take output
        #expect(await engine.item("boxB")?.parent == .player)

        let command = Command(verbID: "insert", directObject: "boxB", indirectObject: "boxA", preposition: "in", rawInput: "put box B in box A")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush() // Initialize mockIO
        expectNoDifference(output, "You can't put the box B inside the box A, because the box A is inside the box B!") // Zorkian message

        // Assert No State Change (other than taking the box)
        let history = await engine.gameState.changeHistory // Use engine instance
        #expect(history.count > 0) // Take action happened
        #expect(history.last?.attributeKey != .itemParent) // Insert action did not happen
    }

    @Test("Insert into deeply nested container that contains itself indirectly")
    func testInsertIntoDeepIndirectSelfContainer() async throws {
        // Arrange: A contains B, B contains C. Player holds C. Try putting C into A.
        let boxA = Item(
            id: "boxA",
            name: "box A",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let boxB = Item(
            id: "boxB",
            name: "box B",
            parent: .item("boxA"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let boxC = Item(
            id: "boxC",
            name: "box C",
            parent: .item("boxB"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .isTakable: true,
            ],
        )

        let game = MinimalGame(items: [boxA, boxB, boxC])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO) // Initialize engine

        // Player needs to take Box C first (requires opening A and B)
        await engine.execute(command: Command(verbID: "take", directObject: "boxC", rawInput: "take box C"))
        _ = await mockIO.flush() // Discard take output
        #expect(await engine.item("boxC")?.parent == .player)

        let command = Command(verbID: "insert", directObject: "boxC", indirectObject: "boxA", preposition: "in", rawInput: "put box C in box A")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush() // Initialize mockIO
        expectNoDifference(output, "You can't put the box C inside the box A, because the box A is inside the box C!") // Zorkian message

        // Assert No State Change (other than taking the box)
        let history = await engine.gameState.changeHistory // Use engine instance
        #expect(history.count > 0) // Take action happened
        #expect(history.last?.attributeKey != .itemParent || history.last?.entityID != .item("boxC")) // Insert action did not happen for boxC
    }

    // --- Validation Tests (using handler.validate for focused error checks) ---

    @Test("Validation fails when item not held")
    func testValidationItemNotHeld() async throws {
        // Arrange: Coin is in the room, not held; box is open
        let coin = Item(
            id: "coin", name: "gold coin", parent: .location("startRoom"),
            attributes: [.isTakable: true,]
        )
        let box = Item(
            id: "openBox", name: "open box", parent: .location("startRoom"),
            attributes: [.isOpen: true, .isContainer: true, .isOpenable: true,]
        )
        let game = MinimalGame(items: [coin, box])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "openBox", preposition: "in", rawInput: "put coin in box")

        // Act & Assert Error
        await #expect(throws: ActionError.itemNotHeld("coin")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when target not reachable")
    func testValidationTargetNotReachable() async throws {
        // Arrange: Box is nowhere, player holds coin
        let coin = Item(
            id: "coin", name: "gold coin", parent: .player,
            attributes: [.isTakable: true,]
        )
        let box = Item(
            id: "distantBox", name: "distant box", parent: .nowhere,
            attributes: [.isContainer: true, .isOpenable: true, .isOpen: true,]
        )
        let game = MinimalGame(items: [coin, box])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "distantBox", preposition: "in", rawInput: "put coin in distant box")

        // Act & Assert Error
        await #expect(throws: ActionError.itemNotAccessible("distantBox")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when target not a container")
    func testValidationTargetNotContainer() async throws {
        // Arrange: Target is a statue (not a container)
        let coin = Item(
            id: "coin", name: "gold coin", parent: .player,
            attributes: [.isTakable: true,]
        )
        let statue = Item(
            id: "statue", name: "stone statue", parent: .location("startRoom"),
        )
        let game = MinimalGame(items: [coin, statue])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(
            verbID: "insert",
            directObject: "coin",
            indirectObject: "statue",
            preposition: "in",
            rawInput: "put coin in statue"
        )

        // Act & Assert Error
        await #expect(throws: ActionError.targetIsNotAContainer("statue")) {
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when target is closed")
    func testValidationTargetClosed() async throws {
        // Arrange: Box is closed
        let coin = Item(
            id: "coin", name: "gold coin", parent: .player,
            attributes: [.isTakable: true,]
        )
        let box = Item(
            id: "closedBox", name: "closed box", parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
            ]
        )
        let game = MinimalGame(items: [coin, box])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(verbID: "insert", directObject: "coin", indirectObject: "closedBox", preposition: "in", rawInput: "put coin in closed box")

        // Act & Assert Error
        await #expect(throws: ActionError.containerIsClosed("closedBox")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when item is too large for container")
    func testValidationItemTooLarge() async throws {
        // Arrange: Boulder is size 10, box capacity is 5
        let boulder = Item(
            id: "boulder", name: "huge boulder", parent: .player,
            attributes: [.isTakable: true, .size: 10]
        )
        let box = Item(
            id: "box", name: "small box", parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .capacity: 5
            ]
        )
        let game = MinimalGame(items: [boulder, box])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(verbID: "insert", directObject: "boulder", indirectObject: "box", preposition: "in", rawInput: "put boulder in box")

        // Act & Assert Error
        await #expect(throws: ActionError.itemTooLargeForContainer(item: "boulder", container: "box")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when inserting into self")
    func testValidationInsertIntoSelf() async throws {
        // Arrange: Player holds a bag (which is a container)
        let bag = Item(
            id: "bag", name: "cloth bag", parent: .player,
            attributes: [
                .isTakable: true,
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ]
        )
        let game = MinimalGame(items: [bag])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine
        let command = Command(verbID: "insert", directObject: "bag", indirectObject: "bag", preposition: "in", rawInput: "put bag in bag")

        // Act & Assert Error
        await #expect(throws: ActionError.customResponse("Putting the cloth bag into itself would be বোকা.")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty) // Use instance engine
    }

    @Test("Validation fails when inserting into indirect self container")
    func testValidationInsertIntoIndirectSelf() async throws {
        // Arrange: A contains B. Player holds B. Try putting B into A.
        let boxA = Item(
            id: "boxA",
            name: "box A",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let boxB = Item(
            id: "boxB",
            name: "box B",
            parent: .item("boxA"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
                .isTakable: true,
            ],
        )

        let game = MinimalGame(items: [boxA, boxB])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler()) // Use instance engine

        // Player needs to take Box B first
        await engine.execute(command: Command(verbID: "take", directObject: "boxB", rawInput: "take box B"))
        _ = await MockIOHandler().flush() // Discard take output (needs own mockIO instance for flush)
        #expect(await engine.item("boxB")?.parent == .player)

        let command = Command(verbID: "insert", directObject: "boxB", indirectObject: "boxA", preposition: "in", rawInput: "put box B in box A")

        // Act & Assert Error
        await #expect(throws: ActionError.customResponse("You can't put the box B inside the box A, because the box A is inside the box B!")) { // Correct error type
            try await handler.validate(
                context: ActionContext(command: command, engine: engine, stateSnapshot: engine.gameState) // Use instance engine
            )
        }
        // Check history, but don't expect it to be empty due to 'take'
        let history = await engine.gameState.changeHistory
        #expect(history.count > 0)
        #expect(history.last?.attributeKey != .itemParent || history.last?.entityID != .item("boxB")) // Insert didn't happen for boxB
    }

    @Test("Insert fails when item is fixed (scenery)")
    func testInsertFailsItemIsFixed() async throws {
        // Arrange: Player holds trophy (scenery), box is open
        let trophy = Item(
            id: "trophy",
            name: "glass trophy",
            parent: .player,
            attributes: [
                .isTakable: true,
                .isFixed: true,
            ]
        )
        let box = Item(
            id: "openBox",
            name: "open box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true,
            ],
        )
        let game = MinimalGame(items: [trophy, box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(game: game, parser: mockParser, ioHandler: mockIO)
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "insert", directObject: "trophy", indirectObject: "box", preposition: "in", rawInput: "put trophy in box")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't put things in the glass trophy.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }
}

extension InsertActionHandlerTests {
    private func expectedInsertChanges(
        itemToInsertID: ItemID,
        containerID: ItemID,
        initialParent: ParentEntity,
        initialItemAttributes: [AttributeID: StateValue],
        initialContainerAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: Item parent
        changes.append(StateChange(
            entityID: .item(itemToInsertID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(initialParent),
            newValue: .parentEntity(.item(containerID))
        ))

        // Change 2: Item touched (if needed)
        if initialItemAttributes[.isTouched] != true {
            changes.append(StateChange(
                entityID: .item(itemToInsertID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: nil,
                newValue: true,
            ))
        }

        // Change 3: Container touched (if needed)
        if initialContainerAttributes[.isTouched] != true {
            changes.append(StateChange(
                entityID: .item(containerID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: nil,
                newValue: true,
            ))
        }

        // Change 4: Pronoun "it"
        changes.append(StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemToInsertID])
        ))

        return changes
    }
}
