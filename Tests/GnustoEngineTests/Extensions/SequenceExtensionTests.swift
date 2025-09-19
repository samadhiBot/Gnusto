import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Sequence Extension Tests")
struct SequenceExtensionTests {

    // MARK: - asyncCompactMap Tests

    @Test("asyncCompactMap transforms and filters elements correctly")
    func testAsyncCompactMapBasicFunctionality() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = await numbers.asyncCompactMap { number in
            await Task.yield()  // Simulate async work
            return number > 3 ? number * 2 : nil
        }

        #expect(result == [8, 10])
    }

    @Test("asyncCompactMap handles empty sequence")
    func testAsyncCompactMapEmptySequence() async throws {
        let empty: [Int] = []

        let result = await empty.asyncCompactMap { number in
            number * 2
        }

        #expect(result.isEmpty)
    }

    @Test("asyncCompactMap filters out all nil values")
    func testAsyncCompactMapAllNil() async throws {
        let numbers = [1, 2, 3]

        let result = await numbers.asyncCompactMap { _ in
            nil as Int?
        }

        #expect(result.isEmpty)
    }

    @Test("asyncCompactMap propagates errors from transform closure")
    func testAsyncCompactMapErrorPropagation() async {
        let numbers = [1, 2, 3]

        struct TestError: Error, Equatable {}

        await #expect(throws: TestError.self) {
            try await numbers.asyncCompactMap { number in
                if number == 2 {
                    throw TestError()
                }
                return number * 2
            }
        }
    }

    @Test("asyncCompactMap maintains order of elements")
    func testAsyncCompactMapOrder() async throws {
        let strings = ["1", "not_a_number", "3", "4", "not_a_number_either", "6"]

        let result = await strings.asyncCompactMap { string in
            await Task.yield()
            return Int(string)
        }

        #expect(result == [1, 3, 4, 6])
    }

    // MARK: - asyncFilter Tests

    @Test("asyncFilter includes elements that satisfy predicate")
    func testAsyncFilterBasicFunctionality() async throws {
        let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        let result = await numbers.asyncFilter { number in
            await Task.yield()  // Simulate async work
            return number % 2 == 0
        }

        #expect(result == [2, 4, 6, 8, 10])
    }

    @Test("asyncFilter handles empty sequence")
    func testAsyncFilterEmptySequence() async throws {
        let empty: [Int] = []

        let result = await empty.asyncFilter { _ in
            return true
        }

        #expect(result.isEmpty)
    }

    @Test("asyncFilter excludes all elements when predicate returns false")
    func testAsyncFilterAllExcluded() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = await numbers.asyncFilter { _ in
            return false
        }

        #expect(result.isEmpty)
    }

    @Test("asyncFilter includes all elements when predicate returns true")
    func testAsyncFilterAllIncluded() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = await numbers.asyncFilter { _ in
            return true
        }

        #expect(result == numbers)
    }

    @Test("asyncFilter propagates errors from predicate closure")
    func testAsyncFilterErrorPropagation() async {
        let numbers = [1, 2, 3]

        struct TestError: Error, Equatable {}

        await #expect(throws: TestError.self) {
            try await numbers.asyncFilter { number in
                if number == 2 {
                    throw TestError()
                }
                return true
            }
        }
    }

    @Test("asyncFilter maintains original order")
    func testAsyncFilterOrder() async throws {
        let numbers = [5, 1, 8, 2, 9, 3, 7, 4, 6]

        let result = await numbers.asyncFilter { number in
            await Task.yield()
            return number > 5
        }

        #expect(result == [8, 9, 7, 6])
    }

    // MARK: - asyncMap Tests

    @Test("asyncMap transforms all elements")
    func testAsyncMapBasicFunctionality() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = await numbers.asyncMap { number in
            await Task.yield()  // Simulate async work
            return number * 2
        }

        #expect(result == [2, 4, 6, 8, 10])
    }

    @Test("asyncMap handles empty sequence")
    func testAsyncMapEmptySequence() async throws {
        let empty: [Int] = []

        let result = await empty.asyncMap { number in
            return number * 2
        }

        #expect(result.isEmpty)
    }

    @Test("asyncMap can change element type")
    func testAsyncMapTypeTransformation() async throws {
        let numbers = [1, 2, 3]

        let result = await numbers.asyncMap { number in
            await Task.yield()
            return "Number: \(number)"
        }

        #expect(result == ["Number: 1", "Number: 2", "Number: 3"])
    }

    @Test("asyncMap propagates errors from transform closure")
    func testAsyncMapErrorPropagation() async {
        let numbers = [1, 2, 3]

        struct TestError: Error, Equatable {}

        await #expect(throws: TestError.self) {
            try await numbers.asyncMap { number in
                if number == 2 {
                    throw TestError()
                }
                return number * 2
            }
        }
    }

    @Test("asyncMap maintains original order")
    func testAsyncMapOrder() async throws {
        let numbers = [3, 1, 4, 1, 5, 9, 2, 6]

        let result = await numbers.asyncMap { number in
            await Task.yield()
            return number * 10
        }

        #expect(result == [30, 10, 40, 10, 50, 90, 20, 60])
    }

    // MARK: - contains(where:) Tests

    @Test("contains(where:) returns true when element exists")
    func testContainsWhereElementExists() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = try await numbers.contains { number in
            await Task.yield()  // Simulate async work
            return number > 3
        }

        #expect(result == true)
    }

    @Test("contains(where:) returns false when no element matches")
    func testContainsWhereNoMatch() async throws {
        let numbers = [1, 2, 3, 4, 5]

        let result = try await numbers.contains { number in
            await Task.yield()
            return number > 10
        }

        #expect(result == false)
    }

    @Test("contains(where:) returns false for empty sequence")
    func testContainsWhereEmptySequence() async throws {
        let empty: [Int] = []

        let result = empty.contains { _ in
            return true
        }

        #expect(result == false)
    }

    @Test("contains(where:) stops at first match")
    func testContainsWhereShortCircuits() async throws {
        let numbers = [1, 2, 3, 4, 5]
        var callCount = 0

        let result = try await numbers.contains { number in
            callCount += 1
            await Task.yield()
            return number == 3
        }

        #expect(result == true)
        #expect(callCount == 3)  // Should stop after finding 3
    }

    @Test("contains(where:) propagates errors from predicate closure")
    func testContainsWhereErrorPropagation() {
        let numbers = [1, 2, 3]

        struct TestError: Error, Equatable {}

        #expect(throws: TestError.self) {
            try numbers.contains { number in
                if number == 2 {
                    throw TestError()
                }
                return false
            }
        }
    }

    @Test("contains(where:) works with complex predicates")
    func testContainsWhereComplexPredicate() async throws {
        let strings = ["apple", "banana", "cherry", "date"]

        let result = try await strings.contains { string in
            await Task.yield()
            return string.count > 5 && string.hasPrefix("b")
        }

        #expect(result == true)  // "banana" matches
    }

    // MARK: - Performance and Edge Case Tests

    @Test("All async methods work with large sequences")
    func testLargeSequencePerformance() async throws {
        let largeArray = Array(1...1000)

        // Test asyncMap
        let mapped = await largeArray.asyncMap { $0 * 2 }
        #expect(mapped.count == 1000)
        #expect(mapped.first == 2)
        #expect(mapped.last == 2000)

        // Test asyncFilter
        let filtered = await largeArray.asyncFilter { $0 % 100 == 0 }
        #expect(filtered == [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000])

        // Test asyncCompactMap
        let compactMapped = await largeArray.asyncCompactMap { $0 > 995 ? $0 : nil }
        #expect(compactMapped == [996, 997, 998, 999, 1000])

        // Test contains
        let contains = largeArray.contains { $0 == 500 }
        #expect(contains == true)
    }

    @Test("Methods work with different sequence types")
    func testDifferentSequenceTypes() async throws {
        // Test with Set (which is a Sequence but not necessarily ordered)
        let numberSet: Set<Int> = [1, 2, 3, 4, 5]

        let mappedFromSet = await numberSet.asyncMap { $0 * 2 }
        let expectedValues: Set<Int> = [2, 4, 6, 8, 10]
        #expect(Set(mappedFromSet) == expectedValues)

        // Test with Range
        let range = 1...5
        let mappedFromRange = await range.asyncMap { $0 * 3 }
        #expect(mappedFromRange == [3, 6, 9, 12, 15])
    }
}
