import Testing
import CustomDump

@testable import Gnusto

@Suite("ActionDispatcher Response Tests")
struct ActionDispatcherResponseTests {
    @Test("Object-specific responses in dispatcher")
    func testObjectSpecificResponses() throws {
        // Create player with LocationComponent
        let world = World()

        world.add(
            .room(
                id: "room",
                name: "Dark Room",
                description: "A simple dark room for testing.",
                isLit: false
            ),
            .item(
                id: "lantern",
                name: "brass lantern",
                description: "A sturdy brass lantern.",
                flags: .takeable,
                .device,
                location: "room",
                LightSourceComponent(isOn: false),
                ResponseComponent(
                    [
                        "turnon": { world, userInput in
                            ResponseResult(
                                effects: [.showText("You turn on the brass lantern, illuminating the area.")],
                                updateState: { world in
                                    world.modify(id: "lantern") { $0.turnOn() }
                                }
                            )
                        }
                    ]
                )
            )
        )

        world.movePlayer(to: "room")

        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Test looking in dark room
        let darkLookInput = UserInput(verb: "look", rawInput: "look")
        let darkLookEffects = dispatcher.dispatch(.command(darkLookInput), in: world)

        // Explicitly cast to [Effect] if compiler struggles with type inference
        let expectedDarkLook: [Effect] = [
            .showText("It is pitch black. You are likely to be eaten by a grue."),
        ]
        expectNoDifference(darkLookEffects, expectedDarkLook)

        // Test the custom response
        let turnOnInput = UserInput(
            verb: "turnon",
            directObject: "lantern",
            rawInput: "turn on lantern"
        )
        let effects = dispatcher.dispatch(.command(turnOnInput), in: world)

        // Expect the response effect PLUS the implicit look effects
        let expectedCombinedEffects: [Effect] = [
            .showText("You turn on the brass lantern, illuminating the area."),
            // Implicit look effects:
            .showText("DARK ROOM"), // Room name (adjust if needed)
            .showText("A simple dark room for testing."), // Room description
            .showText("You can see: brass lantern.") // Room contents (now lit)
        ]
        expectNoDifference(effects, expectedCombinedEffects)

        // Verify the lantern was actually turned on
        guard
            let updatedLantern = world.find("lantern"),
            let lightSource = updatedLantern.find(LightSourceComponent.self)
        else {
            throw TestFailure("Failed to get lantern or light source component")
        }

        #expect(lightSource.isOn == true, "Lantern should be turned on")
        // Verify room is lit using world helper
        guard let roomObject = world.find("room") else {
            throw TestFailure("Room object not found")
        }
        #expect(world.isIlluminated(roomObject.id), "Room should now be illuminated")

        // Test that we can now look around in the previously dark room
        let lookInput = UserInput(verb: "look", rawInput: "look")
        let lookEffects = dispatcher.dispatch(.command(lookInput), in: world)

        let expectedLook: [Effect] = [
            .showText("DARK ROOM"), // Room name
            .showText("A simple dark room for testing."),
            .showText("You can see: brass lantern."),
        ]
        expectNoDifference(lookEffects, expectedLook)
    }
}
