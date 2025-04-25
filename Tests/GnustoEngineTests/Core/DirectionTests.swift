import Testing
@testable import GnustoEngine

@Suite("Direction Enum Tests")
struct DirectionTests {

    @Test("Direction Raw Values")
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
        #expect(Direction.in.rawValue == "in")
        #expect(Direction.out.rawValue == "out")
    }

    @Test("Direction CaseIterable")
    func testDirectionCaseIterable() throws {
        #expect(Direction.allCases.count == 12)
        // Check a few key cases are present
        #expect(Direction.allCases.contains(.north))
        #expect(Direction.allCases.contains(.in))
        #expect(Direction.allCases.contains(.southeast))
    }

    @Test("Direction Unknown")
    func testDirectionUnknown() throws {
        #expect(Direction(rawValue: "unknown") == nil)
    }

    // Codable tests might be added later.
}
