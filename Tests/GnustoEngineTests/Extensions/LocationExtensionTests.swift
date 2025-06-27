import Foundation
import Testing

@testable import GnustoEngine

@Suite("Location Extensions")
struct LocationExtensionTests {

    // MARK: - Test Data Setup

    private func createTestLocation(
        id: String = "testLocation",
        name: String = "Test Location"
    ) -> Location {
        Location(
            id: LocationID(rawValue: id),
            .name(name),
            .description("A test location.")
        )
    }

    // MARK: - Array<Location> find Tests

    @Test("find returns correct location when ID exists")
    func testFindExistingLocation() {
        let location1 = createTestLocation(id: "location1", name: "First Location")
        let location2 = createTestLocation(id: "location2", name: "Second Location")
        let location3 = createTestLocation(id: "location3", name: "Third Location")
        let locations = [location1, location2, location3]

        let foundLocation = locations.find("location2")
        #expect(foundLocation?.id == "location2")
        #expect(foundLocation?.name == "Second Location")
    }

    @Test("find returns nil when ID does not exist")
    func testFindNonExistentLocation() {
        let location1 = createTestLocation(id: "location1", name: "First Location")
        let location2 = createTestLocation(id: "location2", name: "Second Location")
        let locations = [location1, location2]

        let foundLocation = locations.find("nonexistent")
        #expect(foundLocation == nil)
    }

    @Test("find returns nil for empty array")
    func testFindInEmptyArray() {
        let locations: [Location] = []
        let foundLocation = locations.find("anyID")
        #expect(foundLocation == nil)
    }

    @Test("find returns first match when duplicate IDs exist")
    func testFindWithDuplicateIDs() {
        let location1 = createTestLocation(id: "duplicate", name: "First Duplicate")
        let location2 = createTestLocation(id: "duplicate", name: "Second Duplicate")
        let locations = [location1, location2]

        let foundLocation = locations.find("duplicate")
        #expect(foundLocation?.name == "First Duplicate")
    }

    @Test("find works with single location array")
    func testFindWithSingleLocation() {
        let location = createTestLocation(id: "onlyLocation", name: "Only Location")
        let locations = [location]

        let foundLocation = locations.find("onlyLocation")
        #expect(foundLocation?.id == "onlyLocation")
        #expect(foundLocation?.name == "Only Location")

        let notFoundLocation = locations.find("differentID")
        #expect(notFoundLocation == nil)
    }

    @Test("find handles various ID formats")
    func testFindWithVariousIDFormats() {
        let locations = [
            createTestLocation(id: "simple", name: "Simple"),
            createTestLocation(id: "with-dashes", name: "With Dashes"),
            createTestLocation(id: "with_underscores", name: "With Underscores"),
            createTestLocation(id: "withNumbers123", name: "With Numbers"),
            createTestLocation(id: "MixedCase", name: "Mixed Case"),
        ]

        #expect(locations.find("simple")?.name == "Simple")
        #expect(locations.find("with-dashes")?.name == "With Dashes")
        #expect(locations.find("with_underscores")?.name == "With Underscores")
        #expect(locations.find("withNumbers123")?.name == "With Numbers")
        #expect(locations.find("MixedCase")?.name == "Mixed Case")
    }

    @Test("find is case insensitive")
    func testFindCaseSensitive() {
        let location = createTestLocation(id: "CamelCase", name: "Test Location")
        let locations = [location]

        #expect(locations.find("CamelCase")?.name == "Test Location")
        #expect(locations.find("camelcase")?.name == "Test Location")
        #expect(locations.find("CAMELCASE")?.name == "Test Location")
        #expect(locations.find("camelCase")?.name == "Test Location")
    }

    @Test("find performance with large arrays")
    func testFindPerformanceWithLargeArrays() {
        // Create a large array of locations
        var locations: [Location] = []
        for i in 0..<1000 {
            locations.append(createTestLocation(id: "location\(i)", name: "Location \(i)"))
        }

        // Test finding first, middle, and last elements
        #expect(locations.find("location0")?.name == "Location 0")
        #expect(locations.find("location500")?.name == "Location 500")
        #expect(locations.find("location999")?.name == "Location 999")
        #expect(locations.find("nonexistent") == nil)
    }

    @Test("find handles locations with special characters in names")
    func testFindWithSpecialCharacters() {
        let locations = [
            createTestLocation(id: "special1", name: "Room with 'quotes'"),
            createTestLocation(id: "special2", name: "Room with \"double quotes\""),
            createTestLocation(id: "special3", name: "Room with émojis 🏠"),
            createTestLocation(id: "special4", name: "Room with\nnewlines"),
            createTestLocation(id: "special5", name: "Room with\ttabs"),
        ]

        #expect(locations.find("special1")?.name == "Room with 'quotes'")
        #expect(locations.find("special2")?.name == "Room with \"double quotes\"")
        #expect(locations.find("special3")?.name == "Room with émojis 🏠")
        #expect(locations.find("special4")?.name == "Room with\nnewlines")
        #expect(locations.find("special5")?.name == "Room with\ttabs")
    }

    @Test("find maintains reference equality")
    func testFindReferenceEquality() {
        let location1 = createTestLocation(id: "location1", name: "First Location")
        let location2 = createTestLocation(id: "location2", name: "Second Location")
        let locations = [location1, location2]

        let foundLocation = locations.find("location1")

        // The found location should be the exact same object reference
        #expect(foundLocation == location1)
        #expect(foundLocation != location2)
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("find works with locations that have identical names but different IDs")
    func testFindWithIdenticalNames() {
        let location1 = createTestLocation(id: "id1", name: "Identical Name")
        let location2 = createTestLocation(id: "id2", name: "Identical Name")
        let locations = [location1, location2]

        #expect(locations.find("id1")?.id == "id1")
        #expect(locations.find("id2")?.id == "id2")
        #expect(locations.find("id1") != locations.find("id2"))
    }

    @Test("find works with locations containing various flags")
    func testFindWithVariousFlags() {
        let locations = [
            Location(
                id: "lit",
                .name("Lit Room"),
                .description("A test location."),
                .inherentlyLit
            ),
            createTestLocation(id: "dark", name: "Dark Room"),
            Location(
                id: "multiple",
                .name("Multi-flag Room"),
                .description("A test location."),
                .inherentlyLit
            ),
        ]

        let litRoom = locations.find("lit")
        #expect(litRoom?.name == "Lit Room")
        #expect(litRoom?.hasFlag(.inherentlyLit) == true)

        let darkRoom = locations.find("dark")
        #expect(darkRoom?.name == "Dark Room")
        #expect(darkRoom?.hasFlag(.inherentlyLit) == false)

        let multiRoom = locations.find("multiple")
        #expect(multiRoom?.name == "Multi-flag Room")
        #expect(multiRoom?.hasFlag(.inherentlyLit) == true)
    }

    @Test("find handles very long location IDs")
    func testFindWithLongIDs() {
        let longID = String(repeating: "veryLongLocationID", count: 10)
        let location = createTestLocation(id: longID, name: "Long ID Location")
        let locations = [location]

        let foundLocation = locations.find(LocationID(rawValue: longID))
        #expect(foundLocation?.name == "Long ID Location")
    }

    @Test("find handles unicode in IDs")
    func testFindWithUnicodeIDs() {
        let locations = [
            createTestLocation(id: "café", name: "Coffee Shop"),
            createTestLocation(id: "北京", name: "Beijing"),
            createTestLocation(id: "🏠home", name: "Home with Emoji"),
        ]

        #expect(locations.find("café")?.name == "Coffee Shop")
        #expect(locations.find("北京")?.name == "Beijing")
        #expect(locations.find("🏠home")?.name == "Home with Emoji")
    }
}
