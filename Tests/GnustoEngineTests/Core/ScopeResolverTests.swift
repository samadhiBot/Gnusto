import Testing
@testable import GnustoEngine

@MainActor
@Suite("ScopeResolver Tests")
struct ScopeResolverTests {
    let testLocationID = Location.ID("testRoom") // Define once

    // --- Helper Setup ---
    /// Creates a GameState for testing ScopeResolver.
    func createTestGameState(
        locationProperties: Set<LocationProperty> = [],
        items: [Item]
    ) -> GameState {
        let testLocation = Location(id: testLocationID, name: "Test Room", description: "A room.", properties: locationProperties)
        let player = Player(currentLocationID: testLocation.id)
        let allItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let gameState = GameState(
            locations: [testLocation.id: testLocation],
            items: allItems,
            player: player,
            vocabulary: Vocabulary() // Use default initializer
        )
        return gameState
    }

    // --- isLocationLit Tests ---

    @Test("Location is lit if inherentlyLit property is present")
    func testIsLitInherentlyLit() async throws {
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == true)
    }

    @Test("Location is dark if not inherentlyLit and no light source")
    func testIsLitDarkNoSource() async throws {
        let gameState = createTestGameState(items: [])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == false)
    }

    @Test("Location is lit if player holds active light source")
    func testIsLitPlayerActiveLight() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player)
        let gameState = createTestGameState(items: [activeLamp])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == true)
    }

    @Test("Location is dark if player holds inactive light source")
    func testIsLitPlayerInactiveLight() async throws {
        let inactiveLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .takable], parent: .player)
        let gameState = createTestGameState(items: [inactiveLamp])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == false)
    }

    @Test("Location is lit if active light source is in room")
    func testIsLitRoomActiveLight() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on], parent: .location(testLocationID))
        let gameState = createTestGameState(items: [activeLamp])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == true)
    }

    @Test("Location is dark if inactive light source is in room")
    func testIsLitRoomInactiveLight() async throws {
        let inactiveLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource], parent: .location(testLocationID))
        let gameState = createTestGameState(items: [inactiveLamp])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == false)
    }

    @Test("Location is lit if inherentlyLit and player holds active light (inherentlyLit takes precedence)")
    func testIsLitInherentlyLitWithPlayerLight() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player)
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [activeLamp])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: testLocationID) == true)
    }

    @Test("Location is dark if location ID does not exist")
    func testIsLitNonExistentLocation() async throws {
        let gameState = createTestGameState(items: [])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        #expect(resolver.isLocationLit(locationID: "badRoom") == false)
    }

    // --- visibleItemsIn Tests ---

    @Test("Visible items in inherently lit room")
    func testVisibleItemsInherentlyLit() async throws {
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID))
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID))
        let gameState = createTestGameState(
            locationProperties: [.inherentlyLit],
            items: [visibleItem, invisibleItem]
        )
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: testLocationID)
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible in dark room")
    func testVisibleItemsDarkRoom() async throws {
        let item = Item(id: "key", name: "key", parent: .location(testLocationID))
        let gameState = createTestGameState(
            items: [item] // Room is dark by default
        )
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: testLocationID)
        #expect(visibleIDs.isEmpty)
    }

    @Test("Visible items in room lit by player light")
    func testVisibleItemsPlayerLight() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player)
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID))
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID))
        let gameState = createTestGameState(
            items: [activeLamp, visibleItem, invisibleItem]
        )
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: testLocationID)
        #expect(Set(visibleIDs) == Set([visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("Visible items in room lit by room light")
    func testVisibleItemsRoomLight() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on], parent: .location(testLocationID))
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID))
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID))
        let gameState = createTestGameState(
            items: [activeLamp, visibleItem, invisibleItem]
        )
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: testLocationID)
        #expect(Set(visibleIDs) == Set([activeLamp.id, visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible if location ID does not exist")
    func testVisibleItemsNonExistentLocation() async throws {
        let gameState = createTestGameState(items: [])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let visibleIDs = resolver.visibleItemsIn(locationID: "badRoom")
        #expect(visibleIDs.isEmpty)
    }

    // --- itemsReachableByPlayer Tests ---

    @Test("Reachable includes inventory")
    func testReachableInventory() async throws {
        let inventoryItem = Item(id: "invItem", name: "Inventory Item", properties: [.takable], parent: .player)
        let gameState = createTestGameState(items: [inventoryItem])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(inventoryItem.id))
    }

    @Test("Reachable includes visible items in lit room")
    func testReachableVisibleLitRoom() async throws {
        let locationItem = Item(id: "locItem", name: "Location Item", parent: .location(testLocationID))
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [locationItem])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(locationItem.id))
    }

    @Test("Reachable excludes items in dark room")
    func testReachableDarkRoom() async throws {
        let locationItem = Item(id: "locItem", name: "Location Item", parent: .location(testLocationID))
        let gameState = createTestGameState(items: [locationItem]) // Dark room
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(!reachable.contains(locationItem.id))
    }

    // --- Container Setup for Reachable Tests ---
    // Need to be lazy vars or initialized in setup
    let baseBox = Item(id: "box", name: "box", properties: [.container])
    let baseOpenBox = Item(id: "openBox", name: "open box", properties: [.container, .open])
    let baseClosedBox = Item(id: "closedBox", name: "closed box", properties: [.container])
    let baseTransparentBox = Item(id: "transBox", name: "transparent box", properties: [.container, .transparent])
    let baseItemInBox = Item(id: "itemInBox", name: "item in box")

    @Test("Reachable includes item in open container (inventory)")
    func testReachableOpenContainerInventory() async throws {
        let openBox = self.baseOpenBox.withParent(.player)
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let gameState = createTestGameState(items: [openBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (inventory)")
    func testReachableClosedContainerInventory() async throws {
        let closedBox = self.baseClosedBox.withParent(.player)
        let itemInBox = self.baseItemInBox.withParent(.item(closedBox.id))
        let gameState = createTestGameState(items: [closedBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (inventory)")
    func testReachableTransparentContainerInventory() async throws {
        let transparentBox = self.baseTransparentBox.withParent(.player)
        let itemInBox = self.baseItemInBox.withParent(.item(transparentBox.id))
        let gameState = createTestGameState(items: [transparentBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable includes item in open container (lit room)")
    func testReachableOpenContainerLitRoom() async throws {
        let openBox = self.baseOpenBox.withParent(.location(testLocationID))
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [openBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (lit room)")
    func testReachableClosedContainerLitRoom() async throws {
        let closedBox = self.baseClosedBox.withParent(.location(testLocationID))
        let itemInBox = self.baseItemInBox.withParent(.item(closedBox.id))
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [closedBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (lit room)")
    func testReachableTransparentContainerLitRoom() async throws {
        let transparentBox = self.baseTransparentBox.withParent(.location(testLocationID))
        let itemInBox = self.baseItemInBox.withParent(.item(transparentBox.id))
        let gameState = createTestGameState(locationProperties: [.inherentlyLit], items: [transparentBox, itemInBox])
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes container and item in dark room")
    func testReachableContainerDarkRoom() async throws {
        let openBox = self.baseOpenBox.withParent(.location(testLocationID))
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let gameState = createTestGameState(items: [openBox, itemInBox]) // Dark room
        let mockParser = MockParser()
        let mockIO = await MockIOHandler()
        let engine = GameEngine(initialState: gameState, parser: mockParser, ioHandler: mockIO)
        let resolver = engine.scopeResolver

        let reachable = resolver.itemsReachableByPlayer()
        #expect(reachable.isEmpty) // Neither box nor item inside should be reachable in dark
    }

    // Add tests for nested containers, transparent closed containers, etc.
}

// Helper extension for tests needing items with modified parents
extension Item {
    /// Returns a new Item instance with the same properties but a different parent.
    func withParent(_ newParent: ParentEntity) -> Item {
        // Create a new item instance by copying relevant properties.
        let newItem = Item(
            id: self.id,
            name: self.name,
            adjectives: self.adjectives,
            synonyms: self.synonyms,
            description: self.description,
            firstDescription: self.firstDescription,
            subsequentDescription: self.subsequentDescription,
            text: self.text,
            heldText: self.heldText,
            properties: self.properties,
            size: self.size,
            capacity: self.capacity,
            parent: newParent, // Set the new parent
            readableText: self.readableText,
            lockKey: self.lockKey
        )
        return newItem
    }
}
