import CustomDump
import Gnusto
import Testing

@Suite
struct RoomComponentTests {
    @Test
    func testRoomConnections() throws {
        let game = TestGame()
        let world = try game.createWorld()

        // Get the start room
        guard let startRoom = world.find("startRoom") else {
            throw TestFailure("Start room not found in world")
        }

        // Verify north exit exists (direct exit)
        guard let roomComponent = startRoom.find(RoomComponent.self) else {
            throw TestFailure("Start room missing RoomComponent")
        }
        guard let northExit = roomComponent.exits[.north] else {
            throw TestFailure("North exit not found in start room")
        }

        // Check that it's a direct exit
        if case .direct(let roomID) = northExit {
            #expect(roomID == "northRoom")
        } else {
            throw TestFailure("North exit should be a direct exit")
        }

        // Check that east exit is conditional and initially not available
        guard let eastExit = roomComponent.exits[.east] else {
            throw TestFailure("East exit not found in start room")
        }

        // Check that it's a conditional exit
        if case .conditional = eastExit {
            let availableExit = roomComponent.availableExit(direction: .east, in: world)
            #expect(
                availableExit == nil,
                "East exit should not be available when lantern is off"
            )
        } else {
            throw TestFailure("East exit should be a conditional exit")
        }

        // Turn on the lantern to make the east exit available
        world.modify(id: "lantern") { $0.turnOn() }

        // Now the east exit should be available
        let availableExit = roomComponent.availableExit(direction: .east, in: world)
        #expect(
            availableExit == "eastRoom",
            "East exit should be available when lantern is on"
        )
    }





}
