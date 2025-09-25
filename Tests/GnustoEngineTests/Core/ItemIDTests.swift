import Foundation
@testable import GnustoEngine
import Testing

@Suite("ItemID Tests")
struct ItemIDTests {

    // MARK: - Test Data

    let testID1: ItemID = "brassLantern"
    let testID2: ItemID = "rustyKnife"
    let testID3: ItemID = "silverCoin"

    // MARK: - Initialization Tests

    @Test("ItemID String Literal Initialization")
    func testStringLiteralInitialization() throws {
        let id: ItemID = "testItem"
        #expect(id.rawValue == "testItem")
    }

    @Test("ItemID Raw Value Initialization")
    func testRawValueInitialization() throws {
        let id = ItemID("testItem")
        #expect(id.rawValue == "testItem")
    }

    @Test("ItemID Initialization with Special Characters")
    func testSpecialCharacterInitialization() throws {
        let id: ItemID = "item_with-special.chars@123"
        #expect(id.rawValue == "item_with-special.chars@123")
    }

    @Test("ItemID Initialization with Unicode")
    func testUnicodeInitialization() throws {
        let id: ItemID = "🗝️魔法钥匙"
        #expect(id.rawValue == "🗝️魔法钥匙")
    }

    // MARK: - Equality Tests

    @Test("ItemID Equality")
    func testEquality() throws {
        let id1: ItemID = "brassLantern"
        let id2 = ItemID("brassLantern")
        let id3: ItemID = "rustyKnife"

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id2 != id3)
    }

    @Test("ItemID is case-insensitive")
    func testCaseSensitivity() throws {
        let id1: ItemID = "BrassLantern"
        let id2: ItemID = "brasslantern"
        let id3: ItemID = "BRASSLANTERN"

        #expect(id1 == id2)
        #expect(id1 == id3)
        #expect(id2 == id3)
    }

    // MARK: - Hashability Tests

    @Test("ItemID Hashability")
    func testHashability() throws {
        let itemDict = [
            ItemID("lantern"): "A brass lantern",
            ItemID("knife"): "A rusty knife",
            ItemID("coin"): "A silver coin",
        ]

        #expect(itemDict[ItemID("lantern")] == "A brass lantern")
        #expect(itemDict[ItemID("knife")] == "A rusty knife")
        #expect(itemDict[ItemID("coin")] == "A silver coin")
        #expect(itemDict[ItemID("nonexistent")] == nil)
    }

    @Test("ItemID Set Operations")
    func testSetOperations() throws {
        let itemSet: Set<ItemID> = [
            "lantern",
            "knife",
            "coin",
            "lantern", // Duplicate should be ignored
        ]

        #expect(itemSet.count == 3)
        #expect(itemSet.contains("lantern"))
        #expect(itemSet.contains("knife"))
        #expect(itemSet.contains("coin"))
        #expect(!itemSet.contains("nonexistent"))
    }

    // MARK: - Comparable Tests

    @Test("ItemID Comparability")
    func testComparability() throws {
        let id1: ItemID = "apple"
        let id2: ItemID = "banana"
        let id3: ItemID = "cherry"

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("ItemID Sorting")
    func testSorting() throws {
        let unsortedIDs: [ItemID] = ["zebra", "apple", "monkey", "banana"]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder: [ItemID] = ["apple", "banana", "monkey", "zebra"]
        #expect(sortedIDs == expectedOrder)
    }

    @Test("ItemID Sorting with Numbers and Letters")
    func testSortingWithNumbersAndLetters() throws {
        let unsortedIDs: [ItemID] = ["item10", "item2", "item1", "itemA"]
        let sortedIDs = unsortedIDs.sorted()

        // String sorting: numbers come before letters, but "10" < "2" lexicographically
        let expectedOrder: [ItemID] = ["item1", "item10", "item2", "itemA"]
        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Tests

    @Test("ItemID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs: [ItemID] = [
            "brassLantern",
            "rustyKnife",
            "silverCoin",
            "item_with-special.chars",
            "🗝️魔法钥匙",
        ]

        let encoder = JSONEncoder.sorted(.prettyPrinted)
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(ItemID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("ItemID JSON Representation")
    func testJSONRepresentation() throws {
        let id: ItemID = "brassLantern"
        let encoder = JSONEncoder.sorted()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // ID types now encode as plain strings
        #expect(jsonString == "\"brassLantern\"")
    }

    // MARK: - CustomDumpStringConvertible Tests

    @Test("ItemID CustomDumpStringConvertible")
    func testCustomDumpStringConvertible() throws {
        let id: ItemID = "brassLantern"
        #expect(id.description == ".brassLantern")
    }

    @Test("ItemID CustomDumpStringConvertible with Special Characters")
    func testCustomDumpStringConvertibleWithSpecialCharacters() throws {
        let id: ItemID = "item_with-special.chars@123"
        #expect(id.description == ".item_with-special.chars@123")
    }

    // MARK: - CustomStringConvertible Tests

    @Test("ItemID CustomStringConvertible")
    func testCustomStringConvertible() throws {
        let id: ItemID = "brassLantern"
        #expect(id.description == ".brassLantern")
        #expect("\(id)" == ".brassLantern")
    }

    // MARK: - Sendable Compliance Tests

    @Test("ItemID Sendable Compliance")
    func testSendableCompliance() async throws {
        let itemIDs: [ItemID] = [
            "lantern",
            "knife",
            "coin",
        ]

        // Test that ItemID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: ItemID.self) { group in
            for itemID in itemIDs {
                group.addTask {
                    itemID
                }
            }

            var collectedResults: [ItemID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == itemIDs.count)

        // Verify all original item IDs are present in results
        for originalItemID in itemIDs {
            #expect(results.contains(originalItemID))
        }
    }

    // MARK: - Performance Tests

    @Test("ItemID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of ItemIDs
        let itemIDs = (0..<1_000).map { ItemID("item\($0)") }
        let itemSet = Set(itemIDs)

        #expect(itemSet.count == 1_000)

        // Test lookup performance
        let lookupID: ItemID = "item500"
        #expect(itemSet.contains(lookupID))
    }

    // MARK: - Edge Cases Tests

    @Test("ItemID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10_000)
        let id = ItemID(longString)
        #expect(id.rawValue == longString)
    }

    @Test("ItemID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1: ItemID = " leadingSpace"
        let id2: ItemID = "trailingSpace "
        let id3: ItemID = " spaces "
        let id4: ItemID = "no\tTab\nNewline"

        #expect(id1.rawValue == " leadingSpace")
        #expect(id2.rawValue == "trailingSpace ")
        #expect(id3.rawValue == " spaces ")
        #expect(id4.rawValue == "no\tTab\nNewline")

        // All should be different
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id3 != id4)
    }
}
