import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Collection Extensions")
struct CollectionExtensionTests {

    // MARK: - isNotEmpty Tests

    @Test("isNotEmpty returns true for non-empty collections")
    func testIsNotEmptyWithNonEmptyCollections() {
        // Array
        let nonEmptyArray = [1, 2, 3]
        #expect(nonEmptyArray.isNotEmpty == true)

        // String
        let nonEmptyString = "hello"
        #expect(nonEmptyString.isNotEmpty == true)

        // Set
        let nonEmptySet: Set<Int> = [1, 2, 3]
        #expect(nonEmptySet.isNotEmpty == true)

        // Dictionary
        let nonEmptyDict = ["key": "value"]
        #expect(nonEmptyDict.isNotEmpty == true)
    }

    @Test("isNotEmpty returns false for empty collections")
    func testIsNotEmptyWithEmptyCollections() {
        // Array
        let emptyArray: [Int] = []
        #expect(emptyArray.isNotEmpty == false)

        // String
        let emptyString = ""
        #expect(emptyString.isNotEmpty == false)

        // Set
        let emptySet: Set<Int> = []
        #expect(emptySet.isNotEmpty == false)

        // Dictionary
        let emptyDict: [String: String] = [:]
        #expect(emptyDict.isNotEmpty == false)
    }

    // MARK: - intersects Tests

    @Test("intersects returns true when collections have common elements")
    func testIntersectsWithCommonElements() {
        let array1 = [1, 2, 3, 4]
        let array2 = [3, 4, 5, 6]

        #expect(array1.intersects(array2) == true)
        #expect(array2.intersects(array1) == true)
    }

    @Test("intersects returns false when collections have no common elements")
    func testIntersectsWithNoCommonElements() {
        let array1 = [1, 2, 3]
        let array2 = [4, 5, 6]

        #expect(array1.intersects(array2) == false)
        #expect(array2.intersects(array1) == false)
    }

    @Test("intersects returns false when one collection is empty")
    func testIntersectsWithEmptyCollection() {
        let nonEmptyArray = [1, 2, 3]
        let emptyArray: [Int] = []

        #expect(nonEmptyArray.intersects(emptyArray) == false)
        #expect(emptyArray.intersects(nonEmptyArray) == false)
    }

    @Test("intersects returns false when both collections are empty")
    func testIntersectsWithBothEmpty() {
        let emptyArray1: [Int] = []
        let emptyArray2: [Int] = []

        #expect(emptyArray1.intersects(emptyArray2) == false)
    }

    @Test("intersects works with identical collections")
    func testIntersectsWithIdenticalCollections() {
        let array1 = [1, 2, 3]
        let array2 = [1, 2, 3]

        #expect(array1.intersects(array2) == true)
    }

    @Test("intersects works with single element intersection")
    func testIntersectsWithSingleElementIntersection() {
        let array1 = [1, 2, 3]
        let array2 = [4, 5, 3, 6]

        #expect(array1.intersects(array2) == true)
    }

    @Test("intersects works with strings")
    func testIntersectsWithStrings() {
        let strings1 = ["apple", "banana", "cherry"]
        let strings2 = ["cherry", "date", "elderberry"]

        #expect(strings1.intersects(strings2) == true)

        let strings3 = ["fig", "grape"]
        #expect(strings1.intersects(strings3) == false)
    }

    @Test("intersects works with sets")
    func testIntersectsWithSets() {
        let set1: Set<Int> = [1, 2, 3]
        let set2: Set<Int> = [3, 4, 5]

        #expect(set1.intersects(set2) == true)

        let set3: Set<Int> = [6, 7, 8]
        #expect(set1.intersects(set3) == false)
    }

    @Test("intersects works with different collection types")
    func testIntersectsWithDifferentCollectionTypes() {
        let array = [1, 2, 3]
        let set: Set<Int> = [3, 4, 5]

        #expect(array.intersects(set) == true)
        #expect(set.intersects(array) == true)
    }

    @Test("intersects handles duplicates correctly")
    func testIntersectsWithDuplicates() {
        let array1 = [1, 1, 2, 2, 3]
        let array2 = [3, 3, 4, 4, 5]

        #expect(array1.intersects(array2) == true)

        let array3 = [6, 6, 7, 7]
        #expect(array1.intersects(array3) == false)
    }
}
