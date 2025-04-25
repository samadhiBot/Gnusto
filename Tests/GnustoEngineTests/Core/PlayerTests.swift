import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Player Struct Tests")
struct PlayerTests {

    // --- Test Setup ---
    let startLocation: LocationID = "westOfHouse"
    let item1: ItemID = "lantern"
    let item2: ItemID = "leaflet"

    func createDefaultPlayer() -> Player {
        Player(in: startLocation)
    }

    // --- Tests ---

    @Test("Player Default Initialization")
    func testPlayerDefaultInitialization() throws {
        let player = createDefaultPlayer()

        #expect(player.currentLocationID == startLocation)
        #expect(player.carryingCapacity == 100)
        #expect(player.health == 100)
        #expect(player.moves == 0)
        #expect(player.score == 0)
    }

    @Test("Player Property Modification")
    func testPlayerPropertyModification() throws {
        var player = createDefaultPlayer() // Note: player must be var to modify

        player.currentLocationID = "insideHouse"
        player.carryingCapacity = 50
        player.health = 85
        player.moves = 10
        player.score = 5

        #expect(player.currentLocationID == "insideHouse")
        #expect(player.carryingCapacity == 50)
        #expect(player.health == 85)
        #expect(player.moves == 10)
        #expect(player.score == 5)
    }

    @Test("Player Codable Conformance")
    func testPlayerCodable() throws {
        var originalPlayer = createDefaultPlayer()
        originalPlayer.score = 15
        originalPlayer.moves = 25
        originalPlayer.currentLocationID = "forestPath"

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalPlayer)
        let decodedPlayer = try decoder.decode(Player.self, from: jsonData)

        #expect(decodedPlayer.currentLocationID == originalPlayer.currentLocationID)
        #expect(decodedPlayer.carryingCapacity == originalPlayer.carryingCapacity)
        #expect(decodedPlayer.health == originalPlayer.health)
        #expect(decodedPlayer.moves == originalPlayer.moves)
        #expect(decodedPlayer.score == originalPlayer.score)
    }

    @Test("Player Value Semantics")
    func testPlayerValueSemantics() throws {
        var player1 = createDefaultPlayer()
        player1.score = 10

        var player2 = player1 // Create a copy, not a reference

        #expect(player1.score == 10)
        #expect(player2.score == 10)

        player2.score = 20
        player2.currentLocationID = "clearing"

        // Changes to player2 should NOT affect player1
        #expect(player1.score == 10)
        #expect(player2.score == 20)
        #expect(player1.currentLocationID == startLocation)
        #expect(player2.currentLocationID == "clearing")

        // #expect(player1 !== player2) // Cannot test identity for value types
    }
}
