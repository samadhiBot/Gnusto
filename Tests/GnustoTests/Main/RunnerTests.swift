import CustomDump
import Testing

@testable import Gnusto

@Suite("Runner Tests")
struct RunnerTests {
    @Test("Runner successfully starts and runs a game")
    func testSuccessfulGameRun() throws {
        // Arrange
        let game = TestGame()
        let renderer = TestRenderer()
        let engine = try Engine(game: game, renderer: renderer)
        try engine.start(enterGameLoop: false)

        // Assert - verify initial game output including quit/end game
        expectNoDifference(
            renderer.flush(),
            // Output depends on how TestGame/TestRenderer simulates the loop ending.
            // Assuming it simulates a quit action or reaches an end state.
            """
            TEST ADVENTURE
            A simple test game for the Gnusto engine.

            You are standing in a small room. There's a door to the north.
            Test Adventure v1.0
            Type 'help' for a list of commands.
            STARTING ROOM
            This is where your adventure begins. A small, cozy room with wooden walls and a comfortable feel.
            You can see: brass lantern, small key.
            Exits: east, north
            """
        )

        // Act
        engine.processAction(
            .command(UserInput(verb: "quit", rawInput: "quit"))
        )

        expectNoDifference(
            renderer.flush(),
            """
            Thanks for playing!
            .endGame(GAME OVER)
            """
        )
    }

    @Test("Runner handles game errors gracefully")
    func testErrorHandling() throws {
        // Arrange
        struct ErrorGame: Game {
            let welcomeText = "Error Game"
            let versionInfo = "v1.0"

            func createWorld() throws -> World {
                throw TestError.someError
            }
        }

        // Act & Assert - verify error is caught and printed
        Runner.run(ErrorGame())
        // Note: We can't easily test the error output since it's printed directly
        // In a real app, we might want to inject a logger or error handler
    }

    @Test("Runner properly initializes game with custom actions")
    func testCustomActions() throws {
        // Arrange
        struct CustomActionGame: Game {
            let welcomeText = "Custom Action Game"
            let versionInfo = "v1.0"

            func createWorld() throws -> World {
                let world = World() // Default player is created with ID "player"
                // Create a starting room and place the player
                let startRoom = Object.room(id: "startRoom", name: "Start", description: "Start here.")
                world.add(startRoom)
                world.movePlayer(to: startRoom.id) // Place player in the room
                return world
            }

            func defineCustomActions() -> [CustomAction] {
                [
                    CustomAction(verb: "test") { context in
                         // Handler might need to safely access context properties
                        [.showText("Custom action executed!")]
                    }
                ]
            }
        }

        let game = CustomActionGame()
        let renderer = TestRenderer()
        let engine = try Engine(game: game, renderer: renderer)

        // We need valid context, but getting it from the private engine state is tricky.
        // Option 1: Assume the dispatcher provides context (test dispatcher directly?).
        // Option 2: Create placeholder context for the direct .custom action call.
        // Let's use placeholder context for now.
        guard let player = engine.world.find("player"),
              let location = engine.world.location(of: "player") else
        {
            throw TestFailure("Failed to setup player/location for custom action context")
        }
        let placeholderUserInput = UserInput(verb: "test", rawInput: "test")

        // Act - Trigger the custom action directly
        engine.processAction(
            .custom(
                "test",
                // Pass object IDs, not objects
                ActionContext(command: placeholderUserInput, actor: player.id, location: location.id)
            )
        )

        // Assert
        expectNoDifference(
            renderer.output(),
            "Custom action executed!"
        )
    }

    @Test("Runner properly initializes game with event handlers")
    func testEventHandlers() throws {
        // Arrange
        struct EventGame: Game {
            let welcomeText = "Event Game"
            let versionInfo = "v1.0"

            func createWorld() throws -> World {
                World()
            }

            func defineEventHandlers() -> [EventHandler] {
                [
                    EventHandler(id: "turnStart") { world in
                        [.showText("Turn started!")]
                    }
                ]
            }
        }

        let game = EventGame()
        let renderer = TestRenderer()
        let engine = try Engine(game: game, renderer: renderer)

        // Act
        engine.processAction(.event("turnStart"))

        // Assert
        expectNoDifference(
            renderer.output(),
            "Turn started!"
        )
    }
}

// MARK: - Test Support

private enum TestError: Error {
    case someError
}
