import Testing
import Foundation
@testable import GnustoEngine

@Suite("LocationID Tests")
struct LocationIDTests {

    // MARK: - Test Data

    let testID1: LocationID = "westOfHouse"
    let testID2: LocationID = "northOfHouse"
    let testID3: LocationID = "forestClearing"

    // MARK: - Initialization Tests

    @Test("LocationID String Literal Initialization")
    func testStringLiteralInitialization() throws {
        let id: LocationID = "testLocation"
        #expect(id.rawValue == "testLocation")
    }

    @Test("LocationID Raw Value Initialization")
    func testRawValueInitialization() throws {
        let id = LocationID("testLocation")
        #expect(id.rawValue == "testLocation")
    }

    @Test("LocationID Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: LocationID = "location_with-special.chars@123"
        #expect(id.rawValue == "location_with-special.chars@123")
    }

    @Test("LocationID Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: LocationID = "🏰魔法城堡"
        #expect(id.rawValue == "🏰魔法城堡")
    }

    // MARK: - Equality Tests

    @Test("LocationID Equality")
    func testEquality() throws {
        let id1: LocationID = "westOfHouse"
        let id2 = LocationID("westOfHouse")
        let id3: LocationID = "northOfHouse"

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    @Test("LocationID Case Sensitivity")
    func testCaseSensitivity() throws {
        let id1: LocationID = "WestOfHouse"
        let id2: LocationID = "westofhouse"
        let id3: LocationID = "WESTOFHOUSE"

        #expect(id1 != id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    // MARK: - Hashability Tests

    @Test("LocationID Hashability")
    func testHashability() throws {
        let locationDict = [
            LocationID("kitchen"): "A cozy kitchen",
            LocationID("garden"): "A beautiful garden",
            LocationID("library"): "A dusty library"
        ]

        #expect(locationDict[LocationID("kitchen")] == "A cozy kitchen")
        #expect(locationDict[LocationID("garden")] == "A beautiful garden")
        #expect(locationDict[LocationID("library")] == "A dusty library")
        #expect(locationDict[LocationID("nonexistent")] == nil)
    }

    @Test("LocationID Set Operations")
    func testSetOperations() throws {
        let locationSet: Set<LocationID> = [
            "kitchen",
            "garden",
            "library",
            "kitchen" // Duplicate should be ignored
        ]

        #expect(locationSet.count == 3)
        #expect(locationSet.contains("kitchen"))
        #expect(locationSet.contains("garden"))
        #expect(locationSet.contains("library"))
        #expect(!locationSet.contains("nonexistent"))
    }

    // MARK: - Comparable Tests

    @Test("LocationID Comparability")
    func testComparability() throws {
        let id1: LocationID = "apple"
        let id2: LocationID = "banana"
        let id3: LocationID = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("LocationID Sorting")
    func testSorting() throws {
        let unsortedIDs: [LocationID] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [LocationID] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("LocationID Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [LocationID] = ["room10", "room2", "room1", "roomA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [LocationID] = ["room1", "room10", "room2", "roomA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Tests

    @Test("LocationID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs: [LocationID] = [
            "westOfHouse",
            "northOfHouse",
            "forestClearing",
            "location_with-special.chars",
            "🏰魔法城堡",
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(LocationID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("LocationID JSON Representation")
    func testJSONRepresentation() throws {
        let id: LocationID = "westOfHouse"
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // ID types now encode as plain strings
        #expect(jsonString == "\"westOfHouse\"")
    }

    // MARK: - CustomDumpStringConvertible Tests

    @Test("LocationID CustomDumpStringConvertible")
    func testCustomDumpStringConvertible() throws {
        let id: LocationID = "westOfHouse"
        #expect(id.description == ".westOfHouse")
    }

    @Test("LocationID CustomDumpStringConvertible with Special Characters")
    func testCustomDumpStringConvertibleWithSpecialCharacters() throws {
        let id: LocationID = "location_with-special.chars@123"
        #expect(id.description == ".location_with-special.chars@123")
    }

    // MARK: - ExpressibleByStringLiteral Tests

    @Test("LocationID ExpressibleByStringLiteral Usage")
    func testExpressibleByStringLiteral() throws {
        // These should all work due to ExpressibleByStringLiteral
        let locations: [LocationID] = [
            "kitchen",
            "garden",
            "library"
        ]

        #expect(locations.count == 3)
        #expect(locations[0].rawValue == "kitchen")
        #expect(locations[1].rawValue == "garden")
        #expect(locations[2].rawValue == "library")
    }

    // MARK: - Sendable Compliance Tests

    @Test("LocationID Sendable Compliance")
    func testSendableCompliance() async throws {
        let locationIDs: [LocationID] = [
            "kitchen",
            "garden", 
            "library"
        ]

        // Test that LocationID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: LocationID.self) { group in
            for locationID in locationIDs {
                group.addTask {
                    return locationID
                }
            }

            var collectedResults: [LocationID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == locationIDs.count)

        // Verify all original location IDs are present in results
        for originalLocationID in locationIDs {
            #expect(results.contains(originalLocationID))
        }
    }

    // MARK: - Performance Tests

    @Test("LocationID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of LocationIDs
        let locationIDs = (0..<1000).map { LocationID("location\($0)") }
        let locationSet = Set(locationIDs)

        #expect(locationSet.count == 1000)

        // Test lookup performance
        let lookupID: LocationID = "location500"
        #expect(locationSet.contains(lookupID))
    }

    // MARK: - Edge Cases Tests

    @Test("LocationID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10000)
        let id = LocationID(longString)
        #expect(id.rawValue == longString)
    }

    @Test("LocationID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: LocationID = " leadingSpace"
        let id2: LocationID = "trailingSpace "
        let id3: LocationID = " spaces "
        let id4: LocationID = "no\tTab\nNewline"

        #expect(id1.rawValue == " leadingSpace")
        #expect(id2.rawValue == "trailingSpace ")
        #expect(id3.rawValue == " spaces ")
        #expect(id4.rawValue == "no\tTab\nNewline")

        // All should be different
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id3 != id4)
    }

    // MARK: - String Interpolation Tests

    @Test("LocationID String Interpolation")
    func testStringInterpolation() throws {
        let id: LocationID = "kitchen"
        let message = "You are in the \(id)."
        // LocationID doesn't implement CustomStringConvertible, so it shows the full struct representation
        #expect(message == "You are in the .kitchen.")
    }

    // MARK: - Array and Collection Tests

    @Test("LocationID Array Operations")
    func testArrayOperations() throws {
        var locations: [LocationID] = ["kitchen", "garden"]
        locations.append("library")
        locations.insert("attic", at: 1)

        let expectedLocations: [LocationID] = ["kitchen", "attic", "garden", "library"]
        #expect(locations == expectedLocations)
    }

    @Test("LocationID Dictionary Keys")
    func testDictionaryKeys() throws {
        var locationDescriptions: [LocationID: String] = [:]
        locationDescriptions["kitchen"] = "A cozy kitchen"
        locationDescriptions["garden"] = "A beautiful garden"

        #expect(locationDescriptions.keys.count == 2)
        #expect(locationDescriptions.keys.contains("kitchen"))
        #expect(locationDescriptions.keys.contains("garden"))
    }
} 
