import Testing
@testable import GnustoEngine

@Suite("Exit Struct Tests")
struct ExitTests {

    @Test("Exit Initialization - Destination Only")
    func testExitInitializationDestination() throws {
        let destination: LocationID = "clearing"
        let exit = Exit(destination: destination)

        #expect(exit.destination == destination)
        #expect(exit.blockedMessage == nil)
        #expect(exit.isDoor == false)
        #expect(exit.isOpen == true)
        #expect(exit.isLocked == false)
        #expect(exit.requiredKey == nil)
    }

    @Test("Exit Initialization - Blocked Message Only")
    func testExitInitializationBlockedMessage() throws {
        let message = "The way is blocked by a fallen tree."
        // Exit must have a destination, use a placeholder
        let destination: LocationID = "nowhere"
        let exit = Exit(destination: destination, blockedMessage: message)

        #expect(exit.destination == destination)
        #expect(exit.blockedMessage == message)
    }

    @Test("Exit Initialization - Destination and Blocked Message")
    func testExitInitializationBoth() throws {
        let destination: LocationID = "path"
        let message = "You push through the bushes."
        let exit = Exit(destination: destination, blockedMessage: message)

        #expect(exit.destination == destination)
        #expect(exit.blockedMessage == message)
    }

    @Test("Exit Initialization - Door Properties")
    func testExitInitializationDoor() throws {
        let destination: LocationID = "inside"
        let key: ItemID = "ironKey"
        let exit = Exit(destination: destination, requiredKey: key, isDoor: true, isOpen: false, isLocked: true)

        #expect(exit.destination == destination)
        #expect(exit.isDoor == true)
        #expect(exit.isOpen == false)
        #expect(exit.isLocked == true)
        #expect(exit.requiredKey == key)
        #expect(exit.blockedMessage == nil)
    }

    // Test for default door state (should be open, unlocked)
    @Test("Exit Initialization - Default Door State")
    func testExitInitializationDefaultDoorState() throws {
        let destination: LocationID = "nextRoom"
        let exit = Exit(destination: destination, isDoor: true)

        #expect(exit.isDoor == true)
        #expect(exit.isOpen == true)
        #expect(exit.isLocked == false)
    }

    // Test non-door ignores door properties
    @Test("Exit Initialization - NonDoor Ignores Door Properties")
    func testExitInitializationNonDoorIgnoresDoorAttributes() throws {
        let destination: LocationID = "otherSide"
        // Provide door properties, but set isDoor to false
        let exit = Exit(destination: destination, isDoor: false, isOpen: false, isLocked: true)

        #expect(exit.isDoor == false)
        #expect(exit.isOpen == true) // Should revert to default true for non-door
        #expect(exit.isLocked == false) // Should revert to default false for non-door
    }

    // Codable tests will be added when needed.
    // Tests for conditional logic will be added when `conditionHandler` is implemented.
}
