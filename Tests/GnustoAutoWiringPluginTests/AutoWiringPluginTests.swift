import Testing
import GnustoEngine

@Suite("Auto-Wiring Plugin Tests")
struct AutoWiringPluginTests {
    func testItemIDs() {
        let game = AutoWiringTestGame()

        #expect(game.items.map(\.id) == [.chair])
        #expect(game.locations.map(\.id) == [.room])
    }
}
