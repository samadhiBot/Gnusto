import Foundation
import Testing
@testable import GnustoEngine

@Suite("Direction Enum Tests")
struct DirectionTests {

    @Test("Direction Raw Values")
    func testDirectionRawValues() throws {
        #expect(Direction.down.rawValue == "down")
        #expect(Direction.east.rawValue == "east")
        #expect(Direction.inside.rawValue == "in")
        #expect(Direction.north.rawValue == "north")
        #expect(Direction.northeast.rawValue == "northeast")
        #expect(Direction.northwest.rawValue == "northwest")
        #expect(Direction.outside.rawValue == "out")
        #expect(Direction.south.rawValue == "south")
        #expect(Direction.southeast.rawValue == "southeast")
        #expect(Direction.southwest.rawValue == "southwest")
        #expect(Direction.up.rawValue == "up")
        #expect(Direction.west.rawValue == "west")
    }

    @Test("Direction CaseIterable")
    func testDirectionCaseIterable() throws {
        #expect(Direction.allCases.count == 12)
        // Check a few key cases are present
        #expect(Direction.allCases.contains(.north))
        #expect(Direction.allCases.contains(.inside))
        #expect(Direction.allCases.contains(.southeast))
    }

    @Test("Direction Unknown")
    func testDirectionUnknown() throws {
        #expect(Direction(rawValue: "unknown") == nil)
    }

    @Test("Direction Comparable - Sort Order")
    func testDirectionComparable() throws {
        // Test the clockwise cardinal directions order
        #expect(Direction.north < Direction.northeast)
        #expect(Direction.northeast < Direction.east)
        #expect(Direction.east < Direction.southeast)
        #expect(Direction.southeast < Direction.south)
        #expect(Direction.south < Direction.southwest)
        #expect(Direction.southwest < Direction.west)
        #expect(Direction.west < Direction.northwest)
        
        // Test vertical directions come after cardinal directions
        #expect(Direction.northwest < Direction.up)
        #expect(Direction.up < Direction.down)
        
        // Test inside/outside come last
        #expect(Direction.down < Direction.inside)
        #expect(Direction.inside < Direction.outside)
    }

    @Test("Direction Sorting")
    func testDirectionSorting() throws {
        let unsorted: [Direction] = [.west, .north, .down, .inside, .east, .up, .south]
        let sorted = unsorted.sorted()
        
        let expected: [Direction] = [.north, .east, .south, .west, .up, .down, .inside]
        #expect(sorted == expected)
    }

    @Test("Direction description")
    func testDescription() throws {
        #expect(Direction.north.description == ".north")
        #expect(Direction.east.description == ".east")
        #expect(Direction.inside.description == ".in")
        #expect(Direction.outside.description == ".out")
        #expect(Direction.southwest.description == ".southwest")
    }

    @Test("Direction Codable - Encoding")
    func testDirectionEncoding() throws {
        let encoder = JSONEncoder()
        
        let northData = try encoder.encode(Direction.north)
        let northString = String(data: northData, encoding: .utf8)
        #expect(northString == "\"north\"")
        
        let insideData = try encoder.encode(Direction.inside)
        let insideString = String(data: insideData, encoding: .utf8)
        #expect(insideString == "\"in\"")
    }

    @Test("Direction Codable - Decoding")
    func testDirectionDecoding() throws {
        let decoder = JSONDecoder()
        
        let northData = "\"north\"".data(using: .utf8)!
        let decodedNorth = try decoder.decode(Direction.self, from: northData)
        #expect(decodedNorth == .north)
        
        let insideData = "\"in\"".data(using: .utf8)!
        let decodedInside = try decoder.decode(Direction.self, from: insideData)
        #expect(decodedInside == .inside)
    }

    @Test("Direction Codable - Round Trip")
    func testDirectionRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for direction in Direction.allCases {
            let encoded = try encoder.encode(direction)
            let decoded = try decoder.decode(Direction.self, from: encoded)
            #expect(decoded == direction)
        }
    }

    @Test("Direction Hashable")
    func testDirectionHashable() throws {
        let directions: Set<Direction> = [.north, .south, .east, .west]
        #expect(directions.count == 4)
        #expect(directions.contains(.north))
        #expect(!directions.contains(.up))
    }
}
