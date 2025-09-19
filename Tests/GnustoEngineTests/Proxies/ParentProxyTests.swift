import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ParentProxy Tests")
struct ParentProxyTests {

    // MARK: - Core Functionality Tests

    @Test("ParentProxy creation from ParentEntity")
    func testParentProxyCreationFromParentEntity() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("wooden box"),
            .isContainer,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test location parent
        let locationEntity = ParentEntity.location(.startRoom)
        let locationParent = await engine.parent(from: locationEntity)

        if case .location(let locationProxy) = locationParent {
            #expect(locationProxy.id == .startRoom)
        } else {
            #expect(Bool(false), "Expected location parent")
        }

        // When/Then - Test item parent
        let itemEntity = ParentEntity.item("container")
        let itemParent = await engine.parent(from: itemEntity)

        if case .item(let itemProxy) = itemParent {
            #expect(itemProxy.id == "container")
        } else {
            #expect(Bool(false), "Expected item parent")
        }

        // When/Then - Test player parent
        let playerEntity = ParentEntity.player
        let playerParent = await engine.parent(from: playerEntity)
        #expect(playerParent == .player)

        // When/Then - Test nowhere parent
        let nowhereEntity = ParentEntity.nowhere
        let nowhereParent = await engine.parent(from: nowhereEntity)
        #expect(nowhereParent == .nowhere)
    }

    @Test("ParentProxy equality comparisons")
    func testParentProxyEquality() async throws {
        // Given
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let container1 = Item(
            id: "container1",
            .name("first box"),
            .isContainer,
            .in(.startRoom)
        )

        let container2 = Item(
            id: "container2",
            .name("second box"),
            .isContainer,
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: container1, container2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let locationParent1 = await engine.parent(from: .location(.startRoom))
        let locationParent2 = await engine.parent(from: .location(.startRoom))
        let differentLocationParent = await engine.parent(from: .location("otherRoom"))

        let itemParent1 = await engine.parent(from: .item("container1"))
        let itemParent2 = await engine.parent(from: .item("container1"))
        let differentItemParent = await engine.parent(from: .item("container2"))

        let playerParent1 = await engine.parent(from: .player)
        let playerParent2 = await engine.parent(from: .player)

        let nowhereParent1 = await engine.parent(from: .nowhere)
        let nowhereParent2 = await engine.parent(from: .nowhere)

        // Then - Test same location parents
        #expect(locationParent1 == locationParent2)
        #expect(locationParent1 != differentLocationParent)

        // Then - Test same item parents
        #expect(itemParent1 == itemParent2)
        #expect(itemParent1 != differentItemParent)

        // Then - Test player parents
        #expect(playerParent1 == playerParent2)

        // Then - Test nowhere parents
        #expect(nowhereParent1 == nowhereParent2)

        // Then - Test different types
        #expect(locationParent1 != itemParent1)
        #expect(locationParent1 != playerParent1)
        #expect(locationParent1 != nowhereParent1)
        #expect(itemParent1 != playerParent1)
        #expect(itemParent1 != nowhereParent1)
        #expect(playerParent1 != nowhereParent1)
    }

    @Test("ParentProxy hashing")
    func testParentProxyHashing() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("wooden box"),
            .isContainer,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let locationParent1 = await engine.parent(from: .location(.startRoom))
        let locationParent2 = await engine.parent(from: .location(.startRoom))

        let itemParent1 = await engine.parent(from: .item("container"))
        let itemParent2 = await engine.parent(from: .item("container"))

        let playerParent1 = await engine.parent(from: .player)
        let playerParent2 = await engine.parent(from: .player)

        let nowhereParent1 = await engine.parent(from: .nowhere)
        let nowhereParent2 = await engine.parent(from: .nowhere)

        // Then - Equal objects should have equal hash values
        #expect(locationParent1.hashValue == locationParent2.hashValue)
        #expect(itemParent1.hashValue == itemParent2.hashValue)
        #expect(playerParent1.hashValue == playerParent2.hashValue)
        #expect(nowhereParent1.hashValue == nowhereParent2.hashValue)
    }

    // MARK: - Case-Specific Tests

    @Test("ParentProxy location case")
    func testParentProxyLocationCase() async throws {
        // Given
        let library = Location(
            id: "library",
            .name("Grand Library"),
            .description("A vast library."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            locations: library
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let parent = await engine.parent(from: .location("library"))

        // Then
        if case .location(let locationProxy) = parent {
            #expect(locationProxy.id == "library")
            #expect(await locationProxy.name == "Grand Library")
        } else {
            #expect(Bool(false), "Expected location case")
        }
    }

    @Test("ParentProxy item case")
    func testParentProxyItemCase() async throws {
        // Given
        let container = Item(
            id: "treasureChest",
            .name("ornate treasure chest"),
            .description("A beautifully carved chest."),
            .isContainer,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let parent = await engine.parent(from: .item("treasureChest"))

        // Then
        if case .item(let itemProxy) = parent {
            #expect(itemProxy.id == "treasureChest")
            #expect(await itemProxy.name == "ornate treasure chest")
            #expect(await itemProxy.isContainer == true)
        } else {
            #expect(Bool(false), "Expected item case")
        }
    }

    @Test("ParentProxy player case")
    func testParentProxyPlayerCase() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let parent = await engine.parent(from: .player)

        // Then
        #expect(parent == .player)

        if case .player = parent {
            // Correct case
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected player case")
        }
    }

    @Test("ParentProxy nowhere case")
    func testParentProxyNowhereCase() async throws {
        // Given
        let game = MinimalGame()

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let parent = await engine.parent(from: .nowhere)

        // Then
        #expect(parent == .nowhere)

        if case .nowhere = parent {
            // Correct case
            #expect(Bool(true))
        } else {
            #expect(Bool(false), "Expected nowhere case")
        }
    }

    // MARK: - Integration Tests

    @Test("ParentProxy in item parent relationships")
    func testParentProxyInItemParentRelationships() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .isContainer,
            .isOpen,
            .in(.player)
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.item("bag"))
        )

        let bookOnFloor = Item(
            id: "book",
            .name("old book"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bag, coin, bookOnFloor
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test coin in bag (item parent)
        let coinProxy = await engine.item("coin")
        let coinParent = await coinProxy.parent

        if case .item(let bagProxy) = coinParent {
            #expect(bagProxy.id == "bag")
        } else {
            #expect(Bool(false), "Expected coin to be in bag")
        }

        // When/Then - Test bag with player (player parent)
        let bagProxy = await engine.item("bag")
        let bagParent = await bagProxy.parent
        #expect(bagParent == .player)

        // When/Then - Test book on floor (location parent)
        let bookProxy = await engine.item("book")
        let bookParent = await bookProxy.parent

        if case .location(let roomProxy) = bookParent {
            #expect(roomProxy.id == .startRoom)
        } else {
            #expect(Bool(false), "Expected book to be in room")
        }
    }

    @Test("ParentProxy maintains consistency through state changes")
    func testParentProxyConsistencyThroughStateChanges() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When - Initially in room
        let coinProxy = await engine.item("coin")
        let initialParent = await coinProxy.parent

        if case .location(let roomProxy) = initialParent {
            #expect(roomProxy.id == .startRoom)
        } else {
            #expect(Bool(false), "Expected coin to start in room")
        }

        // When - Take the coin
        try await engine.execute("take coin")

        // Then - Now with player
        let finalParent = await coinProxy.parent
        #expect(finalParent == .player)
    }

    @Test("ParentProxy use cases in collections")
    func testParentProxyInCollections() async throws {
        // Given
        let bag = Item(
            id: "bag",
            .name("leather bag"),
            .isContainer,
            .in(.player)
        )

        let game = MinimalGame(
            items: bag
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let playerParent1 = await engine.parent(from: .player)
        let playerParent2 = await engine.parent(from: .player)
        let bagItemParent = await engine.parent(from: .item("bag"))
        let roomLocationParent = await engine.parent(from: .location(.startRoom))
        let nowhereParent = await engine.parent(from: .nowhere)

        // Then - Test in Set (requires Hashable)
        let parentSet: Set<ParentProxy> = [
            playerParent1,
            playerParent2,  // Should be deduplicated
            bagItemParent,
            roomLocationParent,
            nowhereParent,
        ]

        #expect(parentSet.count == 4)  // player, bag, room, nowhere (player1 and player2 are the same)

        // Then - Test in Array and sorting would work if Comparable is implemented
        let parentArray = [playerParent1, bagItemParent, roomLocationParent, nowhereParent]
        #expect(parentArray.count == 4)
    }
}
