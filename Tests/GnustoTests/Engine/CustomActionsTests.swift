import CustomDump
import Testing

@testable import Gnusto // Add testable import

@Suite("Custom Actions Tests")
struct CustomActionsTests {
    @Test("Custom actions can be defined and executed")
    func testCustomActionsWork() throws {
        // Setup a game with a custom 'light' action
        struct LightGame: Game {
            let welcomeText = "Welcome"
            let versionInfo = "1.0"

            func createWorld() throws -> World {
                let world = World()
                let player = Object.player(id: "player", location: "startRoom") // Location ID only
                let room = Object.room(id: "startRoom", name: "Start Room", description: "A room.")
                let lantern = Object.item(
                    id: "lantern",
                    name: "brass lantern",
                    description: "A brass lantern.",
                    flags: .takeable, .device,
                    location: "startRoom",
                    LightSourceComponent(isOn: false)
                )
                let key = Object.item(
                    id: "key",
                    name: "small key",
                    description: "A small key.",
                    flags: .takeable,
                    location: "startRoom"
                )

                // Add objects to the world
                world.add(player, room, lantern, key)
                // Move player explicitly
                world.movePlayer(to: "startRoom")
                return world
            }

            func defineCustomActions() -> [CustomAction] {
                [
                    CustomAction(verb: "turnon") { context in // Assuming verb mapped to 'turnon'
                        guard context.directObject == "lantern" else {
                            return [.showText("You can't turn on \(context.directObject ?? "that").")]
                        }
                        // Actual logic would modify world state
                        return [.showText("You turn on the lantern.")]
                    }
                ]
            }
        }

        let game = LightGame()
        let renderer = TestRenderer()
        let engine = try Engine(game: game, renderer: renderer)

        // Test light action with lantern
        let validUserInput = UserInput(verb: "turnon", directObject: "lantern", rawInput: "turn on lantern")
        let validContext = ActionContext(
            command: validUserInput, // Use UserInput
            actor: "player",
            location: "startRoom"
        )
        engine.processAction(.custom("turnon", validContext))
        expectNoDifference(renderer.flush(), "You turn on the lantern.")

        // Test light action with wrong object
        let invalidUserInput = UserInput(verb: "turnon", directObject: "key", rawInput: "turn on key")
        let invalidContext = ActionContext(
            command: invalidUserInput, // Use UserInput
            actor: "player",
            location: "startRoom"
        )
        engine.processAction(.custom("turnon", invalidContext))
        expectNoDifference(renderer.flush(), "You can't turn on key.")
    }
}
