import CustomDump
import Foundation
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Location Tests")
struct LocationTests {

    // MARK: - Test Setup

    let defaultLocationID: LocationID = "defaultLoc"
    let defaultLocationName = "Room"

    func createDefaultLocation() -> Location {
        Location(defaultLocationID)
            .name(defaultLocationName)
            .description("A nondescript room.")
    }

    func createCustomLocation() -> Location {
        Location("livingRoom")
            .name("Living Room")
            .description("A comfortably furnished living room. There are exits west and east.")
            .west("You head west.")
            .east("A solid wall blocks your path.")
            .inherentlyLit
            .scenery("rug", "fireplace")
    }

    // MARK: - Core Struct Tests

    @Test("Location Default Initialization")
    func testLocationDefaultInitialization() throws {
        let location = createDefaultLocation()

        #expect(location.id == defaultLocationID)
        #expect(location.properties[.name]?.toString == defaultLocationName)
        // Check properties for descriptions
        #expect(location.properties[.description] == .string("A nondescript room."))
        #expect(location.properties[.shortDescription] == nil)
        #expect(location.properties[.exits] == nil)  // Not set, so nil
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
            ])
        #expect(location.properties[.inherentlyLit] == nil)
        #expect(location.properties[.scenery] == nil)  // Not set, so nil
    }

    @Test("Location Custom Initialization")
    func testLocationCustomInitialization() throws {
        let location = createCustomLocation()
        let rugID: ItemID = "rug"

        #expect(location.id == "livingRoom")
        #expect(location.properties[.name]?.toString == "Living Room")
        // Check properties for descriptions
        expectNoDifference(
            location.properties[.description],
            .string("A comfortably furnished living room. There are exits west and east.")
        )
        #expect(location.properties[.shortDescription] == nil)
        expectNoDifference(
            location.properties[.exits]?.toExits,
            [
                .east("A solid wall blocks your path."),
                .west("You head west."),
            ])
        #expect(location.properties[.inherentlyLit]?.toBool == true)
        #expect(location.properties[.scenery]?.toItemIDs?.count == 2)
        #expect(location.properties[.scenery]?.toItemIDs?.contains(rugID) == true)
        // Check the full properties dictionary for completeness
        #expect(
            location.properties == [
                .name: "Living Room",
                .description: "A comfortably furnished living room. There are exits west and east.",
                .exits: .exits([
                    .west("You head west."),
                    .east("A solid wall blocks your path."),
                ]),
                .inherentlyLit: true,
                .scenery: .itemIDSet(["rug", "fireplace"]),
            ]
        )
    }

    @Test("Location Property Management")
    func testLocationPropertyManagement() throws {
        var location = createDefaultLocation()

        #expect(location.properties[.inherentlyLit] == nil)  // Not set, so nil
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
            ])

        location.properties[.inherentlyLit] = true
        #expect(location.properties[.inherentlyLit]?.toBool == true)
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
                .inherentlyLit: true,
            ])

        location.properties[.inherentlyLit] = true  // Setting again should have no effect on count
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
                .inherentlyLit: true,
            ])

        location.properties[.isOutside] = true
        #expect(location.properties[.isOutside]?.toBool == true)
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
                .inherentlyLit: true,
                .isOutside: true,
            ])

        location.properties[.inherentlyLit] = false  // Set back to false, don't remove the key
        #expect(location.properties[.inherentlyLit]?.toBool == false)
        #expect(location.properties[.isOutside]?.toBool == true)
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
                .inherentlyLit: false,
                .isOutside: true,
            ])

        location.properties[.inherentlyLit] = nil  // Remove the key entirely
        #expect(location.properties[.inherentlyLit] == nil)  // Now nil
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
                .isOutside: true,
            ])

        location.properties[.isOutside] = nil  // Remove the other key
        #expect(location.properties[.isOutside] == nil)  // Now nil
        #expect(
            location.properties == [
                .name: "Room",
                .description: "A nondescript room.",
            ])
    }

    @Test("Location Codable Conformance")
    func testLocationCodable() throws {
        var originalLocation = createCustomLocation()
        // Add a short description for thorough testing by setting dynamic value
        originalLocation.properties[.shortDescription] = .string("A comfy room.")

        let encoder = JSONEncoder.sorted(.prettyPrinted)
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalLocation)
        let decodedLocation = try decoder.decode(Location.self, from: jsonData)

        // Verify key properties after decoding
        #expect(decodedLocation.id == originalLocation.id)
        #expect(decodedLocation.properties[.name] == originalLocation.properties[.name])
        // Compare properties for descriptions
        #expect(
            decodedLocation.properties[.description] == originalLocation.properties[.description])
        #expect(
            decodedLocation.properties[.shortDescription]
            == originalLocation.properties[.shortDescription]
        )
        expectNoDifference(
            decodedLocation.properties[.exits]?.toExits,
            [
                .east("A solid wall blocks your path."),
                .west("You head west."),
            ])
        #expect(decodedLocation.properties == originalLocation.properties)
        #expect(
            decodedLocation.properties[.scenery] == originalLocation.properties[.scenery])
    }

    @Test("Location Value Semantics")
    func testLocationValueSemantics() throws {
        let location1 = createDefaultLocation()
        var location2 = location1  // Assign creates a copy for structs

        let originalName = location1.properties[.name]?.toString  // Capture original values
        let originalDescValue = location1.properties[.description]  // Capture original dynamic value

        // Modify the copy (location2)
        location2.properties[.name] = "Renamed Room"
        location2.properties[.isVisited] = true
        // Set dynamic value for description
        location2.properties[.description] = .string("An updated room.")

        // Assert that the original (location1) is unchanged
        #expect(location1.properties[.name]?.toString == originalName)  // Check against captured default
        #expect(location1.properties[.isVisited] == nil)  // Not set, so nil
                                                          // Check original dynamic value
        #expect(location1.properties[.description] == originalDescValue)

        // Assert that location2 has the changes
        #expect(location2.properties[.name]?.toString == "Renamed Room")
        #expect(location2.properties[.isVisited]?.toBool == true)
        // Check new dynamic value
        #expect(location2.properties[.description] == .string("An updated room."))

        // Assert that location1 and location2 are now different
        #expect(location1 != location2)
    }

    // MARK: - Proxy Integration Tests

    @Test("LocationProxy provides access to static properties")
    func testLocationProxyStaticProperties() async throws {
        let location = createCustomLocation()
        let game = MinimalGame(
            player: Player(in: "livingRoom"),
            locations: location
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.location("livingRoom")

        // Test that proxy correctly accesses static properties
        #expect(proxy.id == "livingRoom")

        let nameValue = await proxy.property(.name)
        #expect(nameValue?.toString == "Living Room")

        let descriptionValue = await proxy.property(.description)
        #expect(
            descriptionValue?.toString
            == "A comfortably furnished living room. There are exits west and east.")

        let inherentlyLitValue = await proxy.property(.inherentlyLit)
        #expect(inherentlyLitValue?.toBool == true)
    }

    @Test("LocationProxy equality and hashing")
    func testLocationProxyEqualityAndHashing() async throws {
        let location1 = Location("room1")
            .name("First Room")
            .description("First room.")

        let location2 = Location("room2")
            .name("Second Room")
            .description("Second room.")

        let location1Copy = Location("room1")
            .name("First Room")
            .description("First room.")

        let game = MinimalGame(
            player: Player(in: "room1"),
            locations: location1, location2
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy1 = await engine.location("room1")
        let proxy2 = await engine.location("room2")
        let proxy1Copy = await location1Copy.proxy(engine)

        // Test equality
        #expect(proxy1 == proxy1Copy)  // Same location content
        #expect(proxy1 != proxy2)  // Different locations

        // Test hashing
        var hasher1 = Hasher()
        proxy1.hash(into: &hasher1)

        var hasher1Copy = Hasher()
        proxy1Copy.hash(into: &hasher1Copy)

        var hasher2 = Hasher()
        proxy2.hash(into: &hasher2)

        #expect(hasher1.finalize() == hasher1Copy.finalize())
        #expect(hasher1.finalize() != hasher2.finalize())
    }

    @Test("LocationProxy handles missing properties gracefully")
    func testLocationProxyMissingProperties() async throws {
        let location = Location("minimal")
            .name("Minimal Room")

        let game = MinimalGame(
            player: Player(in: "minimal"),
            locations: location
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.location("minimal")

        // Test that proxy returns nil for unset properties
        let shortDescValue = await proxy.property(.shortDescription)
        #expect(shortDescValue == nil)

        let exitsValue = await proxy.property(.exits)
        #expect(exitsValue == nil)  // Not set, so nil

        let inherentlyLitValue = await proxy.property(.inherentlyLit)
        #expect(inherentlyLitValue == nil)  // Not set, so nil
    }

    @Test("LocationProxy handles exits correctly")
    func testLocationProxyExits() async throws {
        let location = createCustomLocation()
        let game = MinimalGame(
            player: Player(in: "livingRoom"),
            locations: location
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.location("livingRoom")

        let exitsValue = await proxy.property(.exits)
        let exits = exitsValue?.toExits

        expectNoDifference(
            exits,
            [
                .east("A solid wall blocks your path."),
                .west("You head west."),
            ])
    }

    @Test("LocationProxy handles scenery correctly")
    func testLocationProxyLocalGlobals() async throws {
        let location = createCustomLocation()
        let game = MinimalGame(
            player: Player(in: "livingRoom"),
            locations: location
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        let proxy = await engine.location("livingRoom")

        let sceneryValue = await proxy.property(.scenery)
        let scenery = sceneryValue?.toItemIDs

        #expect(scenery?.count == 2)
        #expect(scenery?.contains("rug") == true)
        #expect(scenery?.contains("fireplace") == true)
    }
}
