import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Direction Tests")
struct DirectionTests {

    // MARK: - Basic Functionality Tests

    @Test("All directions have correct raw values")
    func testDirectionRawValues() throws {
        #expect(Direction.north.rawValue == "north")
        #expect(Direction.south.rawValue == "south")
        #expect(Direction.east.rawValue == "east")
        #expect(Direction.west.rawValue == "west")
        #expect(Direction.northeast.rawValue == "northeast")
        #expect(Direction.northwest.rawValue == "northwest")
        #expect(Direction.southeast.rawValue == "southeast")
        #expect(Direction.southwest.rawValue == "southwest")
        #expect(Direction.up.rawValue == "up")
        #expect(Direction.down.rawValue == "down")
        #expect(Direction.inside.rawValue == "in")
        #expect(Direction.outside.rawValue == "out")
    }

    @Test("Direction Unknown")
    func testDirectionUnknown() throws {
        #expect(Direction(rawValue: "unknown") == nil)
    }

    @Test("All directions are included in allCases")
    func testAllCasesComplete() throws {
        let expectedCount = 12
        #expect(Direction.allCases.count == expectedCount)

        // Verify all expected directions are present
        let allCases = Set(Direction.allCases)
        let expectedDirections: Set<Direction> = [
            .north, .south, .east, .west,
            .northeast, .northwest, .southeast, .southwest,
            .up, .down, .inside, .outside,
        ]

        #expect(allCases == expectedDirections)
    }

    // MARK: - Comparable Conformance Tests

    @Test("Comparable conformance follows clockwise order from North")
    func testComparableConformance() throws {
        // Test cardinal directions in clockwise order
        #expect(Direction.north < Direction.northeast)
        #expect(Direction.northeast < Direction.east)
        #expect(Direction.east < Direction.southeast)
        #expect(Direction.southeast < Direction.south)
        #expect(Direction.south < Direction.southwest)
        #expect(Direction.southwest < Direction.west)
        #expect(Direction.west < Direction.northwest)

        // Test other directions come after compass directions
        #expect(Direction.northwest < Direction.up)
        #expect(Direction.up < Direction.down)
        #expect(Direction.down < Direction.inside)
        #expect(Direction.inside < Direction.outside)
    }

    @Test("Sort order is stable and consistent")
    func testSortOrder() throws {
        var generator = SeededRandomNumberGenerator(seed: 42)
        let directions = Direction.allCases.shuffled(using: &generator)
        let sorted = directions.sorted()

        let expectedOrder: [Direction] = [
            .north, .northeast, .east, .southeast,
            .south, .southwest, .west, .northwest,
            .up, .down, .inside, .outside,
        ]

        expectNoDifference(sorted, expectedOrder)
    }

    @Test("Comparable operations work correctly")
    func testComparableOperations() throws {
        #expect(Direction.north <= Direction.north)
        #expect(Direction.north >= Direction.north)
        #expect(!(Direction.north > Direction.north))
        #expect(!(Direction.north < Direction.north))

        #expect(Direction.north < Direction.south)
        #expect(Direction.north <= Direction.south)
        #expect(Direction.south > Direction.north)
        #expect(Direction.south >= Direction.north)
    }

    // MARK: - CustomStringConvertible Tests

    @Test("CustomStringConvertible provides dot notation")
    func testCustomStringConvertible() throws {
        #expect(Direction.north.description == ".north")
        #expect(Direction.south.description == ".south")
        #expect(Direction.east.description == ".east")
        #expect(Direction.west.description == ".west")
        #expect(Direction.northeast.description == ".northeast")
        #expect(Direction.northwest.description == ".northwest")
        #expect(Direction.southeast.description == ".southeast")
        #expect(Direction.southwest.description == ".southwest")
        #expect(Direction.up.description == ".up")
        #expect(Direction.down.description == ".down")
        #expect(Direction.inside.description == ".in")
        #expect(Direction.outside.description == ".out")
    }

    // MARK: - Codable Conformance Tests

    @Test("Direction encodes and decodes correctly")
    func testCodableConformance() throws {
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()

        for direction in Direction.allCases {
            let encoded = try encoder.encode(direction)
            let decoded = try decoder.decode(Direction.self, from: encoded)
            #expect(decoded == direction)
        }
    }

    @Test("Direction decodes from raw string values")
    func testDecodingFromRawValues() throws {
        let decoder = JSONDecoder()

        // Test valid raw values
        let northJSON = "\"north\"".data(using: .utf8)!
        let decodedNorth = try decoder.decode(Direction.self, from: northJSON)
        #expect(decodedNorth == .north)

        let insideJSON = "\"in\"".data(using: .utf8)!
        let decodedInside = try decoder.decode(Direction.self, from: insideJSON)
        #expect(decodedInside == .inside)

        let outsideJSON = "\"out\"".data(using: .utf8)!
        let decodedOutside = try decoder.decode(Direction.self, from: outsideJSON)
        #expect(decodedOutside == .outside)
    }

    @Test("Direction encoding produces expected JSON")
    func testEncodingProducesExpectedJSON() throws {
        let encoder = JSONEncoder.sorted()

        let northData = try encoder.encode(Direction.north)
        let northString = String(data: northData, encoding: .utf8)
        #expect(northString == "\"north\"")

        let insideData = try encoder.encode(Direction.inside)
        let insideString = String(data: insideData, encoding: .utf8)
        #expect(insideString == "\"in\"")

        let outsideData = try encoder.encode(Direction.outside)
        let outsideString = String(data: outsideData, encoding: .utf8)
        #expect(outsideString == "\"out\"")
    }

    // MARK: - Hashable Conformance Tests

    @Test("Direction is properly hashable")
    func testHashableConformance() throws {
        let directions = Set(Direction.allCases)
        #expect(directions.count == Direction.allCases.count)

        // Test that equal directions have equal hash values
        #expect(Direction.north.hashValue == Direction.north.hashValue)

        // Test that directions can be used as dictionary keys
        var directionMap: [Direction: String] = [:]
        for direction in Direction.allCases {
            directionMap[direction] = direction.rawValue
        }
        #expect(directionMap.count == Direction.allCases.count)
        #expect(directionMap[.north] == "north")
        #expect(directionMap[.inside] == "in")
        #expect(directionMap[.outside] == "out")
    }

    // MARK: - Equatable Tests

    @Test("Direction equality works correctly")
    func testEquatableConformance() throws {
        #expect(Direction.north == Direction.north)
        #expect(Direction.north != Direction.south)

        // Test all directions are equal to themselves
        for direction in Direction.allCases {
            #expect(direction == direction)
        }

        // Test all directions are different from each other
        for (i, direction1) in Direction.allCases.enumerated() {
            for (j, direction2) in Direction.allCases.enumerated() {
                if i != j {
                    #expect(direction1 != direction2)
                }
            }
        }
    }

    // MARK: - Array and Collection Tests

    @Test("Directions work correctly in arrays and collections")
    func testCollectionUsage() throws {
        let cardinalDirections = [Direction.north, .south, .east, .west]
        #expect(cardinalDirections.contains(.north))
        #expect(!cardinalDirections.contains(.up))

        let sortedCardinals = cardinalDirections.sorted()
        expectNoDifference(sortedCardinals, [.north, .east, .south, .west])

        let directionSet: Set<Direction> = [.north, .south, .north, .east]
        #expect(directionSet.count == 3)  // .north should only appear once
        #expect(directionSet.contains(.north))
        #expect(directionSet.contains(.south))
        #expect(directionSet.contains(.east))
        #expect(!directionSet.contains(.west))
    }

    // MARK: - Sendable Conformance Tests

    @Test("Direction is Sendable")
    func testSendableConformance() throws {
        // This test mainly ensures compilation - if Direction weren't Sendable,
        // this wouldn't compile in strict concurrency mode
        Task {
            let direction = Direction.north
            await withCheckedContinuation { continuation in
                Task {
                    #expect(direction == .north)
                    continuation.resume()
                }
            }
        }
    }
}
