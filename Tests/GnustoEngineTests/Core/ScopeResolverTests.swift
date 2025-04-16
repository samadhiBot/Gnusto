import Testing
@testable import GnustoEngine

@Suite("ScopeResolver Tests")
struct ScopeResolverTests {
    let resolver = ScopeResolver()
    let testLocationID = Location.ID("testRoom") // Define once

    // --- Helper Setup ---
    /// Creates a GameState for testing ScopeResolver.
    /// Assumes the parent property of each item in the `items` array is already set correctly.
    func createTestGameState(
        locationProperties: Set<LocationProperty> = [],
        items: [Item]
    ) -> (GameState, Location.ID) {
        let testLocation = Location(id: testLocationID, name: "Test Room", description: "A room.", properties: locationProperties)
        let player = Player(currentLocationID: testLocation.id)

        // Build the items dictionary directly from the input array
        let allItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        // Use the internal GameState initializer directly
        let gameState = GameState(
            locations: [testLocation.id: testLocation],
            items: allItems,
            player: player,
            vocabulary: Vocabulary() // Use default initializer
        )
        return (gameState, testLocation.id)
    }

    // --- isLocationLit Tests ---

    @Test("Location is lit if inherentlyLit property is present")
    func testIsLitInherentlyLit() {
        let (gameState, locationID) = createTestGameState(locationProperties: [.inherentlyLit], items: [])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == true)
    }

    @Test("Location is dark if not inherentlyLit and no light source")
    func testIsLitDarkNoSource() {
        let (gameState, locationID) = createTestGameState(items: [])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == false)
    }

    @Test("Location is lit if player holds active light source")
    func testIsLitPlayerActiveLight() {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player) // Set parent
        let (gameState, locationID) = createTestGameState(items: [activeLamp])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == true)
    }

    @Test("Location is dark if player holds inactive light source")
    func testIsLitPlayerInactiveLight() {
        let inactiveLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .takable], parent: .player) // Set parent
        let (gameState, locationID) = createTestGameState(items: [inactiveLamp])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == false)
    }

    @Test("Location is lit if active light source is in room")
    func testIsLitRoomActiveLight() {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on], parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(items: [activeLamp])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == true)
    }

    @Test("Location is dark if inactive light source is in room")
    func testIsLitRoomInactiveLight() {
        let inactiveLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource], parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(items: [inactiveLamp])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == false)
    }

    @Test("Location is lit if inherentlyLit and player holds active light (inherentlyLit takes precedence)")
    func testIsLitInherentlyLitWithPlayerLight() {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player) // Set parent
        let (gameState, locationID) = createTestGameState(locationProperties: [.inherentlyLit], items: [activeLamp])
        #expect(resolver.isLocationLit(locationID: locationID, gameState: gameState) == true)
    }

    @Test("Location is dark if location ID does not exist")
    func testIsLitNonExistentLocation() {
        let (gameState, _) = createTestGameState(items: [])
        #expect(resolver.isLocationLit(locationID: "badRoom", gameState: gameState) == false)
    }

    // --- visibleItemsIn Tests ---

    @Test("Visible items in inherently lit room")
    func testVisibleItemsInherentlyLit() {
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID)) // Set parent
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(
            locationProperties: [.inherentlyLit],
            items: [visibleItem, invisibleItem]
        )

        let visibleIDs = resolver.visibleItemsIn(locationID: locationID, gameState: gameState)
        #expect(Set(visibleIDs) == Set([visibleItem.id])) // Use Set for order independence
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible in dark room")
    func testVisibleItemsDarkRoom() {
        let item = Item(id: "key", name: "key", parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(
            items: [item] // Room is dark by default
        )

        let visibleIDs = resolver.visibleItemsIn(locationID: locationID, gameState: gameState)
        #expect(visibleIDs.isEmpty)
    }

    @Test("Visible items in room lit by player light")
    func testVisibleItemsPlayerLight() {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable], parent: .player) // Set parent
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID)) // Set parent
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(
            items: [activeLamp, visibleItem, invisibleItem]
        )

        let visibleIDs = resolver.visibleItemsIn(locationID: locationID, gameState: gameState)
        #expect(Set(visibleIDs) == Set([visibleItem.id])) // Use Set
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("Visible items in room lit by room light")
    func testVisibleItemsRoomLight() {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on], parent: .location(testLocationID)) // Set parent
        let visibleItem = Item(id: "key", name: "key", parent: .location(testLocationID)) // Set parent
        let invisibleItem = Item(id: "dust", name: "dust", properties: [.invisible], parent: .location(testLocationID)) // Set parent
        let (gameState, locationID) = createTestGameState(
            items: [activeLamp, visibleItem, invisibleItem]
        )

        let visibleIDs = resolver.visibleItemsIn(locationID: locationID, gameState: gameState)
        #expect(Set(visibleIDs) == Set([activeLamp.id, visibleItem.id]))
        #expect(!visibleIDs.contains(invisibleItem.id))
    }

    @Test("No items visible if location ID does not exist")
    func testVisibleItemsNonExistentLocation() {
        let (gameState, _) = createTestGameState(items: [])
        let visibleIDs = resolver.visibleItemsIn(locationID: "badRoom", gameState: gameState)
        #expect(visibleIDs.isEmpty)
    }

    // --- itemsReachableByPlayer Tests ---

    @Test("Reachable includes inventory")
    func testReachableInventory() {
        let inventoryItem = Item(id: "invItem", name: "Inventory Item", properties: [.takable], parent: .player) // Set parent
        let (gameState, _) = createTestGameState(items: [inventoryItem])

        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable.contains(inventoryItem.id))
    }

    @Test("Reachable includes visible items in lit room")
    func testReachableVisibleLitRoom() {
        let locationItem = Item(id: "locItem", name: "Location Item", parent: .location(testLocationID)) // Set parent
        let (gameState, _) = createTestGameState(locationProperties: [.inherentlyLit], items: [locationItem])

        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable.contains(locationItem.id))
    }

    @Test("Reachable excludes items in dark room")
    func testReachableDarkRoom() {
        let locationItem = Item(id: "locItem", name: "Location Item", parent: .location(testLocationID)) // Set parent
        let (gameState, _) = createTestGameState(items: [locationItem]) // Dark room

        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(!reachable.contains(locationItem.id))
    }

    // --- Container Setup for Reachable Tests ---
    // Define base items without parents first
    let baseBox = Item(id: "box", name: "box", properties: [.container])
    let baseOpenBox = Item(id: "openBox", name: "open box", properties: [.container, .open])
    let baseClosedBox = Item(id: "closedBox", name: "closed box", properties: [.container])
    let baseTransparentBox = Item(id: "transBox", name: "transparent box", properties: [.container, .transparent])
    let baseItemInBox = Item(id: "itemInBox", name: "item in box")

    @Test("Reachable includes item in open container (inventory)")
    func testReachableOpenContainerInventory() {
        let openBox = self.baseOpenBox.withParent(.player) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let (gameState, _) = createTestGameState(items: [openBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (inventory)")
    func testReachableClosedContainerInventory() {
        let closedBox = self.baseClosedBox.withParent(.player) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(closedBox.id))
        let (gameState, _) = createTestGameState(items: [closedBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (inventory)")
    func testReachableTransparentContainerInventory() {
        let transparentBox = self.baseTransparentBox.withParent(.player) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(transparentBox.id))
        let (gameState, _) = createTestGameState(items: [transparentBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable includes item in open container (lit room)")
    func testReachableOpenContainerLitRoom() {
        let openBox = self.baseOpenBox.withParent(.location(testLocationID)) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let (gameState, _) = createTestGameState(locationProperties: [.inherentlyLit], items: [openBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([openBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes item in closed container (lit room)")
    func testReachableClosedContainerLitRoom() {
        let closedBox = self.baseClosedBox.withParent(.location(testLocationID)) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(closedBox.id))
        let (gameState, _) = createTestGameState(locationProperties: [.inherentlyLit], items: [closedBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable.contains(closedBox.id))
        #expect(!reachable.contains(itemInBox.id))
        #expect(reachable.count == 1)
    }

    @Test("Reachable includes item in transparent container (lit room)")
    func testReachableTransparentContainerLitRoom() {
        let transparentBox = self.baseTransparentBox.withParent(.location(testLocationID)) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(transparentBox.id))
        let (gameState, _) = createTestGameState(locationProperties: [.inherentlyLit], items: [transparentBox, itemInBox])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([transparentBox.id, itemInBox.id]))
    }

    @Test("Reachable excludes container and item in dark room")
    func testReachableContainerDarkRoom() {
        let openBox = self.baseOpenBox.withParent(.location(testLocationID)) // Use self.
        let itemInBox = self.baseItemInBox.withParent(.item(openBox.id))
        let (gameState, _) = createTestGameState(items: [openBox, itemInBox]) // Dark room
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable.isEmpty) // Nothing reachable beyond potential inventory
    }

    // --- Nested Container Tests ---
    // Define base items without parents first
    let baseOuterBox = Item(id: "outer", name: "outer box", properties: [.container, .open])
    let baseInnerBox = Item(id: "inner", name: "inner box", properties: [.container, .open])
    let baseItemInInner = Item(id: "innerItem", name: "item in inner box")

    @Test("Reachable includes item in nested open container (inventory)")
    func testReachableNestedOpenInventory() {
        let outerBox = self.baseOuterBox.withParent(.player) // Use self.
        let innerBox = self.baseInnerBox.withParent(.item(outerBox.id))
        let itemInInner = self.baseItemInInner.withParent(.item(innerBox.id))
        let (gameState, _) = createTestGameState(items: [outerBox, innerBox, itemInInner])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([outerBox.id, innerBox.id, itemInInner.id]))
    }

    @Test("Reachable excludes item if inner container is closed (inventory)")
    func testReachableNestedClosedInnerInventory() {
        let outerBox = self.baseOuterBox.withParent(.player) // Use self.
        let closedInnerBox = Item(id: "inner", name: "inner box", properties: [.container]).withParent(.item(outerBox.id))
        let itemInInner = self.baseItemInInner.withParent(.item(closedInnerBox.id))
        let (gameState, _) = createTestGameState(items: [outerBox, closedInnerBox, itemInInner])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([outerBox.id, closedInnerBox.id]))
    }

    @Test("Reachable excludes items if outer container is closed (inventory)")
    func testReachableNestedClosedOuterInventory() {
        let closedOuterBox = Item(id: "outer", name: "outer box", properties: [.container]).withParent(.player)
        let innerBox = self.baseInnerBox.withParent(.item(closedOuterBox.id))
        let itemInInner = self.baseItemInInner.withParent(.item(innerBox.id))
        let (gameState, _) = createTestGameState(items: [closedOuterBox, innerBox, itemInInner])
        let reachable = resolver.itemsReachableByPlayer(gameState: gameState)
        #expect(reachable == Set([closedOuterBox.id]))
    }
}

// Helper extension to create item copy with different parent for tests
extension Item {
    /// Creates a new Item instance with the same properties but a new parent.
    /// Useful for setting up test data where item parentage is crucial.
    func withParent(_ newParent: ParentEntity) -> Item {
        return Item(
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
            parent: newParent // Apply the new parent here
        )
    }
}
