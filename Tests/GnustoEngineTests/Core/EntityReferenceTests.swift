import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

/// Comprehensive tests for the `EntityReference` enum.
///
/// Tests all enum cases, Codable conformance, Hashable behavior, and CustomStringConvertible output.
struct EntityReferenceTests {

    // MARK: - Basic Enum Case Tests

    @Test("EntityReference.player can be created")
    func testPlayerCase() throws {
        let playerRef = EntityReference.player

        if case .player = playerRef {
            // Test passes
        } else {
            #expect(Bool(false), "EntityReference should be .player")
        }
    }

    @Test("EntityReference.item can be created with Item")
    func testItemCase() throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let itemRef = EntityReference.item(testItem)

        if case .item(let item) = itemRef {
            #expect(item.id == "testItem")
        } else {
            #expect(Bool(false), "EntityReference should be .item")
        }
    }

    @Test("EntityReference.location can be created with Location")
    func testLocationCase() throws {
        let testLocation = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let locationRef = EntityReference.location(testLocation)

        if case .location(let location) = locationRef {
            #expect(location.id == .startRoom)
        } else {
            #expect(Bool(false), "EntityReference should be .location")
        }
    }

    @Test("EntityReference.universal can be created with Universal")
    func testUniversalCase() throws {
        let universalRef = EntityReference.universal(.ground)

        if case .universal(let universal) = universalRef {
            #expect(universal == .ground)
        } else {
            #expect(Bool(false), "EntityReference should be .universal")
        }
    }

    // MARK: - Equality Tests

    @Test("Same EntityReference cases are equal")
    func testEquality() throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let testLocation = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        #expect(EntityReference.player == EntityReference.player)
        #expect(EntityReference.item(testItem) == EntityReference.item(testItem))
        #expect(EntityReference.location(testLocation) == EntityReference.location(testLocation))
        #expect(EntityReference.universal(.ground) == EntityReference.universal(.ground))
    }

    @Test("Different EntityReference cases are not equal")
    func testInequality() throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let testLocation = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        #expect(EntityReference.player != EntityReference.item(testItem))
        #expect(EntityReference.player != EntityReference.location(testLocation))
        #expect(EntityReference.player != EntityReference.universal(.ground))
        #expect(EntityReference.item(testItem) != EntityReference.location(testLocation))
        #expect(EntityReference.item(testItem) != EntityReference.universal(.ground))
        #expect(EntityReference.location(testLocation) != EntityReference.universal(.ground))
    }

    @Test("Same EntityReference with different associated values are not equal")
    func testDifferentAssociatedValues() throws {
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

        let location1 = Location(
            id: "room1",
            .name("First Room"),
            .inherentlyLit
        )

        let location2 = Location(
            id: "room2",
            .name("Second Room"),
            .inherentlyLit
        )

        #expect(EntityReference.item(item1) != EntityReference.item(item2))
        #expect(EntityReference.location(location1) != EntityReference.location(location2))
        #expect(EntityReference.universal(.ground) != EntityReference.universal(.sky))
    }

    // MARK: - Hashable Tests

    @Test("EntityReference conforms to Hashable")
    func testHashable() throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let testLocation = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let references: Set<EntityReference> = [
            .player,
            .item(testItem),
            .location(testLocation),
            .universal(.ground),
        ]

        #expect(references.count == 4)
        #expect(references.contains(.player))
        #expect(references.contains(.universal(.ground)))
    }

    @Test("Same EntityReference instances have same hash value")
    func testHashConsistency() throws {
        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let ref1 = EntityReference.item(testItem)
        let ref2 = EntityReference.item(testItem)

        #expect(ref1.hashValue == ref2.hashValue)
        #expect(ref1 == ref2)
    }

    // MARK: - Codable Tests

    @Test("All EntityReference cases are Codable")
    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .in(.startRoom)
        )

        let testLocation = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let testCases: [EntityReference] = [
            .player,
            .item(testItem),
            .location(testLocation),
            .universal(.ground),
            .universal(.sky),
        ]

        for reference in testCases {
            let encodedData = try encoder.encode(reference)
            let decodedReference = try decoder.decode(EntityReference.self, from: encodedData)
            #expect(decodedReference == reference, "Failed encoding/decoding for \(reference)")
        }
    }

    @Test("Complex EntityReference cases encode and decode correctly")
    func testComplexCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let complexItem = Item(
            id: "complexItem",
            .name("complex test item"),
            .description("A complex item for testing"),
            .isTakable,
            .in("complexRoom")
        )

        let complexReference = EntityReference.item(complexItem)

        let encodedData = try encoder.encode(complexReference)
        let decodedReference = try decoder.decode(EntityReference.self, from: encodedData)

        #expect(decodedReference == complexReference)

        if case .item(let decodedItem) = decodedReference {
            #expect(decodedItem.id == "complexItem")
        } else {
            #expect(Bool(false), "Decoded reference should be .item")
        }
    }

    // MARK: - CustomStringConvertible Tests

    @Test("EntityReference.player description is correct")
    func testPlayerDescription() throws {
        let playerRef = EntityReference.player
        #expect(playerRef.description == "player")
    }

    @Test("EntityReference.item description shows item ID")
    func testItemDescription() throws {
        let testItem = Item(
            id: "magicLamp",
            .name("magic lamp"),
            .in(.startRoom)
        )

        let itemRef = EntityReference.item(testItem)
        #expect(itemRef.description == ".magicLamp")
    }

    @Test("EntityReference.location description shows location ID")
    func testLocationDescription() throws {
        let testLocation = Location(
            id: "enchantedForest",
            .name("Enchanted Forest"),
            .inherentlyLit
        )

        let locationRef = EntityReference.location(testLocation)
        #expect(locationRef.description == ".enchantedForest")
    }

    @Test("EntityReference.universal description shows universal object")
    func testUniversalDescription() throws {
        let groundRef = EntityReference.universal(.ground)
        let skyRef = EntityReference.universal(.sky)

        #expect(groundRef.description == "ground")
        #expect(skyRef.description == "sky")
    }

    // MARK: - Associated Values Tests

    @Test("Item associated values work correctly")
    func testItemAssociatedValues() throws {
        let testItem = Item(
            id: "testSword",
            .name("enchanted sword"),
            .description("A magical blade"),
            .isTakable,
            .in("armory")
        )

        let itemRef = EntityReference.item(testItem)

        if case .item(let extractedItem) = itemRef {
            #expect(extractedItem.id == "testSword")
        } else {
            #expect(Bool(false), "Reference should be .item")
        }
    }

    @Test("Location associated values work correctly")
    func testLocationAssociatedValues() throws {
        let testLocation = Location(
            id: "mysticalCave",
            .name("Mystical Cave"),
            .description("A cave filled with ancient magic"),
            .inherentlyLit
        )

        let locationRef = EntityReference.location(testLocation)

        if case .location(let extractedLocation) = locationRef {
            #expect(extractedLocation.id == "mysticalCave")
        } else {
            #expect(Bool(false), "Reference should be .location")
        }
    }

    @Test("Universal associated values work correctly")
    func testUniversalAssociatedValues() throws {
        let groundRef = EntityReference.universal(.ground)
        let skyRef = EntityReference.universal(.sky)

        if case .universal(let extractedUniversal) = groundRef {
            #expect(extractedUniversal == .ground)
        } else {
            #expect(Bool(false), "Reference should be .universal(.ground)")
        }

        if case .universal(let extractedUniversal) = skyRef {
            #expect(extractedUniversal == .sky)
        } else {
            #expect(Bool(false), "Reference should be .universal(.sky)")
        }
    }

    // MARK: - Edge Cases

    @Test("EntityReference works in collections")
    func testInCollections() throws {
        let testItem = Item(
            id: "collectionItem",
            .name("collection item"),
            .in(.startRoom)
        )

        let testLocation = Location(
            id: "collectionRoom",
            .name("Collection Room"),
            .inherentlyLit
        )

        let references: [EntityReference] = [
            .player,
            .item(testItem),
            .location(testLocation),
            .universal(.ground),
        ]

        #expect(references.count == 4)
        #expect(references.contains(.player))
        #expect(references.contains(.item(testItem)))
        #expect(references.contains(.location(testLocation)))
        #expect(references.contains(.universal(.ground)))
    }

    @Test("EntityReference pattern matching works correctly")
    func testPatternMatching() throws {
        let testItem = Item(
            id: "patternItem",
            .name("pattern item"),
            .in(.startRoom)
        )

        let references: [EntityReference] = [
            .player,
            .item(testItem),
            .location(Location(id: .startRoom, .name("Test Room"), .inherentlyLit)),
            .universal(.ground),
        ]

        var playerCount = 0
        var itemCount = 0
        var locationCount = 0
        var universalCount = 0

        for reference in references {
            switch reference {
            case .player:
                playerCount += 1
            case .item:
                itemCount += 1
            case .location:
                locationCount += 1
            case .universal:
                universalCount += 1
            }
        }

        #expect(playerCount == 1)
        #expect(itemCount == 1)
        #expect(locationCount == 1)
        #expect(universalCount == 1)
    }

    @Test("EntityReference maintains type safety")
    func testTypeSafety() throws {
        // This test verifies that the enum enforces type safety at compile time
        // by ensuring we can only create valid EntityReference cases

        let item = Item(id: "safetyItem", .name("safety item"), .in(.startRoom))
        let location = Location(id: "safetyRoom", .name("Safety Room"), .inherentlyLit)

        // These should all compile and work correctly
        let validReferences: [EntityReference] = [
            .player,
            .item(item),
            .location(location),
            .universal(.ground),
            .universal(.sky),
        ]

        #expect(validReferences.count == 5)

        // Verify each reference maintains its type information
        for reference in validReferences {
            switch reference {
            case .player:
                #expect(reference.description == "player")
            case .item(let associatedItem):
                #expect(associatedItem.id == "safetyItem")
            case .location(let associatedLocation):
                #expect(associatedLocation.id == "safetyRoom")
            case .universal(let universal):
                #expect(universal == .ground || universal == .sky)
            }
        }
    }
}
