import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Location Class Tests")
struct LocationTests {

    // --- Test Setup ---
    let defaultLocationID: LocationID = "defaultLoc"
    let defaultLocationName = "Room"
    let defaultLocationLongDesc = "A non-descript room."
    let customLocationLongDesc = "A comfortably furnished living room. There are exits west and east."

    func createDefaultLocation() -> Location {
        Location(
            id: defaultLocationID,
            name: defaultLocationName,
            longDescription: defaultLocationLongDesc // Use longDescription parameter
        )
    }

    func createCustomLocation() -> Location {
        let westExit = Exit(destination: "westOfHouse", blockedMessage: "You head west.")
        let eastExit = Exit(destination: "nowhere", blockedMessage: "A solid wall blocks your path.")
        return Location(
            id: "livingRoom",
            name: "Living Room",
            longDescription: customLocationLongDesc, // Use longDescription parameter
            exits: [.west: westExit, .east: eastExit],
            properties: .inherentlyLit, .sacred,
            globals: "rug", "fireplace"
        )
    }

    // --- Tests ---

    @Test("Location Default Initialization")
    func testLocationDefaultInitialization() throws {
        let location = createDefaultLocation()

        #expect(location.id == defaultLocationID)
        #expect(location.name == defaultLocationName)
        // Check the static description within the DescriptionHandler
        #expect(location.longDescription?.staticDescription == defaultLocationLongDesc)
        #expect(location.longDescription?.dynamicHandlerID == nil)
        #expect(location.shortDescription == nil) // Verify shortDescription is nil by default
        #expect(location.exits.isEmpty)
        #expect(location.properties.isEmpty)
        #expect(location.globals.isEmpty)
    }

    @Test("Location Custom Initialization")
    func testLocationCustomInitialization() throws {
        let location = createCustomLocation()
        let rugID: ItemID = "rug"

        #expect(location.id == "livingRoom")
        #expect(location.name == "Living Room")
        #expect(location.longDescription?.staticDescription == customLocationLongDesc)
        #expect(location.longDescription?.dynamicHandlerID == nil)
        #expect(location.shortDescription == nil)
        #expect(location.exits.count == 2)
        #expect(location.exits[.west]?.destination == "westOfHouse")
        #expect(location.exits[.east]?.blockedMessage == "A solid wall blocks your path.")
        #expect(location.properties == [.inherentlyLit, .sacred])
        #expect(location.globals.count == 2)
        #expect(location.globals.contains(rugID))
    }

    @Test("Location Property Management")
    func testLocationPropertyManagement() throws {
        let location = createDefaultLocation()

        #expect(!location.hasProperty(.inherentlyLit))

        location.addProperty(.inherentlyLit)
        #expect(location.hasProperty(.inherentlyLit))
        #expect(location.properties.count == 1)

        location.addProperty(.inherentlyLit) // Adding again should have no effect
        #expect(location.properties.count == 1)

        location.addProperty(.outside)
        #expect(location.hasProperty(.outside))
        #expect(location.properties.count == 2)

        location.removeProperty(.inherentlyLit)
        #expect(!location.hasProperty(.inherentlyLit))
        #expect(location.hasProperty(.outside))
        #expect(location.properties.count == 1)

        location.removeProperty(.inherentlyLit) // Removing again should have no effect
        #expect(location.properties.count == 1)

        location.removeProperty(.outside)
        #expect(!location.hasProperty(.outside))
        #expect(location.properties.isEmpty)
    }

    @Test("Location Codable Conformance")
    func testLocationCodable() throws {
        let originalLocation = createCustomLocation()
        // Add a short description for thorough testing
        originalLocation.shortDescription = DescriptionHandler(staticDescription: "A comfy room.")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalLocation)
        let decodedLocation = try decoder.decode(Location.self, from: jsonData)

        // Verify key properties after decoding
        #expect(decodedLocation.id == originalLocation.id)
        #expect(decodedLocation.name == originalLocation.name)
        // Compare DescriptionHandlers
        #expect(decodedLocation.longDescription == originalLocation.longDescription)
        #expect(decodedLocation.shortDescription == originalLocation.shortDescription)
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
        // Modify the description handler indirectly (if it were mutable, or reassign)
        location2.longDescription = DescriptionHandler(staticDescription: "An updated room.")

        #expect(location1.name == "Renamed Room") // Change in location2 reflects in location1
        #expect(location1.hasProperty(.visited))
        #expect(location1.longDescription?.staticDescription == "An updated room.")
        #expect(location1 === location2) // Verify they point to the same instance
    }

    // TODO: Add tests for dynamic description handler registration and generation
    // using DescriptionHandlerRegistry and LocationSnapshot.
}
