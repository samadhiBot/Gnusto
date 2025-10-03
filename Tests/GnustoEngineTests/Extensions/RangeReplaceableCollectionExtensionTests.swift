import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("RangeReplaceableCollection Extension Tests")
struct RangeReplaceableCollectionExtensionTests {

    // MARK: - appendIfPresent(_:) Tests

    @Test("appendIfPresent adds non-nil optional elements to collection")
    func testAppendNonNilOptional() {
        var numbers: [Int] = [1, 2, 3]
        let optionalFour: Int? = 4

        numbers.appendIfPresent(optionalFour)

        #expect(numbers == [1, 2, 3, 4])
    }

    @Test("appendIfPresent ignores nil optional elements")
    func testAppendNilOptional() {
        var numbers: [Int] = [1, 2, 3]
        let optionalNil: Int? = nil

        numbers.appendIfPresent(optionalNil)

        #expect(numbers == [1, 2, 3])
    }

    @Test("appendIfPresent works with empty collections")
    func testAppendToEmptyCollection() {
        var emptyNumbers: [Int] = []
        let optionalOne: Int? = 1
        let optionalNil: Int? = nil

        emptyNumbers.appendIfPresent(optionalOne)
        #expect(emptyNumbers == [1])

        emptyNumbers.appendIfPresent(optionalNil)
        #expect(emptyNumbers == [1])
    }

    @Test("appendIfPresent maintains order of elements")
    func testAppendMaintainsOrder() {
        var numbers: [Int] = [1, 2]
        let optionalThree: Int? = 3
        let optionalFour: Int? = 4
        let optionalNil: Int? = nil
        let optionalFive: Int? = 5

        numbers.appendIfPresent(optionalThree)
        numbers.appendIfPresent(optionalFour)
        numbers.appendIfPresent(optionalNil)
        numbers.appendIfPresent(optionalFive)

        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("appendIfPresent works with string collections")
    func testAppendWithStrings() {
        var words: [String] = ["hello", "world"]
        let optionalExclamation: String? = "!"
        let optionalNil: String? = nil
        let optionalGoodbye: String? = "goodbye"

        words.appendIfPresent(optionalExclamation)
        words.appendIfPresent(optionalNil)
        words.appendIfPresent(optionalGoodbye)

        #expect(words == ["hello", "world", "!", "goodbye"])
    }

    @Test("appendIfPresent works with custom types")
    func testAppendWithCustomTypes() {
        struct Person {
            let name: String
        }

        var people: [Person] = []
        let optionalAlice: Person? = Person(name: "Alice")
        let optionalNil: Person? = nil
        let optionalBob: Person? = Person(name: "Bob")

        people.appendIfPresent(optionalAlice)
        people.appendIfPresent(optionalNil)
        people.appendIfPresent(optionalBob)

        #expect(people.count == 2)
        #expect(people[0].name == "Alice")
        #expect(people[1].name == "Bob")
    }

    @Test("appendIfPresent multiple nil values in sequence")
    func testAppendMultipleNilValues() {
        var numbers: [Int] = [1, 2, 3]
        let originalCount = numbers.count

        for _ in 0..<10 {
            let optionalNil: Int? = nil
            numbers.appendIfPresent(optionalNil)
        }

        #expect(numbers == [1, 2, 3])
        #expect(numbers.count == originalCount)
    }

    @Test("appendIfPresent with alternating nil and non-nil values")
    func testAppendAlternatingNilAndNonNil() {
        var numbers: [Int] = []

        for i in 1...5 {
            let nonNilValue: Int? = i
            let nilValue: Int? = nil

            numbers.appendIfPresent(nonNilValue)
            numbers.appendIfPresent(nilValue)
        }

        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("appendIfPresent works with different RangeReplaceableCollection types")
    func testAppendWithDifferentCollectionTypes() {
        // Test with Array
        var array: [Int] = [1]
        let optionalTwo: Int? = 2
        array.appendIfPresent(optionalTwo)
        #expect(array == [1, 2])

        // Test with ContiguousArray
        var contiguousArray = ContiguousArray<String>(["a"])
        let optionalB: String? = "b"
        contiguousArray.appendIfPresent(optionalB)
        #expect(Array(contiguousArray) == ["a", "b"])

        // Test with ArraySlice
        var arraySlice = ArraySlice([10, 20])
        let optionalThirty: Int? = 30
        arraySlice.appendIfPresent(optionalThirty)
        #expect(Array(arraySlice) == [10, 20, 30])
    }

    @Test("appendIfPresent performance with large number of operations")
    func testAppendPerformance() {
        var numbers: [Int] = []

        // Append 1000 elements, alternating between valid and nil values
        for i in 1...1_000 {
            let value: Int? = i % 2 == 0 ? i : nil
            numbers.appendIfPresent(value)
        }

        // Should only contain even numbers from 2 to 1000
        let expectedNumbers = Array(stride(from: 2, through: 1_000, by: 2))
        #expect(numbers == expectedNumbers)
        #expect(numbers.count == 500)
    }

    @Test("appendIfPresent preserves collection capacity behavior")
    func testAppendPreservesCapacityBehavior() {
        var numbers: [Int] = []
        numbers.reserveCapacity(10)
        let initialCapacity = numbers.capacity

        // Append elements within reserved capacity
        for i in 1...5 {
            let optionalValue: Int? = i
            numbers.appendIfPresent(optionalValue)
        }

        // Capacity should not have changed (assuming it was sufficient)
        #expect(numbers.capacity >= initialCapacity)
        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("appendIfPresent works with optional chaining results")
    func testAppendWithOptionalChainingResults() {
        struct Container {
            let value: Int
        }

        let containers: [Container?] = [
            Container(value: 1),
            nil,
            Container(value: 2),
            nil,
            Container(value: 3),
        ]

        var values: [Int] = []

        for container in containers {
            values.appendIfPresent(container?.value)
        }

        #expect(values == [1, 2, 3])
    }
}
