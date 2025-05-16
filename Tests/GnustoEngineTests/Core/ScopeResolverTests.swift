import Testing
@testable import GnustoEngine

@Suite("ScopeResolver Tests")
struct ScopeResolverTests {
    @Test("Location is lit if inherentlyLit property is present")
    func testIsLitInherentlyLit() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: .startRoom) == true)
    }

    @Test("Location is dark if not inherentlyLit and no light source")
    func testIsLitDarkNoSource() async throws {
        let darkRoom = Location(id: .startRoom)
        let game = MinimalGame(locations: [darkRoom])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: .startRoom) == false)
    }

    @Test("Location is lit if player holds active light source")
    func testIsLitPlayerActiveLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            .in(.player),
            .isLightSource,
            .isOn,
            .isTakable
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: .startRoom) == true)
    }

    @Test("Location is dark if player holds inactive light source")
    func testIsLitPlayerInactiveLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let inactiveLamp = Item(
            id: "lamp",
            .in(.player),
            .isLightSource,
            .isTakable
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [inactiveLamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: darkRoom.id) == false)
    }

    @Test("Location is lit if active light source is in room")
    func testIsLitRoomActiveLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            .in(.location(.startRoom)),
            .isLightSource,
            .isOn
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: .startRoom) == true)
    }

    @Test("Location is dark if inactive light source is in room")
    func testIsLitRoomInactiveLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let inactiveLamp = Item(
            id: "lamp",
            .in(.location(darkRoom.id)),
            .isLightSource
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [inactiveLamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: darkRoom.id) == false)
    }

    @Test("Location is lit if inherentlyLit and player holds active light (inherentlyLit takes precedence)")
    func testIsLitInherentlyLitWithPlayerLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            .in(.player),
            .isLightSource,
            .isOn,
            .isTakable
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: .startRoom) == true)
    }

    @Test("Location is dark if location ID does not exist")
    func testIsLitNonExistentLocation() async throws {
        let game = MinimalGame(locations: [])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        await #expect(resolver.isLocationLit(locationID: "badRoom") == false)
    }

    // — visibleItemsIn Tests —

    @Test("Visible items in inherently lit room")
    func testVisibleItemsInherentlyLit() async throws {
        let visibleItem = Item(
            id: "key",
            .in(.location(.startRoom))
        )
        let invisibleItem = Item(
            id: "dust",
            .in(.location(.startRoom)),
            .isInvisible
        )
        let game = MinimalGame(items: [visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let visibleIDs = await resolver.visibleItemsIn(locationID: .startRoom)
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible in dark room")
    func testVisibleItemsDarkRoom() async throws {
        // Explicitly create a dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
            // No .inherentlyLit property
        )
        let item = Item(
            id: "key",
            .in(.location(darkRoom.id)),
            .isInvisible
        )
        let player = Player(in: darkRoom.id)

        // Initialize game with the dark room and item
        let game = MinimalGame(
            player: player,
            locations: [darkRoom],
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        // No need to modify state after initialization
        // game.state.locations[.startRoom].attributes.remove(.inherentlyLit)

        let visibleIDs = await resolver.visibleItemsIn(locationID: darkRoom.id)
        #expect(visibleIDs.isEmpty)
    }

    @Test("Visible items in room lit by player light")
    func testVisibleItemsPlayerLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            .in(.player),
            .isLightSource,
            .isOn,
            .isTakable
        )
        let visibleItem = Item(
            id: "key",
            .in(.location(.startRoom))
        )
        let invisibleItem = Item(
            id: "dust",
            .in(.location(.startRoom)),
            .isInvisible
        )
        let game = MinimalGame(items: [activeLamp, visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let visibleIDs = await resolver.visibleItemsIn(locationID: .startRoom)
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("Visible items in room lit by room light")
    func testVisibleItemsRoomLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            .in(.location(.startRoom)),
            .isLightSource,
            .isOn
        )
        let visibleItem = Item(
            id: "key",
            .in(.location(.startRoom))
)
        let invisibleItem = Item(
            id: "dust",
            .in(.location(.startRoom)),
            .isInvisible
        )
        let game = MinimalGame(items: [activeLamp, visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let visibleIDs = await resolver.visibleItemsIn(locationID: .startRoom)
        #expect(Set(visibleIDs) == Set([activeLamp.id, visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible if location ID does not exist")
    func testVisibleItemsNonExistentLocation() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let visibleIDs = await resolver.visibleItemsIn(locationID: "badRoom")
        #expect(visibleIDs.isEmpty)
    }

    // MARK: - Reachable Tests

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
        let game = MinimalGame(items: [inventoryItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable.contains(inventoryItem.id))
    }

    @Test("Reachable includes visible items in lit room")
    func testReachableVisibleLitRoom() async throws {
        let locationItem = Item(
            id: "locItem",
            .name("Location Item"),
            .in(.location(.startRoom))
        )
        let game = MinimalGame(items: [locationItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable.contains(locationItem.id))
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
            .in(.location(darkRoom.id)),
            .isInvisible
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [locationItem]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(!reachable.contains(locationItem.id))
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
        let game = MinimalGame(items: [openBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
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
        let game = MinimalGame(items: [closedBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
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
        let game = MinimalGame(items: [transparentBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable includes item in open container (lit room)")
    func testReachableOpenContainerLitRoom() async throws {
        let openBox = Item(
            id: "openBox",
            .name("open box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(openBox.id))
        )
        let game = MinimalGame(items: [openBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (lit room)")
    func testReachableClosedContainerLitRoom() async throws {
        let closedBox = Item(
            id: "closedBox",
            .name("closed box"),
            .in(.location(.startRoom)),
            .isContainer
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(closedBox.id))
        )
        let game = MinimalGame(items: [closedBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (lit room)")
    func testReachableTransparentContainerLitRoom() async throws {
        let transparentBox = Item(
            id: "transBox",
            .name("transparent box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isTransparent
        )
        let itemInBox = Item(
            id: "itemInBox",
            .name("item in box"),
            .in(.item(transparentBox.id))
        )
        let game = MinimalGame(items: [transparentBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
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
            .in(.location(darkRoom.id)),
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
            locations: [darkRoom],
            items: [openBox, itemInBox]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let reachable = await resolver.itemsReachableByPlayer()
        #expect(reachable.isEmpty) // Neither box nor item inside should be reachable in dark
    }

    @Test("No items visible in room lit by inactive light")
    func testVisibleItemsRoomInactiveLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )
        let inactiveLamp = Item(
            id: "lamp",
            .in(.location(darkRoom.id)),
            .isLightSource
        )
        let item = Item(
            id: "key",
            .in(.location(darkRoom.id)),
            .isInvisible
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [inactiveLamp, item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = await engine.scopeResolver

        let visibleIDs = await resolver.visibleItemsIn(locationID: darkRoom.id)
        #expect(visibleIDs.isEmpty)
    }
}
