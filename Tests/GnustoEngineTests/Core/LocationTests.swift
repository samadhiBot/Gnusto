import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Location Class Tests")
struct LocationTests {

    // --- Test Setup ---
    let defaultLocationID: LocationID = "defaultLoc"
    let defaultLocationName = "Room"
    let defaultLocationDesc = "A non-descript room."

    func createDefaultLocation() -> Location {
        Location(
            id: defaultLocationID,
            name: defaultLocationName,
            description: defaultLocationDesc
        )
    }

    func createCustomLocation() -> Location {
        let westExit = Exit(destination: "westOfHouse", blockedMessage: "You head west.")
        let eastExit = Exit(destination: "nowhere", blockedMessage: "A solid wall blocks your path.")
        return Location(
            id: "livingRoom",
            name: "Living Room",
            description: "A comfortably furnished living room. There are exits west and east.",
            exits: [.west: westExit, .east: eastExit],
            properties: [.lit, .sacred],
            globals: ["rug", "fireplace"]
        )
    }

    // --- Tests ---

    @Test("Location Default Initialization")
    func testLocationDefaultInitialization() throws {
        let location = createDefaultLocation()

        #expect(location.id == defaultLocationID)
        #expect(location.name == defaultLocationName)
        #expect(location.description == defaultLocationDesc)
        #expect(location.exits.isEmpty)
        #expect(location.properties.isEmpty)
        #expect(location.globals.isEmpty)
    }

    @Test("Location Custom Initialization")
    func testLocationCustomInitialization() throws {
        let location = createCustomLocation()
        let leafletID: ItemID = "leaflet"
        let rugID: ItemID = "rug"

        #expect(location.id == "livingRoom")
        #expect(location.name == "Living Room")
        #expect(location.description == "A comfortably furnished living room. There are exits west and east.")
        #expect(location.exits.count == 2)
        #expect(location.exits[.west]?.destination == "westOfHouse")
        #expect(location.exits[.east]?.blockedMessage == "A solid wall blocks your path.")
        #expect(location.properties == [.lit, .sacred])
        #expect(location.globals.count == 2)
        #expect(location.globals.contains(rugID))
    }

    @Test("Location Property Management")
    func testLocationPropertyManagement() throws {
        let location = createDefaultLocation()

        #expect(!location.hasProperty(.lit))

        location.addProperty(.lit)
        #expect(location.hasProperty(.lit))
        #expect(location.properties.count == 1)

        location.addProperty(.lit) // Adding again should have no effect
        #expect(location.properties.count == 1)

        location.addProperty(.outside)
        #expect(location.hasProperty(.outside))
        #expect(location.properties.count == 2)

        location.removeProperty(.lit)
        #expect(!location.hasProperty(.lit))
        #expect(location.hasProperty(.outside))
        #expect(location.properties.count == 1)

        location.removeProperty(.lit) // Removing again should have no effect
        #expect(location.properties.count == 1)

        location.removeProperty(.outside)
        #expect(!location.hasProperty(.outside))
        #expect(location.properties.isEmpty)
    }

    @Test("Location Codable Conformance")
    func testLocationCodable() throws {
        let originalLocation = createCustomLocation()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // For easier debugging
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalLocation)
        let decodedLocation = try decoder.decode(Location.self, from: jsonData)

        // Verify key properties after decoding
        #expect(decodedLocation.id == originalLocation.id)
        #expect(decodedLocation.name == originalLocation.name)
        #expect(decodedLocation.description == originalLocation.description)
        #expect(decodedLocation.exits.count == originalLocation.exits.count)
        #expect(decodedLocation.exits[.west]?.destination == originalLocation.exits[.west]?.destination)
        #expect(decodedLocation.exits[.east]?.blockedMessage == originalLocation.exits[.east]?.blockedMessage)
        #expect(decodedLocation.properties == originalLocation.properties)
        #expect(Set(decodedLocation.globals) == Set(originalLocation.globals))
    }

    @Test("Location Reference Semantics")
    func testLocationReferenceSemantics() throws {
        let location1 = createDefaultLocation()
        let location2 = location1 // Assign reference, not a copy

        location2.name = "Renamed Room"
        location2.addProperty(.visited)

        #expect(location1.name == "Renamed Room") // Change in location2 reflects in location1
        #expect(location1.hasProperty(.visited))
        #expect(location1 === location2) // Verify they point to the same instance
    }
}
