import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("ScopeResolver Tests")
struct ScopeResolverTests {
    let baseBox = Item(
        id: "box",
        .in(.player),
        .isContainer
    )
    let baseOpenBox = Item(
        id: "openBox",
        .name("open box"),
        .in(.player),
        .isContainer,
        .isOpen
    )
    let baseClosedBox = Item(
        id: "closedBox",
        .name("closed box"),
        .in(.player),
        .isContainer
    )
    let baseTransparentBox = Item(
        id: "transBox",
        .name("transparent box"),
        .in(.player),
        .isContainer,
        .isTransparent
    )
    let baseItemInBox = Item(
        id: "itemInBox",
        .in(.nowhere)
    )

    @Test("Reachable includes inventory")
    func testReachableInventory() async throws {
        let inventoryItem = Item(
            id: "invItem",
            .name("Inventory Item"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: inventoryItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(inventoryItem.id))
    }

    @Test("Reachable includes visible items in lit room")
    func testReachableVisibleLitRoom() async throws {
        let locationItem = Item(
            id: "locItem",
            .name("Location Item"),
            .in(.startRoom)
        )
        let game = MinimalGame(items: locationItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(locationItem.id))
    }

    @Test("Reachable excludes items in dark room")
    func testReachableDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let locationItem = Item(
            id: "locItem",
            .name("Location Item"),
            .in(darkRoom.id),
            .isInvisible
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: darkRoom,
            items: locationItem
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(!reachable.map(\.id).contains(locationItem.id))
    }

    @Test("Reachable includes item in open container (inventory)")
    func testReachableOpenContainerInventory() async throws {
        let openBox = Item(
            id: "openBox",
            .name("open box"),
            .in(.player),
            .isContainer,
            .isOpen
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(openBox.id))
        )
        let game = MinimalGame(items: openBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(openBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id))
    }

    @Test("Reachable excludes item in closed container (inventory)")
    func testReachableClosedContainerInventory() async throws {
        let closedBox = Item(
            id: "closedBox",
            .name("closed box"),
            .in(.player),
            .isContainer
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(closedBox.id))
        )
        let game = MinimalGame(items: closedBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(closedBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id) == false)
    }

    @Test("Reachable includes item in transparent container (inventory)")
    func testReachableTransparentContainerInventory() async throws {
        let transparentBox = Item(
            id: "transBox",
            .name("transparent box"),
            .in(.player),
            .isContainer,
            .isTransparent
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(transparentBox.id))
        )
        let game = MinimalGame(items: transparentBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(transparentBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id))
    }

    @Test("Reachable includes item in open container (lit room)")
    func testReachableOpenContainerLitRoom() async throws {
        let openBox = Item(
            id: "openBox",
            .name("open box"),
            .in(.startRoom),
            .isContainer,
            .isOpen
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(openBox.id))
        )
        let game = MinimalGame(items: openBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(openBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id))
    }

    @Test("Reachable excludes item in closed container (lit room)")
    func testReachableClosedContainerLitRoom() async throws {
        let closedBox = Item(
            id: "closedBox",
            .name("closed box"),
            .in(.startRoom),
            .isContainer
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(closedBox.id))
        )
        let game = MinimalGame(items: closedBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(closedBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id) == false)
    }

    @Test("Reachable includes item in transparent container (lit room)")
    func testReachableTransparentContainerLitRoom() async throws {
        let transparentBox = Item(
            id: "transBox",
            .name("transparent box"),
            .in(.startRoom),
            .isContainer,
            .isTransparent
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(transparentBox.id))
        )
        let game = MinimalGame(items: transparentBox, itemInBox)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(transparentBox.id))
        #expect(reachable.map(\.id).contains(itemInBox.id))

    }

    @Test("Reachable excludes container and item in dark room")
    func testReachableContainerDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let openBox = Item(
            id: "openBox",
            .name("open box"),
            .in(darkRoom.id),
            .isContainer,
            .isOpen
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(openBox.id))
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: darkRoom,
            items: openBox, itemInBox
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let itemsReachableByPlayer = await engine.itemsReachableByPlayer()
        #expect(itemsReachableByPlayer.isEmpty)  // Neither box nor item inside should be reachable in dark
    }

    @Test("Reachable includes scenery items in lit room")
    func testReachableSceneryLitRoom() async throws {
        let sceneryItem = Item(
            id: "window",
            .name("Window"),
            .in(.startRoom),
            .omitDescription
        )
        let game = MinimalGame(items: sceneryItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        let reachable = await engine.itemsReachableByPlayer()
        #expect(reachable.map(\.id).contains(sceneryItem.id))
    }
}
