import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ProxyReference Tests")
struct ProxyReferenceTests {

    // MARK: - Core Functionality Tests

    @Test("ProxyReference creation from EntityReference")
    func testProxyReferenceCreationFromEntityReference() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test item reference
        let itemEntity = EntityReference.item(testItem)
        let itemReference = await ProxyReference(from: itemEntity, with: engine)

        #expect(itemReference.isItem == true)
        #expect(itemReference.isLocation == false)
        #expect(itemReference.isPlayer == false)
        #expect(itemReference.isUniversal == false)

        // When/Then - Test location reference
        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationEntity = EntityReference.location(startRoom)
        let locationReference = await ProxyReference(from: locationEntity, with: engine)

        #expect(locationReference.isLocation == true)
        #expect(locationReference.isItem == false)
        #expect(locationReference.isPlayer == false)
        #expect(locationReference.isUniversal == false)

        // When/Then - Test player reference
        let playerEntity = EntityReference.player
        let playerReference = await ProxyReference(from: playerEntity, with: engine)

        #expect(playerReference.isPlayer == true)
        #expect(playerReference.isItem == false)
        #expect(playerReference.isLocation == false)
        #expect(playerReference.isUniversal == false)

        // When/Then - Test universal reference
        let universalEntity = EntityReference.universal(.ground)
        let universalReference = await ProxyReference(from: universalEntity, with: engine)

        #expect(universalReference.isUniversal == true)
        #expect(universalReference.isItem == false)
        #expect(universalReference.isLocation == false)
        #expect(universalReference.isPlayer == false)
    }

    @Test("ProxyReference proxy extraction methods")
    func testProxyReferenceProxyExtraction() async throws {
        // Given
        let startRoom = Location(
            id: "library",
            .name("Grand Library"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("ancient tome"),
            .in("library")
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            items: book
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test item proxy extraction
        let itemEntity = EntityReference.item(book)
        let itemReference = await ProxyReference(from: itemEntity, with: engine)

        let extractedItemProxy = itemReference.itemProxy
        #expect(extractedItemProxy != nil)
        #expect(extractedItemProxy?.id == "book")

        let extractedLocationProxy = itemReference.locationProxy
        #expect(extractedLocationProxy == nil)

        // When/Then - Test location proxy extraction
        let locationEntity = EntityReference.location(startRoom)
        let locationReference = await ProxyReference(from: locationEntity, with: engine)

        let extractedLocationProxy2 = locationReference.locationProxy
        #expect(extractedLocationProxy2 != nil)
        #expect(extractedLocationProxy2?.id == "library")

        let extractedItemProxy2 = locationReference.itemProxy
        #expect(extractedItemProxy2 == nil)

        // When/Then - Test player reference (no proxy extraction methods)
        let playerEntity = EntityReference.player
        let playerReference = await ProxyReference(from: playerEntity, with: engine)

        #expect(playerReference.itemProxy == nil)
        #expect(playerReference.locationProxy == nil)

        // When/Then - Test universal reference (no proxy extraction methods)
        let universalEntity = EntityReference.universal(.sky)
        let universalReference = await ProxyReference(from: universalEntity, with: engine)

        #expect(universalReference.itemProxy == nil)
        #expect(universalReference.locationProxy == nil)
    }

    @Test("ProxyReference entityReference property")
    func testProxyReferenceEntityReferenceProperty() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test item entity reference
        let itemEntity = EntityReference.item(testItem)
        let itemReference = await ProxyReference(from: itemEntity, with: engine)
        let backToItemEntity = itemReference.entityReference

        if case .item(let item) = backToItemEntity {
            #expect(item.id == "testItem")
        } else {
            #expect(Bool(false), "Expected item entity reference")
        }

        // When/Then - Test location entity reference
        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationEntity = EntityReference.location(startRoom)
        let locationReference = await ProxyReference(from: locationEntity, with: engine)
        let backToLocationEntity = locationReference.entityReference

        if case .location(let location) = backToLocationEntity {
            #expect(location.id == "startRoom")
        } else {
            #expect(Bool(false), "Expected location entity reference")
        }

        // When/Then - Test player entity reference
        let playerEntity = EntityReference.player
        let playerReference = await ProxyReference(from: playerEntity, with: engine)
        let backToPlayerEntity = playerReference.entityReference

        #expect(backToPlayerEntity == .player)

        // When/Then - Test universal entity reference
        let universalEntity = EntityReference.universal(.ground)
        let universalReference = await ProxyReference(from: universalEntity, with: engine)
        let backToUniversalEntity = universalReference.entityReference

        if case .universal(let universal) = backToUniversalEntity {
            #expect(universal == .ground)
        } else {
            #expect(Bool(false), "Expected universal entity reference")
        }
    }

    // MARK: - Equality Tests

    @Test("ProxyReference equality comparisons")
    func testProxyReferenceEquality() async throws {
        // Given
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let item1 = Item(
            id: "item1",
            .name("first item"),
            .in(.startRoom)
        )

        let item2 = Item(
            id: "item2",
            .name("second item"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: item1, item2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When - Create references
        let itemRef1a = await ProxyReference(from: .item(item1), with: engine)
        let itemRef1b = await ProxyReference(from: .item(item1), with: engine)
        let itemRef2 = await ProxyReference(from: .item(item2), with: engine)

        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationRef1a = await ProxyReference(from: .location(startRoom), with: engine)
        let locationRef1b = await ProxyReference(from: .location(startRoom), with: engine)
        let locationRef2 = await ProxyReference(from: .location(otherRoom), with: engine)

        let playerRef1 = await ProxyReference(from: .player, with: engine)
        let playerRef2 = await ProxyReference(from: .player, with: engine)

        let universalRef1 = await ProxyReference(from: .universal(.ground), with: engine)
        let universalRef2 = await ProxyReference(from: .universal(.ground), with: engine)
        let universalRef3 = await ProxyReference(from: .universal(.sky), with: engine)

        // Then - Test same item references
        #expect(itemRef1a == itemRef1b)
        #expect(itemRef1a != itemRef2)

        // Then - Test same location references
        #expect(locationRef1a == locationRef1b)
        #expect(locationRef1a != locationRef2)

        // Then - Test player references
        #expect(playerRef1 == playerRef2)

        // Then - Test universal references
        #expect(universalRef1 == universalRef2)
        #expect(universalRef1 != universalRef3)

        // Then - Test different types
        #expect(itemRef1a != locationRef1a)
        #expect(itemRef1a != playerRef1)
        #expect(itemRef1a != universalRef1)
        #expect(locationRef1a != playerRef1)
        #expect(locationRef1a != universalRef1)
        #expect(playerRef1 != universalRef1)
    }

    @Test("ProxyReference hashing")
    func testProxyReferenceHashing() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let itemRef1 = await ProxyReference(from: .item(testItem), with: engine)
        let itemRef2 = await ProxyReference(from: .item(testItem), with: engine)

        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationRef1 = await ProxyReference(from: .location(startRoom), with: engine)
        let locationRef2 = await ProxyReference(from: .location(startRoom), with: engine)

        let playerRef1 = await ProxyReference(from: .player, with: engine)
        let playerRef2 = await ProxyReference(from: .player, with: engine)

        let universalRef1 = await ProxyReference(from: .universal(.ground), with: engine)
        let universalRef2 = await ProxyReference(from: .universal(.ground), with: engine)

        // Then - Equal objects should have equal hash values
        #expect(itemRef1.hashValue == itemRef2.hashValue)
        #expect(locationRef1.hashValue == locationRef2.hashValue)
        #expect(playerRef1.hashValue == playerRef2.hashValue)
        #expect(universalRef1.hashValue == universalRef2.hashValue)
    }

    // MARK: - Comparable Tests

    @Test("ProxyReference comparison")
    func testProxyReferenceComparison() async throws {
        // Given
        let itemA = Item(
            id: "itemA",
            .name("item A"),
            .in(.startRoom)
        )

        let itemB = Item(
            id: "itemB",
            .name("item B"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: itemA, itemB
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let itemRefA = await ProxyReference(from: .item(itemA), with: engine)
        let itemRefB = await ProxyReference(from: .item(itemB), with: engine)

        let universalGround = await ProxyReference(from: .universal(.ground), with: engine)
        let universalSky = await ProxyReference(from: .universal(.sky), with: engine)

        // Then - Test item comparison (based on ID)
        #expect(itemRefA < itemRefB)  // "itemA" < "itemB"

        // Then - Test universal comparison (based on rawValue)
        #expect(universalGround < universalSky)  // "ground" < "sky" in rawValue
    }

    // MARK: - CustomStringConvertible Tests

    @Test("ProxyReference description")
    func testProxyReferenceDescription() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let itemRef = await ProxyReference(from: .item(testItem), with: engine)
        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationRef = await ProxyReference(from: .location(startRoom), with: engine)
        let playerRef = await ProxyReference(from: .player, with: engine)
        let universalRef = await ProxyReference(from: .universal(.ground), with: engine)

        // Then
        #expect(itemRef.description == "testItem")
        #expect(locationRef.description == "startRoom")
        #expect(playerRef.description == ".player")
        #expect(universalRef.description == ".universal(.ground)")
    }

    // MARK: - WithDefiniteArticle Tests

    @Test("ProxyReference withDefiniteArticle")
    func testProxyReferenceWithDefiniteArticle() async throws {
        // Given
        let startRoom = Location(
            id: "library",
            .name("Grand Library"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("ancient tome"),
            .in("library")
        )

        let waterItem = Item(
            id: "water",
            .name("water"),
            .omitArticle,
            .in("library")
        )

        let game = MinimalGame(
            player: Player(in: "library"),
            items: book, waterItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When/Then - Test item with article
        let bookRef = await ProxyReference(from: .item(book), with: engine)
        let bookArticle = await bookRef.withDefiniteArticle
        #expect(bookArticle == "the ancient tome")

        // When/Then - Test item without article
        let waterRef = await ProxyReference(from: .item(waterItem), with: engine)
        let waterArticle = await waterRef.withDefiniteArticle
        #expect(waterArticle == "water")

        // When/Then - Test location
        let locationRef = await ProxyReference(from: .location(startRoom), with: engine)
        let locationArticle = await locationRef.withDefiniteArticle
        #expect(locationArticle == "the library")

        // When/Then - Test player
        let playerRef = await ProxyReference(from: .player, with: engine)
        let playerArticle = await playerRef.withDefiniteArticle
        #expect(playerArticle == "yourself")

        // When/Then - Test universal
        let universalRef = await ProxyReference(from: .universal(.ground), with: engine)
        let universalArticle = await universalRef.withDefiniteArticle
        #expect(universalArticle == "the ground")
    }

    // MARK: - Integration Tests

    @Test("ProxyReference in collections")
    func testProxyReferenceInCollections() async throws {
        // Given
        let item1 = Item(
            id: "item1",
            .name("first item"),
            .in(.startRoom)
        )

        let item2 = Item(
            id: "item2",
            .name("second item"),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item1, item2
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let itemRef1 = await ProxyReference(from: .item(item1), with: engine)
        let itemRef2 = await ProxyReference(from: .item(item2), with: engine)
        let itemRef1Duplicate = await ProxyReference(from: .item(item1), with: engine)
        let startRoom = await engine.gameState.locations[.startRoom]!
        let locationRef = await ProxyReference(from: .location(startRoom), with: engine)
        let playerRef = await ProxyReference(from: .player, with: engine)

        // Then - Test in Set (requires Hashable)
        let referenceSet: Set<ProxyReference> = [
            itemRef1,
            itemRef2,
            itemRef1Duplicate,  // Should be deduplicated
            locationRef,
            playerRef,
        ]

        #expect(referenceSet.count == 4)  // item1, item2, location, player (duplicate removed)

        // Then - Test in Array and sorting
        let referenceArray = [itemRef2, itemRef1, locationRef, playerRef]
        let sortedReferences = referenceArray.sorted()

        // Verify sorted order (items should be sorted by ID, others by type)
        #expect(sortedReferences[0] == itemRef1)  // "item1" < "item2"
        #expect(sortedReferences[1] == itemRef2)
    }

    @Test("ProxyReference consistency across operations")
    func testProxyReferenceConsistencyAcrossOperations() async throws {
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

        // When - Create reference before and after state change
        let coinEntity = EntityReference.item(coin)
        let initialRef = await ProxyReference(from: coinEntity, with: engine)

        // Take the coin (changes its parent)
        try await engine.execute("take coin")

        let afterTakeRef = await ProxyReference(from: coinEntity, with: engine)

        // Then - References should still be equal (they refer to the same item)
        #expect(initialRef == afterTakeRef)
        #expect(initialRef.description == afterTakeRef.description)

        // Note: Since proxies are created fresh each time, we can't directly compare
        // the parent change here without executing the state change through the engine.
        // The important thing is that the references remain consistent.
        #expect(initialRef.itemProxy?.id == afterTakeRef.itemProxy?.id)
    }

    @Test("ProxyReference type safety")
    func testProxyReferenceTypeSafety() async throws {
        // Given
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        let startRoom = await engine.gameState.locations[.startRoom]!
        let itemRef = await ProxyReference(from: .item(testItem), with: engine)
        let locationRef = await ProxyReference(from: .location(startRoom), with: engine)
        let playerRef = await ProxyReference(from: .player, with: engine)
        let universalRef = await ProxyReference(from: .universal(.ground), with: engine)

        // Then - Type checking methods work correctly
        #expect(itemRef.isItem && !itemRef.isLocation && !itemRef.isPlayer && !itemRef.isUniversal)
        #expect(
            !locationRef.isItem && locationRef.isLocation && !locationRef.isPlayer
                && !locationRef.isUniversal)
        #expect(
            !playerRef.isItem && !playerRef.isLocation && playerRef.isPlayer
                && !playerRef.isUniversal)
        #expect(
            !universalRef.isItem && !universalRef.isLocation && !universalRef.isPlayer
                && universalRef.isUniversal)

        // Then - Proxy extraction is type-safe
        #expect(itemRef.itemProxy != nil && itemRef.locationProxy == nil)
        #expect(locationRef.itemProxy == nil && locationRef.locationProxy != nil)
        #expect(playerRef.itemProxy == nil && playerRef.locationProxy == nil)
        #expect(universalRef.itemProxy == nil && universalRef.locationProxy == nil)
    }
}
