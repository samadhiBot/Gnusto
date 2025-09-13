import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("RangeReplaceableCollection Extension Tests")
struct RangeReplaceableCollectionExtensionTests {

    // MARK: - append(_:) Tests

    @Test("append adds non-nil optional elements to collection")
    func testAppendNonNilOptional() {
        var numbers: [Int] = [1, 2, 3]
        let optionalFour: Int? = 4

        numbers.append(optionalFour)

        #expect(numbers == [1, 2, 3, 4])
    }

    @Test("append ignores nil optional elements")
    func testAppendNilOptional() {
        var numbers: [Int] = [1, 2, 3]
        let optionalNil: Int? = nil

        numbers.append(optionalNil)

        #expect(numbers == [1, 2, 3])
    }

    @Test("append works with empty collections")
    func testAppendToEmptyCollection() {
        var emptyNumbers: [Int] = []
        let optionalOne: Int? = 1
        let optionalNil: Int? = nil

        emptyNumbers.append(optionalOne)
        #expect(emptyNumbers == [1])

        emptyNumbers.append(optionalNil)
        #expect(emptyNumbers == [1])
    }

    @Test("append maintains order of elements")
    func testAppendMaintainsOrder() {
        var numbers: [Int] = [1, 2]
        let optionalThree: Int? = 3
        let optionalFour: Int? = 4
        let optionalNil: Int? = nil
        let optionalFive: Int? = 5

        numbers.append(optionalThree)
        numbers.append(optionalFour)
        numbers.append(optionalNil)
        numbers.append(optionalFive)

        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("append works with string collections")
    func testAppendWithStrings() {
        var words: [String] = ["hello", "world"]
        let optionalExclamation: String? = "!"
        let optionalNil: String? = nil
        let optionalGoodbye: String? = "goodbye"

        words.append(optionalExclamation)
        words.append(optionalNil)
        words.append(optionalGoodbye)

        #expect(words == ["hello", "world", "!", "goodbye"])
    }

    @Test("append works with custom types")
    func testAppendWithCustomTypes() {
        struct Person {
            let name: String
        }

        var people: [Person] = []
        let optionalAlice: Person? = Person(name: "Alice")
        let optionalNil: Person? = nil
        let optionalBob: Person? = Person(name: "Bob")

        people.append(optionalAlice)
        people.append(optionalNil)
        people.append(optionalBob)

        #expect(people.count == 2)
        #expect(people[0].name == "Alice")
        #expect(people[1].name == "Bob")
    }

    @Test("append multiple nil values in sequence")
    func testAppendMultipleNilValues() {
        var numbers: [Int] = [1, 2, 3]
        let originalCount = numbers.count

        for _ in 0..<10 {
            let optionalNil: Int? = nil
            numbers.append(optionalNil)
        }

        #expect(numbers == [1, 2, 3])
        #expect(numbers.count == originalCount)
    }

    @Test("append with alternating nil and non-nil values")
    func testAppendAlternatingNilAndNonNil() {
        var numbers: [Int] = []

        for i in 1...5 {
            let nonNilValue: Int? = i
            let nilValue: Int? = nil

            numbers.append(nonNilValue)
            numbers.append(nilValue)
        }

        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("append works with different RangeReplaceableCollection types")
    func testAppendWithDifferentCollectionTypes() {
        // Test with Array
        var array: [Int] = [1]
        let optionalTwo: Int? = 2
        array.append(optionalTwo)
        #expect(array == [1, 2])

        // Test with ContiguousArray
        var contiguousArray = ContiguousArray<String>(["a"])
        let optionalB: String? = "b"
        contiguousArray.append(optionalB)
        #expect(Array(contiguousArray) == ["a", "b"])

        // Test with ArraySlice
        var arraySlice = ArraySlice([10, 20])
        let optionalThirty: Int? = 30
        arraySlice.append(optionalThirty)
        #expect(Array(arraySlice) == [10, 20, 30])
    }

    @Test("append performance with large number of operations")
    func testAppendPerformance() {
        var numbers: [Int] = []

        // Append 1000 elements, alternating between valid and nil values
        for i in 1...1000 {
            let value: Int? = i % 2 == 0 ? i : nil
            numbers.append(value)
        }

        // Should only contain even numbers from 2 to 1000
        let expectedNumbers = Array(stride(from: 2, through: 1000, by: 2))
        #expect(numbers == expectedNumbers)
        #expect(numbers.count == 500)
    }

    @Test("append preserves collection capacity behavior")
    func testAppendPreservesCapacityBehavior() {
        var numbers: [Int] = []
        numbers.reserveCapacity(10)
        let initialCapacity = numbers.capacity

        // Append elements within reserved capacity
        for i in 1...5 {
            let optionalValue: Int? = i
            numbers.append(optionalValue)
        }

        // Capacity should not have changed (assuming it was sufficient)
        #expect(numbers.capacity >= initialCapacity)
        #expect(numbers == [1, 2, 3, 4, 5])
    }

    @Test("append works with optional chaining results")
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
            values.append(container?.value)
        }

        #expect(values == [1, 2, 3])
    }
}
