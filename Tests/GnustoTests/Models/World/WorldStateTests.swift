import Testing

@testable import Gnusto

@Suite("Game State Tests")
struct WorldStateTests {
    @Test("Game can track player state")
    func testPlayerState() throws {
        let registry = CommandRegistry.default // Use helper
        let dispatcher = ActionDispatcher(commandRegistry: registry) // Pass registry

        let game = TestGame()
        let world = try game.createWorld()

        // Test initial state
        #expect(world.playerLocation != nil)

        // Test move counting - REMOVED as this test bypasses the Engine
        // where move counting happens. This should be tested in EngineTests.
        /*
        let beforeMoves = world.player.find(PlayerComponent.self)?.moves ?? 0
        // Create UserInput for the move command
        let moveInput = UserInput(verb: "go", directObject: "north", rawInput: "go north")
        _ = dispatcher.dispatch(.command(moveInput), in: world) // Dispatch UserInput
        let afterMoves = world.player.find(PlayerComponent.self)?.moves ?? 0
        #expect(afterMoves == beforeMoves + 1)
        */
    }
}
