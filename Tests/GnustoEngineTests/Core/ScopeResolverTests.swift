import Testing
@testable import GnustoEngine

@MainActor
@Suite("ScopeResolver Tests")
struct ScopeResolverTests {
    let testLocationID = Location.ID("startRoom")

    @Test("Location is lit if inherentlyLit property is present")
    func testIsLitInherentlyLit() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == true)
    }

    @Test("Location is dark if not inherentlyLit and no light source")
    func testIsLitDarkNoSource() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        engine.gameState.locations["startRoom"]?.properties.remove(.inherentlyLit)

        #expect(resolver.isLocationLit(locationID: "startRoom") == false)
    }

    @Test("Location is lit if player holds active light source")
    func testIsLitPlayerActiveLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource, .on, .takable,
            parent: .player
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == true)
    }

    @Test("Location is dark if player holds inactive light source")
    func testIsLitPlayerInactiveLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let inactiveLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: [.lightSource, .takable],
            parent: .player
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [inactiveLamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == false)
    }

    @Test("Location is lit if active light source is in room")
    func testIsLitRoomActiveLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource, .on,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == true)
    }

    @Test("Location is dark if inactive light source is in room")
    func testIsLitRoomInactiveLight() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let inactiveLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource,
            parent: .location(darkRoom.id)
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [inactiveLamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == false)
    }

    @Test("Location is lit if inherentlyLit and player holds active light (inherentlyLit takes precedence)")
    func testIsLitInherentlyLitWithPlayerLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource, .on, .takable,
            parent: .player
        )
        let game = MinimalGame(items: [activeLamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "startRoom") == true)
    }

    @Test("Location is dark if location ID does not exist")
    func testIsLitNonExistentLocation() async throws {
        let game = MinimalGame(locations: [])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "badRoom") == false)
    }

    // --- visibleItemsIn Tests ---

    @Test("Visible items in inherently lit room")
    func testVisibleItemsInherentlyLit() async throws {
        let visibleItem = Item(
            id: "key",
            name: "key",
            parent: .location("startRoom")
        )
        let invisibleItem = Item(
            id: "dust",
            name: "dust",
            properties: .invisible,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: "startRoom")
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible in dark room")
    func testVisibleItemsDarkRoom() async throws {
        let item = Item(
            id: "key",
            name: "key",
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [item])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        game.state.locations["startRoom"]?.properties.remove(.inherentlyLit)

        let visibleIDs = resolver.visibleItemsIn(locationID: "startRoom")
        #expect(visibleIDs.isEmpty)
    }

    @Test("Visible items in room lit by player light")
    func testVisibleItemsPlayerLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: .lightSource, .on, .takable,
            parent: .player
        )
        let visibleItem = Item(
            id: "key",
            name: "key",
            parent: .location("startRoom")
        )
        let invisibleItem = Item(
            id: "dust",
            name: "dust",
            properties: .invisible,
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [activeLamp, visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: "startRoom")
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("Visible items in room lit by room light")
    func testVisibleItemsRoomLight() async throws {
        let activeLamp = Item(
            id: "lamp",
            name: "lamp",
            properties: [.lightSource, .on],
            parent: .location("startRoom")
        )
        let visibleItem = Item(
            id: "key",
            name: "key",
            parent: .location("startRoom")
        )
        let invisibleItem = Item(
            id: "dust",
            name: "dust",
            properties: [.invisible],
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [activeLamp, visibleItem, invisibleItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: "startRoom")
        #expect(Set(visibleIDs) == Set([activeLamp.id, visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible if location ID does not exist")
    func testVisibleItemsNonExistentLocation() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: "badRoom")
        #expect(visibleIDs.isEmpty)
    }

    @Test("Reachable includes inventory")
    func testReachableInventory() async throws {
        let inventoryItem = Item(
            id: "invItem",
            name: "Inventory Item",
            properties: .takable,
            parent: .player
        )
        let game = MinimalGame(items: [inventoryItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(inventoryItem.id))
    }

    @Test("Reachable includes visible items in lit room")
    func testReachableVisibleLitRoom() async throws {
        let locationItem = Item(
            id: "locItem",
            name: "Location Item",
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [locationItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(locationItem.id))
    }

    @Test("Reachable excludes items in dark room")
    func testReachableDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let locationItem = Item(
            id: "locItem",
            name: "Location Item",
            parent: .location(darkRoom.id)
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [locationItem]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(!reachable.contains(locationItem.id))
    }

    // MARK: - Reachable Tests

    let baseBox = Item(
        id: "box",
        name: "box",
        properties: .container,
        parent: .player
    )
    let baseOpenBox = Item(
        id: "openBox",
        name: "open box",
        properties: .container, .open,
        parent: .player
    )
    let baseClosedBox = Item(
        id: "closedBox",
        name: "closed box",
        properties: .container,
        parent: .player
    )
    let baseTransparentBox = Item(
        id: "transBox",
        name: "transparent box",
        properties: .container, .transparent,
        parent: .player
    )
    let baseItemInBox = Item(
        id: "itemInBox",
        name: "item in box"
    )

    @Test("Reachable includes item in open container (inventory)")
    func testReachableOpenContainerInventory() async throws {
        let openBox = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .player
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(openBox.id)
        )
        let game = MinimalGame(items: [openBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (inventory)")
    func testReachableClosedContainerInventory() async throws {
        let closedBox = Item(
            id: "closedBox",
            name: "closed box",
            properties: .container,
            parent: .player
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(closedBox.id)
        )
        let game = MinimalGame(items: [closedBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (inventory)")
    func testReachableTransparentContainerInventory() async throws {
        let transparentBox = Item(
            id: "transBox",
            name: "transparent box",
            properties: .container, .transparent,
            parent: .player
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(transparentBox.id)
        )
        let game = MinimalGame(items: [transparentBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable includes item in open container (lit room)")
    func testReachableOpenContainerLitRoom() async throws {
        let openBox = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .location("startRoom")
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(openBox.id)
        )
        let game = MinimalGame(items: [openBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (lit room)")
    func testReachableClosedContainerLitRoom() async throws {
        let closedBox = Item(
            id: "closedBox",
            name: "closed box",
            properties: .container,
            parent: .location("startRoom")
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(closedBox.id)
        )
        let game = MinimalGame(items: [closedBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (lit room)")
    func testReachableTransparentContainerLitRoom() async throws {
        let transparentBox = Item(
            id: "transBox",
            name: "transparent box",
            properties: .container, .transparent,
            parent: .location("startRoom")
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(transparentBox.id)
        )
        let game = MinimalGame(items: [transparentBox, itemInBox])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes container and item in dark room")
    func testReachableContainerDarkRoom() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let openBox = Item(
            id: "openBox",
            name: "open box",
            properties: .container, .open,
            parent: .location(darkRoom.id)
        )
        let itemInBox = Item(
            id: "itemInBox",
            name: "item in box",
            parent: .item(openBox.id)
        )
        let game = MinimalGame(
            player: Player(in: darkRoom.id),
            locations: [darkRoom],
            items: [openBox, itemInBox]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.isEmpty) // Neither box nor item inside should be reachable in dark
    }

    // Add tests for nested containers, transparent closed containers, etc.
}
