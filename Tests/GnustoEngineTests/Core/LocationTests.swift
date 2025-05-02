import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Location Class Tests")
struct LocationTests {

    // --- Test Setup ---
    let defaultLocationID: LocationID = "defaultLoc"
    let defaultLocationName = "Room"

    func createDefaultLocation() -> Location {
        Location(
            id: defaultLocationID,
            name: defaultLocationName,
            longDescription: "A nondescript room."
        )
    }

    func createCustomLocation() -> Location {
        let westExit = Exit(destination: "westOfHouse", blockedMessage: "You head west.")
        let eastExit = Exit(destination: "nowhere", blockedMessage: "A solid wall blocks your path.")
        return Location(
            id: "livingRoom",
            name: "Living Room",
            longDescription: "A comfortably furnished living room. There are exits west and east.",
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
        #expect(location.longDescription?.rawStaticDescription == "A nondescript room.")
        #expect(location.longDescription?.id == nil)
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
        #expect(location.longDescription?.rawStaticDescription == "A comfortably furnished living room. There are exits west and east.")
        #expect(location.longDescription?.id == nil)
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
        var location = createDefaultLocation()

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
        var originalLocation = createCustomLocation()
        // Add a short description for thorough testing
        originalLocation.shortDescription = "A comfy room."

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
        #expect(decodedLocation.globals == originalLocation.globals)
    }

    @Test("Location Value Semantics")
    func testLocationValueSemantics() throws {
        let location1 = createDefaultLocation()
        var location2 = location1 // Assign creates a copy for structs

        let originalName = location1.name // Capture original values
        let originalDesc = location1.longDescription

        // Modify the copy (location2)
        location2.name = "Renamed Room"
        location2.addProperty(.visited)
        location2.longDescription = "An updated room."

        // Assert that the original (location1) is unchanged
        #expect(location1.name == originalName) // Check against captured default
        #expect(!location1.hasProperty(.visited))
        #expect(location1.longDescription?.rawStaticDescription == originalDesc?.rawStaticDescription)

        // Assert that location2 has the changes
        #expect(location2.name == "Renamed Room")
        #expect(location2.hasProperty(.visited))
        #expect(location2.longDescription?.rawStaticDescription == "An updated room.")

        // Assert that location1 and location2 are now different
        #expect(location1 != location2)
    }

    // TODO: Add tests for dynamic description handler registration and generation
    // using DescriptionHandlerRegistry and Location.
}
