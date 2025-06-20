import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {
    let handler = InsertActionHandler()

    // — Test Setup —
    let coin = Item(
        id: "coin",
        .name("gold coin"),
        .isTakable
    )

    let box = Item(
        id: "box",
        .name("wooden box"),
        .isContainer,
        .isOpenable,
    )

    let openBox = Item(
        id: "openBox",
        .name("open box"),
        .isContainer,
        .isOpenable,
        .isOpen,
    )

    // — Tests —

    @Test("Insert item successfully")
    func testInsertItemSuccessfully() async throws {
        // Arrange: Player holds coin, open box is reachable
        let initialCoin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable,
        )
        let initialBox = Item(
            id: "openBox",
            .name("open box"),
            .in(.location(.startRoom)),
            .isOpen,
            .isContainer,
            .isOpenable,
        )
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialBox.attributes

        let game = MinimalGame(items: initialCoin, initialBox)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in open box\n\nYou put the gold coin in the open box.")

        // Assert Final State
        let finalCoinState = try await engine.item("coin")
        #expect(finalCoinState.parent == .item("openBox"), "Coin should be in the box")
        #expect(finalCoinState.attributes[.isTouched] == true, "Coin should be touched")

        let finalBoxState = try await engine.item("openBox")
        #expect(finalBoxState.attributes[.isTouched] == true, "Box should be touched")

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("coin")])

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
            .name("open box"),
            .in(.location(.startRoom)),
            .isOpen,
            .isContainer,
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put in open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put in open box\n\nInsert what?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails with no indirect object")
    func testInsertFailsNoIndirectObject() async throws {
        // Arrange: Player holds coin
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable,
        )
        let game = MinimalGame(items: coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in\n\nWhere do you want to insert the gold coin?")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when item not held")
    func testInsertFailsItemNotHeld() async throws {
        // Arrange: Coin is in the room, not held; box is open
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.location(.startRoom)),
            .isTakable,
        )
        let box = Item(
            id: "openBox",
            .name("open box"),
            .in(.location(.startRoom)),
            .isOpen,
            .isContainer,
            .isOpenable,
        )
        let game = MinimalGame(items: coin, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in box\n\nYou aren't holding the gold coin.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when target not reachable")
    func testInsertFailsTargetNotReachable() async throws {
        // Arrange: Box is in another room, player holds coin
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable,
        )
        let box = Item(
            id: "distantBox",
            .name("distant box"),
            .in(.nowhere),
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let game = MinimalGame(items: coin, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in distant box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in distant box\n\nYou can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when target not a container")
    func testInsertFailsTargetNotContainer() async throws {
        // Arrange: Player holds coin, target is statue (not container)
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable,
        )
        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .in(.location(.startRoom)),
            .isOpenable
        )
        let game = MinimalGame(items: coin, statue)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in statue")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in statue\n\nYou can't put things in the stone statue.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when container closed")
    func testInsertFailsContainerClosed() async throws {
        // Arrange: Box is closed, player holds coin
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
        )
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
        )  // Closed
        let game = MinimalGame(items: coin, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put coin in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in box\n\nThe wooden box is closed.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails self-insertion")
    func testInsertFailsSelfInsertion() async throws {
        // Arrange: Player holds box
        let box = Item(
            id: "box",
            .name("box"),
            .in(.player),
            .isOpen,
        )
        let game = MinimalGame(items: box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put box in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put box in box\n\nYou can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails recursive insertion")
    func testInsertFailsRecursiveInsertion() async throws {
        // Arrange: Player holds bag, bag contains box
        let bag = Item(
            id: "bag",
            .name("bag"),
            .in(.player),
            .isContainer,
            .isOpen,
        )
        let box = Item(
            id: "box",
            .name("box"),
            .in(.item("bag")),
            .isContainer,
            .isOpen,
        )
        let game = MinimalGame(items: bag, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Try to put the bag into the box (which is inside the bag)
        // Act
        try await engine.execute("put bag in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> put bag in box\n\nYou can't put the bag in the box, because the box is inside the\nbag!")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when container is full")
    func testInsertFailsContainerFull() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 but already contains item size 6
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .size(5)
        )
        let existingItem = Item(
            id: "rock",
            .name("rock"),
            .in(.item("fullBox")),
            .size(6),
        )
        let box = Item(
            id: "fullBox",
            .name("nearly full box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
            .capacity(10),
        )
        let game = MinimalGame(items: coin, box, existingItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check - Calculate manually
        let itemsInside = await engine.items(in: .item("fullBox"))
        let initialLoad = itemsInside.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 6)

        // Act
        try await engine.execute("put coin in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in box\n\nThe gold coin won't fit in the nearly full box.")

        // Assert No State Change
        #expect(try await engine.item("coin").parent == .player)  // Coin still held
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert succeeds when container has exact space")
    func testInsertSucceedsContainerExactSpace() async throws {
        // Arrange: Player holds coin (size 5), box has capacity 10 and contains item size 5
        let initialCoin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .size(5)
        )
        let existingItem = Item(
            id: "rock",
            .name("rock"),
            .in(.item("exactBox")),
            .size(5)
        )
        let initialBox = Item(
            id: "exactBox",
            .name("half-full box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
            .capacity(10),
        )
        let initialCoinAttributes = initialCoin.attributes
        let initialBoxAttributes = initialBox.attributes

        let game = MinimalGame(items: initialCoin, initialBox, existingItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check - Calculate manually
        let itemsInsideInitial = await engine.items(in: .item("exactBox"))
        let initialLoad = itemsInsideInitial.reduce(0) { $0 + $1.size }
        #expect(initialLoad == 5)

        // Act
        try await engine.execute("put coin in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in box\n\nYou put the gold coin in the half-full box.")  // Success message

        // Assert Final State
        #expect(try await engine.item("coin").parent == .item("exactBox"))  // Coin is in box
        // Final state check - Calculate manually
        let itemsInsideFinal = await engine.items(in: .item("exactBox"))
        let finalLoad = itemsInsideFinal.reduce(0) { $0 + $1.size }
        #expect(finalLoad == 10)  // Box is now full

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
        let itemToInsert = Item(
            id: "key",
            .name("small key"),
            .in(.player)
        )
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen  // Starts open
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )  // Assuming lit for test

        let game = MinimalGame(locations: room, items: itemToInsert, container)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in box\n\nYou put the small key in the wooden box.")

        // Assert Final State
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .item("box"))
        let finalContainerState = try await engine.item("box")
        #expect(finalContainerState.hasFlag(.isTouched) == true)

        // Assert Pronoun
        #expect(await engine.getPronounReference(pronoun: "it") == [.item("key")])

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
            .name("wooden box"),
            .in(.player),
            .isContainer,
            .isOpenable,
            .isOpen
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: room, items: container)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put box in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put box in box\n\nYou can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into item not in reach")
    func testInsertIntoItemNotInReach() async throws {
        // Arrange: Player holds key, container is in another room
        let itemToInsert = Item(
            id: "key",
            .name("small key"),
            .in(.player)
        )
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location("otherRoom")),
            .isContainer,
            .isOpenable,
            .isOpen
        )
        let room1 = Location(
            id: .startRoom,
            .name("Start Room"),
            .inherentlyLit
        )
        let room2 = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: room1, room2, items: itemToInsert, container)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in box\n\nYou can't see any such thing.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into target not a container")
    func testInsertIntoTargetNotAContainer() async throws {
        // Arrange: Target is a rock (not a container)
        let itemToInsert = Item(
            id: "key",
            .name("small key"),
            .in(.player)
        )
        let target = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.location(.startRoom))
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: room, items: itemToInsert, target)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in rock")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in rock\n\nYou can't put things in the smooth rock.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into closed container")
    func testInsertIntoClosedContainer() async throws {
        // Arrange: Container is closed
        let itemToInsert = Item(
            id: "key",
            .name("small key"),
            .in(.player)
        )
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: room, items: itemToInsert, container)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in box\n\nThe wooden box is closed.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into container that is full")
    func testInsertIntoContainerThatIsFull() async throws {
        // Arrange: Container has capacity 1, already contains an item
        let itemToInsert = Item(
            id: "key",
            .name("small key"),
            .in(.player)
        )
        let existingItem = Item(
            id: "gem",
            .name("shiny gem"),
            .in(.item("box")),
            .size(1)
        )
        let container = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
            .capacity(1)
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: room,
            items: itemToInsert, existingItem, container
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in box\n\nThe small key won't fit in the wooden box.")

        // Assert No State Change
        #expect(try await engine.item("key").parent == .player)  // Key still held
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert item too large for container")
    func testInsertItemTooLargeForContainer() async throws {
        // Arrange: Item size is 5, container capacity is 3
        let itemToInsert = Item(
            id: "key",
            .name("large key"),
            .in(.player),
            .size(5)
        )
        let container = Item(
            id: "box",
            .name("small box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
            .capacity(3)
        )
        let room = Location(
            id: .startRoom,
            .name("Room"),
            .inherentlyLit
        )

        let game = MinimalGame(locations: room, items: itemToInsert, container)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put key in box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put key in box\n\nThe large key won't fit in the small box.")

        // Assert No State Change
        #expect(try await engine.item("key").parent == .player)  // Key still held
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    // Helper to setup game state for nested container tests
    private func setupNestedContainerTest() async -> (GameEngine, MockIOHandler) {
        let outerBox = Item(
            id: "outerBox", .name("large box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let innerBox = Item(
            id: "innerBox", .name("small box"),
            .in(.item("outerBox")),
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let coin = Item(
            id: "coin",
            .name("shiny coin"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(items: outerBox, innerBox, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        return (engine, mockIO)
    }

    @Test("Insert into nested container (outer box)")
    func testInsertIntoNestedOuter() async throws {
        // Arrange
        let (engine, mockIO) = await setupNestedContainerTest()
        let initialCoin = try await engine.item("coin")
        let initialOuterBox = try await engine.item("outerBox")
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialOuterBox.attributes

        // Act
        try await engine.execute("put coin in large box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in large box\n\nYou put the shiny coin in the large box.")

        // Assert State
        let finalCoin = try await engine.item("coin")
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
        let initialCoin = try await engine.item("coin")
        let initialInnerBox = try await engine.item("innerBox")
        let initialParent = initialCoin.parent
        let initialItemAttributes = initialCoin.attributes
        let initialContainerAttributes = initialInnerBox.attributes

        // Act
        try await engine.execute("put coin in small box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put coin in small box\n\nYou put the shiny coin in the small box.")

        // Assert State
        let finalCoin = try await engine.item("coin")
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
            id: "bag", .name("cloth bag"),
            .in(.player),
            .isTakable,
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let game = MinimalGame(items: bag)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put bag in bag")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put bag in bag\n\nYou can't put something inside itself.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into nested container that contains itself indirectly (A in B, put B in A)")
    func testInsertIntoIndirectSelfContainer() async throws {
        // Arrange: Player holds Box B (open container). Box A is inside Box B.
        // Command: Put Box B (itemToInsert) into Box A (containerItem).
        // Expected Error: "You can't put Box B in Box A, because Box A is in Box B!"

        let boxA = Item(  // This is containerItem (Y)
            id: "boxA",
            .name("box A"),
            .in(.item("boxB")),  // Box A is INSIDE Box B
            .isContainer,  // Technically, for it to be a target container, it needs this
            .isOpen,
            .isTakable,  // So it can be a parent, but also a target for insertion
        )
        let boxB = Item(  // This is itemToInsert (X)
            id: "boxB",
            .name("box B"),
            .in(.player),  // Held by player
            .isContainer,
            .isOpen,
            .isOpenable,
            .isTakable,  // Player is holding it
        )

        let game = MinimalGame(items: boxA, boxB)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("put box B in box A")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> put box B in box A\n\nYou can't put the box B in the box A, because the box A is\ninside the box B!")

        // Assert No State Change (Box A still in Box B, Box B still held)
        let finalBoxA = try await engine.item("boxA")
        #expect(finalBoxA.parent == .item("boxB"))
        let finalBoxB = try await engine.item("boxB")
        #expect(finalBoxB.parent == .player)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert into deeply nested container that contains itself indirectly")
    func testInsertIntoDeepIndirectSelfContainer() async throws {
        // Arrange: Player holds Box C (open container).
        // Box B is inside Box C. Box A is inside Box B.
        // Command: Put Box C (itemToInsert) into Box A (containerItem).
        // Expected: "You can't put Box C in Box A, because Box A is in Box C!"

        let boxA = Item(  // This is containerItem (Y)
            id: "boxA",
            .name("box A"),
            .in(.item("boxB")),  // A is in B
            .isTakable,
            .isContainer,  // Target for insertion
            .isOpen
        )
        let boxB = Item(
            id: "boxB",
            .name("box B"),
            .in(.item("boxC")),  // B is in C
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let boxC = Item(  // This is itemToInsert (X)
            id: "boxC",
            .name("box C"),
            .in(.player),  // Held by player
            .isContainer,
            .isOpenable,
            .isOpen,
            .isTakable,
        )

        let game = MinimalGame(items: boxA, boxB, boxC)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("put box C in box A")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            "> put box C in box A\n\nYou can't put the box C in the box A, because the box A is\ninside the box C!")

        // Assert No State Change
        let finalBoxA = try await engine.item("boxA")
        #expect(finalBoxA.parent == .item("boxB"))
        let finalBoxB = try await engine.item("boxB")
        #expect(finalBoxB.parent == .item("boxC"))
        let finalBoxC = try await engine.item("boxC")
        #expect(finalBoxC.parent == .player)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Insert fails when item is fixed scenery")
    func testInsertFailsItemIsFixed() async throws {
        // Arrange: Player holds trophy (scenery), box is open
        let trophy = Item(
            id: "trophy",
            .name("glass trophy"),
            .in(.player),
            .isTakable,
            .omitDescription,
        )
        let box = Item(
            id: "openBox",
            .name("open box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen,
        )
        let game = MinimalGame(items: trophy, box)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("put trophy in the open box")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "> put trophy in the open box\n\nYou can't put things in the glass trophy.")

        // Assert No State Change
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}

extension InsertActionHandlerTests {
    private func expectedInsertChanges(
        itemToInsertID: ItemID,
        containerID: ItemID,
        initialParent: ParentEntity,
        initialItemAttributes: [ItemAttributeID: StateValue],
        initialContainerAttributes: [ItemAttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // 1. Item's parent changes to the container
        changes.append(
            StateChange(
                entityID: .item(itemToInsertID),
                attribute: .itemParent,
                oldValue: .parentEntity(initialParent),
                newValue: .parentEntity(.item(containerID))
            )
        )

        // 2. Item is touched (if not already)
        if initialItemAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(itemToInsertID),
                    attribute: .itemAttribute(.isTouched),
                    oldValue: initialItemAttributes[.isTouched],
                    newValue: true
                )
            )
        }

        // 3. Container is touched (if not already)
        if initialContainerAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityID: .item(containerID),
                    attribute: .itemAttribute(.isTouched),
                    oldValue: initialContainerAttributes[.isTouched],
                    newValue: true
                )
            )
        }

        // 4. Pronoun "it" is set to the inserted item
        // Assuming "it" wasn't already referring to itemToInsertID or was nil.
        // For more robust tests, capture existing pronoun state.
        changes.append(
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                oldValue: nil,  // Simplified for test
                newValue: .entityReferenceSet([.item(itemToInsertID)])
            )
        )

        return changes
    }
}
