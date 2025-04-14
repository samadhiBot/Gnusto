import CustomDump
import Gnusto
import Testing

@Suite
struct WorldTests {
    @Test
    func testGameCreation() throws {
        let game = TestGame()
        let world = try game.createWorld()

        // Verify player location
        guard let playerLocation = world.playerLocation else {
            throw TestFailure("Player location not found in world")
        }
        #expect(playerLocation.id == "startRoom")

        // Verify objects in start room
        let startRoomObjects = world.find(in: "startRoom")
        #expect(startRoomObjects.count == 2) // lantern, key

        // Verify objects in north room
        let northRoomObjects = world.find(in: "northRoom")
        #expect(northRoomObjects.count == 1) // chest

        // Verify chest contents
        guard let _ = world.find("chest") else {
            throw TestFailure("Chest not found in world")
        }

        let chestContents = world.find(in: "chest")
        #expect(chestContents.count == 1) // coin
    }
}
