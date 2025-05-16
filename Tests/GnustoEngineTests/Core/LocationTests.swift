import Testing
import Foundation

@testable import GnustoEngine

@Suite("Location Tests")
struct LocationTests {

    // --- Test Setup ---
    let defaultLocationID: LocationID = "defaultLoc"
    let defaultLocationName = "Room"

    func createDefaultLocation() -> Location {
        Location(
            id: defaultLocationID,
            .name(defaultLocationName),
            .description("A nondescript room.")
        )
    }

    func createCustomLocation() -> Location {
        let westExit = Exit(destination: "westOfHouse", blockedMessage: "You head west.")
        let eastExit = Exit(destination: "nowhere", blockedMessage: "A solid wall blocks your path.")
        return Location(
            id: "livingRoom",
            .name("Living Room"),
            .description("A comfortably furnished living room. There are exits west and east."),
            .exits([.west: westExit, .east: eastExit]),
            .inherentlyLit,
            .isSacred,
            .localGlobals("rug", "fireplace"),
        )
    }

    // --- Tests ---

    @Test("Location Default Initialization")
    func testLocationDefaultInitialization() throws {
        let location = createDefaultLocation()

        #expect(location.id == defaultLocationID)
        #expect(location.name == defaultLocationName)
        // Check attributes for descriptions
        #expect(location.attributes[.description] == .string("A nondescript room."))
        #expect(location.attributes[.shortDescription] == nil)
        #expect(location.exits.isEmpty)
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
        ])

        #expect(location.attributes[.inherentlyLit] == nil)
        #expect(location.hasFlag(.inherentlyLit) == false)

        #expect(location.localGlobals.isEmpty)
    }

    @Test("Location Custom Initialization")
    func testLocationCustomInitialization() throws {
        let location = createCustomLocation()
        let rugID: ItemID = "rug"

        #expect(location.id == "livingRoom")
        #expect(location.name == "Living Room")
        // Check attributes for descriptions
        #expect(location.attributes[.description] == .string("A comfortably furnished living room. There are exits west and east."))
        #expect(location.attributes[.shortDescription] == nil)
        #expect(location.exits.count == 2)
        #expect(location.exits[.west]?.destinationID == "westOfHouse")
        #expect(location.exits[.east]?.blockedMessage == "A solid wall blocks your path.")
        #expect(location.hasFlag(.inherentlyLit))
        #expect(location.hasFlag(.isSacred))
        #expect(location.localGlobals.count == 2)
        #expect(location.localGlobals.contains(rugID))
        // Check the full attributes dictionary for completeness
        #expect(
            location.attributes == [
                .name: "Living Room",
                .description: "A comfortably furnished living room. There are exits west and east.",
                .exits: .exits([
                    .west: Exit(
                        destination: "westOfHouse",
                        blockedMessage: "You head west."
                    ),
                    .east: Exit(
                        destination: "nowhere",
                        blockedMessage: "A solid wall blocks your path."
                    )
                ]),
                .inherentlyLit: true,
                .isSacred: true,
                .localGlobals: .itemIDSet(["rug", "fireplace"])
            ]
        )
    }

    @Test("Location Attribute Management")
    func testLocationAttributeManagement() throws {
        var location = createDefaultLocation()

        #expect(!location.hasFlag(.inherentlyLit)) // isInherentlyLit is false by default
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room."
        ])

        location.attributes[.inherentlyLit] = true
        #expect(location.hasFlag(.inherentlyLit))
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
            .inherentlyLit: true,
        ])

        location.attributes[.inherentlyLit] = true // Setting again should have no effect on count
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
            .inherentlyLit: true,
        ])

        location.attributes[.isOutside] = true
        #expect(location.hasFlag(.isOutside))
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
            .inherentlyLit: true,
            .isOutside: true,
        ])

        location.attributes[.inherentlyLit] = false // Set back to false, don’t remove the key
        #expect(!location.hasFlag(.inherentlyLit))
        #expect(location.hasFlag(.isOutside))
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
            .inherentlyLit: false,
            .isOutside: true,
        ])

        location.attributes[.inherentlyLit] = nil // Remove the key entirely
        #expect(!location.hasFlag(.inherentlyLit)) // Still false
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
            .isOutside: true,
        ])

        location.attributes[.isOutside] = nil // Remove the other key
        #expect(!location.hasFlag(.isOutside))
        #expect(location.attributes == [
            .name: "Room",
            .description: "A nondescript room.",
        ])
    }

    @Test("Location Codable Conformance")
    func testLocationCodable() throws {
        var originalLocation = createCustomLocation()
        // Add a short description for thorough testing by setting dynamic value
        originalLocation.attributes[.shortDescription] = .string("A comfy room.")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalLocation)
        let decodedLocation = try decoder.decode(Location.self, from: jsonData)

        // Verify key properties after decoding
        #expect(decodedLocation.id == originalLocation.id)
        #expect(decodedLocation.name == originalLocation.name)
        // Compare attributes for descriptions
        #expect(decodedLocation.attributes[.description] == originalLocation.attributes[.description])
        #expect(decodedLocation.attributes[.shortDescription] == originalLocation.attributes[.shortDescription])
        #expect(decodedLocation.exits.count == originalLocation.exits.count)
        #expect(decodedLocation.exits[.west]?.destinationID == originalLocation.exits[.west]?.destinationID)
        #expect(decodedLocation.exits[.east]?.blockedMessage == originalLocation.exits[.east]?.blockedMessage)
        #expect(decodedLocation.attributes == originalLocation.attributes)
        #expect(decodedLocation.localGlobals == originalLocation.localGlobals)
    }

    @Test("Location Value Semantics")
    func testLocationValueSemantics() throws {
        let location1 = createDefaultLocation()
        var location2 = location1 // Assign creates a copy for structs

        let originalName = location1.name // Capture original values
        let originalDescValue = location1.attributes[.description] // Capture original dynamic value

        // Modify the copy (location2)
        location2.attributes[.name] = "Renamed Room"
        location2.attributes[.isVisited] = true
        // Set dynamic value for description
        location2.attributes[.description] = .string("An updated room.")

        // Assert that the original (location1) is unchanged
        #expect(location1.name == originalName) // Check against captured default
        #expect(!location1.hasFlag(.isVisited))
        // Check original dynamic value
        #expect(location1.attributes[.description] == originalDescValue)

        // Assert that location2 has the changes
        #expect(location2.name == "Renamed Room")
        #expect(location2.hasFlag(.isVisited))
        // Check new dynamic value
        #expect(location2.attributes[.description] == .string("An updated room."))

        // Assert that location1 and location2 are now different
        #expect(location1 != location2)
    }

    // TODO: Add tests for dynamic description handler registration and generation
    // using DescriptionHandlerRegistry and Location.
}
