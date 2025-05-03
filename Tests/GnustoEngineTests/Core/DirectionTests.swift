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

    // Codable tests might be added later.
}
