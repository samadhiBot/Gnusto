import CustomDump
import Testing

@testable import Gnusto

@Suite("Quit Command Handler Tests")
struct QuitTests {
    @Test("Quit command ends the game")
    func testQuitEndsGame() throws {
        // Arrange
        let world = World()
        let command = UserInput(verb: "quit", rawInput: "quit")

        // Act
        let context = CommandContext(userInput: command, world: world, canonicalVerbID: .quit)
        let effects = QuitHandler.handle(context: context)

        // Assert
        #expect(world.state == .quit)
        let expectedEffects: [Effect] = [
            .showText("Thanks for playing!"),
            .endGame // Assuming Effect.endGame is the correct case
        ]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Quit command ignores player state changes from handlers")
    func testQuitIgnoresStateChanges() throws {
        // Arrange
        let world = World()

        world.add(
            .room(
                id: "room",
                name: "Room",
                description: "A room"
            ),

            .item(
                id: "item",
                name: "item",
                description: "An item.",
                location: "room",
                ResponseComponent(
                    [
                        "quit": { _, _ in
                            ResponseResult(
                                effects: [.showText("This should not appear.")],
                                updateState: { $0.updateState(to: .running) }
                            )
                        }
                    ]
                )
            )
        )

        world.movePlayer(to: "room")

        let command = UserInput(verb: "quit", rawInput: "quit")

        // Act
        let context = CommandContext(userInput: command, world: world, canonicalVerbID: .quit)
        let effects = QuitHandler.handle(context: context)

        // Assert
        #expect(world.state == .quit, "World state should be .quit, not running")
        let expectedEffects: [Effect] = [
            .showText("Thanks for playing!"),
            .endGame
        ]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Quit command bypasses room hooks")
    func testQuitBypassesHooks() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .room(
                id: "hookRoom",
                name: "Hook Room",
                description: "Room with hooks.",
                RoomHooksComponent(
                    beforeAction: { action, _ -> [Effect]? in
                        if case .command(let command) = action,
                           command.verb == "quit" {
                            return [.showText("Hook tried to stop quit!")]
                        }
                        return nil
                    },
                    afterAction: { action, _ -> [Effect] in
                        if case .command(let command) = action,
                           command.verb == "quit" {
                            return []
                        }
                        return [.showText("After action hook ran.")]
                    }
                )
            )
        )

        world.movePlayer(to: "hookRoom")

        let quitInput = UserInput(verb: "quit", rawInput: "quit")

        // Act
        let context = CommandContext(userInput: quitInput, world: world, canonicalVerbID: .quit)
        let effects = dispatcher.dispatch(.command(quitInput), in: world)

        // Assert
        #expect(world.state == .quit)
        let expectedEffects: [Effect] = [
            .showText("Thanks for playing!"),
            .endGame
        ]
        expectNoDifference(effects, expectedEffects)
    }

    @Test("Quit command bypasses object responses")
    func testQuitBypassesObjectResponses() throws {
        // Arrange
        let world = World()
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        world.add(
            .item(
                id: "item",
                name: "item",
                description: "An item.",
                location: "room",
                ResponseComponent()
            ),

            .room(
                id: "room",
                name: "Room",
                description: "A Room."
            )
        )

        world.movePlayer(to: "room")

        // Add a quit response to the object
        world.modify(id: "item") {
            $0.modify(ResponseComponent.self) { component in
                component.addResponse(for: "quit") { world, command in
                    ResponseResult(effects: [.showText("Object quit response!")])
                }
            }
        }

        let quitInput = UserInput(verb: "quit", rawInput: "quit")

        // Act
        let context = CommandContext(userInput: quitInput, world: world, canonicalVerbID: .quit)
        let effects = dispatcher.dispatch(.command(quitInput), in: world)

        // Assert
        #expect(world.state == .quit)
        let expectedEffects: [Effect] = [
            .showText("Thanks for playing!"),
            .endGame
        ]
        expectNoDifference(effects, expectedEffects)
    }
}
