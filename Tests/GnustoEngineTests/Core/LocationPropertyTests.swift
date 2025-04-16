import Testing
@testable import GnustoEngine

@Suite("LocationProperty Enum Tests")
struct LocationPropertyTests {

    @Test("LocationProperty Raw Values")
    func testLocationPropertyRawValues() throws {
        #expect(LocationProperty.inherentlyLit.rawValue == "inherentlyLit")
        #expect(LocationProperty.noMagic.rawValue == "noMagic")
        #expect(LocationProperty.outside.rawValue == "outside")
        #expect(LocationProperty.sacred.rawValue == "sacred")
        #expect(LocationProperty.visited.rawValue == "visited")
        #expect(LocationProperty.water.rawValue == "water")
    }

    @Test("LocationProperty CaseIterable")
    func testCaseIterable() throws {
        // This test ensures that if we add/remove cases, we remember to update it.
        let expectedCount = 6
        #expect(LocationProperty.allCases.count == expectedCount, "Mismatch in expected LocationProperty count. Update this test or check the enum.")
    }

    // Codable tests might be added later.
}
