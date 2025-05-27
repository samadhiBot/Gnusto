import Testing
@testable import GnustoEngine

@Suite("Exit Struct Tests")
struct ExitTests {

    @Test("Exit Initialization - Destination Only")
    func testExitInitializationDestination() throws {
        let destination: LocationID = "clearing"
        let exit = Exit.to(destination)

        #expect(exit.destinationID == destination)
        #expect(exit.blockedMessage == nil)
        #expect(exit.doorID == nil)
    }

    @Test("Exit Initialization - Blocked Message Only")
    func testExitInitializationBlockedMessage() throws {
        let message = "The way is blocked by a fallen tree."
        // Exit must have a destination, use a placeholder
        let destination: LocationID = "nowhere"
        let exit = Exit(destination: destination, blockedMessage: message)

        #expect(exit.destinationID == destination)
        #expect(exit.blockedMessage == message)
    }

    @Test("Exit Initialization - Destination and Blocked Message")
    func testExitInitializationBoth() throws {
        let destination: LocationID = "path"
        let message = "You push through the bushes."
        let exit = Exit(destination: destination, blockedMessage: message)

        #expect(exit.destinationID == destination)
        #expect(exit.blockedMessage == message)
    }

    @Test("Exit Initialization - Door Properties")
    func testExitInitializationDoor() throws {
        let destination: LocationID = "inside"
        let keyID: ItemID = "ironKey"
        let exit = Exit(destination: destination, doorID: "jailCellDoor")
        let door = Item(
            id: "jailCellDoor",
            .name("Jail cell door"),
            .lockKey(keyID)
        )
        #expect(exit.destinationID == destination)
        #expect(exit.doorID == "jailCellDoor")
        #expect(exit.blockedMessage == nil)
        #expect(exit.doorID == door.id)
    }
}
